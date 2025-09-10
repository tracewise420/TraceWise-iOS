import Foundation

class RetryManager {
    private let maxRetries: Int
    private let baseDelay: TimeInterval = 1.0
    
    init(maxRetries: Int) {
        self.maxRetries = maxRetries
    }
    
    func retry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on client errors (4xx) except 429
                if let traceWiseError = error as? TraceWiseError,
                   case .apiError(_, _, let statusCode) = traceWiseError,
                   statusCode >= 400 && statusCode < 500 && statusCode != 429 {
                    throw error
                }
                
                // Handle rate limiting with custom delay
                if let traceWiseError = error as? TraceWiseError,
                   case .rateLimitExceeded(let retryAfter) = traceWiseError {
                    let delay = TimeInterval(retryAfter ?? 60)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                if attempt < maxRetries {
                    // Exponential backoff with jitter
                    let delay = baseDelay * pow(2.0, Double(attempt)) + Double.random(in: 0...1)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? TraceWiseError.unknown(NSError(domain: "RetryManager", code: -1))
    }
}