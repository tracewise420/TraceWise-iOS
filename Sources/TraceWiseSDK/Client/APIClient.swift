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
    private let subscriptionStorage = SubscriptionStorage()
    
    init(config: SDKConfig) {
        self.config = config
        self.retryManager = RetryManager(maxRetries: config.maxRetries)
        self.authProvider = AuthProvider(config: config)
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeoutInterval
        configuration.timeoutIntervalForResource = config.timeoutInterval * 2
        self.session = URLSession(configuration: configuration)
    }
    
    private func checkRateLimit() throws {
        guard let subscriptionInfo = subscriptionStorage.load(),
              subscriptionInfo.tier == "free" else { return }
        
        let usage = subscriptionInfo.usage
        let limits = subscriptionInfo.limits
        
        if usage.apiCallsThisMinute >= limits.apiCallsPerMinute {
            throw TraceWiseError.rateLimitExceeded(retryAfter: 60)
        }
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
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TraceWiseError.invalidResponse
            }
            
            if config.enableLogging {
                print("📥 Response: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Data: \(responseString)")
                }
            }
            
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
            
            return try JSONDecoder().decode(responseType, from: data)
            
        } catch {
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