import Foundation

protocol APIClientProtocol {
    func request<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: Data?,
        responseType: T.Type
    ) async throws -> T
}

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

class APIClient: APIClientProtocol {
    private let config: SDKConfig
    private let session: URLSession
    private let retryManager: RetryManager
    private let authProvider: AuthProvider
    private var subscriptionManager: SubscriptionManager!
    private var csrfManager: CSRFManager!
    private let performanceMonitor = PerformanceMonitor.shared
    
    init(config: SDKConfig) {
        self.config = config
        self.retryManager = RetryManager(maxRetries: config.maxRetries)
        self.authProvider = AuthProvider(config: config)
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeoutInterval
        configuration.timeoutIntervalForResource = config.timeoutInterval * 2
        self.session = URLSession(configuration: configuration)
        
        // Initialize managers after self is fully initialized
        self.subscriptionManager = SubscriptionManager(apiClient: self)
        self.csrfManager = CSRFManager(apiClient: self)
    }
    
    private func checkRateLimit() throws {
        try subscriptionManager.checkRateLimit()
    }
    
    func request<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        try checkRateLimit()
        
        return try await retryManager.retry {
            try await self.performRequest(
                method: method,
                endpoint: endpoint,
                body: body,
                responseType: responseType
            )
        }
    }
    
    private func performRequest<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: Data?,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: config.baseURL + endpoint) else {
            throw TraceWiseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "X-API-Version")
        
        // Add authentication headers
        let headers = try await authProvider.getHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add idempotency key for POST requests
        if method == .POST {
            let idempotencyKey = "\(Date().timeIntervalSince1970)-\(UUID().uuidString)"
            request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
            
            // Add CSRF token for POST requests
            if endpoint.contains("/register") || endpoint.contains("/events") || endpoint.contains("/dpp") {
                do {
                    let csrfToken = try await csrfManager.getCSRFToken()
                    request.setValue(csrfToken, forHTTPHeaderField: "X-CSRF-Token")
                } catch {
                    // Log CSRF token fetch error but continue with request
                    if config.enableLogging {
                        print("⚠️ Failed to fetch CSRF token: \(error)")
                    }
                }
            }
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        if config.enableLogging {
            print("🌐 \(method.rawValue) \(url)")
            if let body = body, let bodyString = String(data: body, encoding: .utf8) {
                print("📤 Body: \(bodyString)")
            }
        }
        
        let startTime = Date()
        var success = false
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let duration = Date().timeIntervalSince(startTime)
                performanceMonitor.trackAPICall(
                    endpoint: performanceMonitor.extractEndpoint(from: request.url?.path ?? ""),
                    duration: duration,
                    success: false
                )
                throw TraceWiseError.invalidResponse
            }
            
            success = httpResponse.statusCode < 400
            
            if config.enableLogging {
                print("📥 Response: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Data: \(responseString)")
                }
            }
            
            // Update rate limit info from headers
            let headers: [String: String] = Dictionary(uniqueKeysWithValues: 
                httpResponse.allHeaderFields.compactMap { key, value in
                    guard let stringKey = key as? String, let stringValue = value as? String else { return nil }
                    return (stringKey, stringValue)
                }
            )
            subscriptionManager.updateRateLimitInfo(from: headers)
            
            // Handle rate limiting
            if httpResponse.statusCode == 429 {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
                throw TraceWiseError.rateLimitExceeded(retryAfter: retryAfter)
            }
            
            if httpResponse.statusCode >= 400 {
                let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
                throw TraceWiseError.apiError(
                    code: errorResponse?.error.code ?? "HTTP_ERROR",
                    message: errorResponse?.error.message ?? "HTTP \(httpResponse.statusCode)",
                    statusCode: httpResponse.statusCode
                )
            }
            
            let result = try JSONDecoder().decode(responseType, from: data)
            let duration = Date().timeIntervalSince(startTime)
            let cached = httpResponse.value(forHTTPHeaderField: "X-Cache") == "HIT"
            
            performanceMonitor.trackAPICall(
                endpoint: performanceMonitor.extractEndpoint(from: request.url?.path ?? ""),
                duration: duration,
                success: success,
                cached: cached
            )
            
            return result
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            performanceMonitor.trackAPICall(
                endpoint: performanceMonitor.extractEndpoint(from: request.url?.path ?? ""),
                duration: duration,
                success: false
            )
            
            if error is TraceWiseError {
                throw error
            } else if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw TraceWiseError.timeout
                case .notConnectedToInternet, .networkConnectionLost:
                    throw TraceWiseError.networkError(urlError)
                default:
                    throw TraceWiseError.networkError(urlError)
                }
            } else {
                throw TraceWiseError.unknown(error)
            }
        }
    }
}