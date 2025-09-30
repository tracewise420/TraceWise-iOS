import Foundation

public struct PerformanceMetrics {
    public let apiResponseTime: [String: Double]
    public let successRate: Double
    public let errorRate: Double
    public let cacheHitRate: Double
    public let retryAttempts: Int64
    public let totalRequests: Int64
    
    public init(apiResponseTime: [String: Double], successRate: Double, errorRate: Double, cacheHitRate: Double, retryAttempts: Int64, totalRequests: Int64) {
        self.apiResponseTime = apiResponseTime
        self.successRate = successRate
        self.errorRate = errorRate
        self.cacheHitRate = cacheHitRate
        self.retryAttempts = retryAttempts
        self.totalRequests = totalRequests
    }
}

struct APICallMetric {
    let endpoint: String
    let duration: TimeInterval
    let success: Bool
    let cached: Bool
    let retries: Int
    let timestamp: Date
}

class PerformanceMonitor {
    private var metrics: [APICallMetric] = []
    private var endpointStats: [String: [TimeInterval]] = [:]
    private var totalRequests: Int64 = 0
    private var successfulRequests: Int64 = 0
    private var cachedRequests: Int64 = 0
    private var totalRetries: Int64 = 0
    private let queue = DispatchQueue(label: "performance.monitor.queue", attributes: .concurrent)
    
    static let shared = PerformanceMonitor()
    
    private init() {}
    
    func trackAPICall(endpoint: String, duration: TimeInterval, success: Bool, cached: Bool = false, retries: Int = 0) {
        let metric = APICallMetric(
            endpoint: endpoint,
            duration: duration,
            success: success,
            cached: cached,
            retries: retries,
            timestamp: Date()
        )
        
        queue.async(flags: .barrier) {
            self.metrics.append(metric)
            if self.metrics.count > 1000 {
                self.metrics.removeFirst() // Keep only last 1000 metrics
            }
            
            if self.endpointStats[endpoint] == nil {
                self.endpointStats[endpoint] = []
            }
            self.endpointStats[endpoint]?.append(duration)
            
            self.totalRequests += 1
            if success { self.successfulRequests += 1 }
            if cached { self.cachedRequests += 1 }
            self.totalRetries += Int64(retries)
        }
    }
    
    func getMetrics() -> PerformanceMetrics {
        return queue.sync {
            guard totalRequests > 0 else {
                return PerformanceMetrics(
                    apiResponseTime: [:],
                    successRate: 0.0,
                    errorRate: 0.0,
                    cacheHitRate: 0.0,
                    retryAttempts: 0,
                    totalRequests: 0
                )
            }
            
            let avgResponseTimes = endpointStats.mapValues { durations in
                durations.reduce(0, +) / Double(durations.count)
            }
            
            let total = Double(totalRequests)
            
            return PerformanceMetrics(
                apiResponseTime: avgResponseTimes,
                successRate: (Double(successfulRequests) / total) * 100,
                errorRate: (Double(totalRequests - successfulRequests) / total) * 100,
                cacheHitRate: (Double(cachedRequests) / total) * 100,
                retryAttempts: totalRetries,
                totalRequests: totalRequests
            )
        }
    }
    
    func reset() {
        queue.async(flags: .barrier) {
            self.metrics.removeAll()
            self.endpointStats.removeAll()
            self.totalRequests = 0
            self.successfulRequests = 0
            self.cachedRequests = 0
            self.totalRetries = 0
        }
    }
    
    func extractEndpoint(from path: String) -> String {
        // Extract endpoint pattern (e.g., "/v1/products/{id}" from "/v1/products/123")
        return path
            .replacingOccurrences(of: #"/[0-9a-fA-F-]{8,}"#, with: "/{id}", options: .regularExpression)
            .replacingOccurrences(of: #"/[0-9]{13}"#, with: "/{gtin}", options: .regularExpression)
            .replacingOccurrences(of: #"/[A-Z0-9]{6,}"#, with: "/{serial}", options: .regularExpression)
    }
}