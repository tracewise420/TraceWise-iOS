import Foundation

public struct SDKConfig {
    public let baseURL: String
    public let apiKey: String?
    public let firebaseTokenProvider: (() async throws -> String)?
    public let timeoutInterval: TimeInterval
    public let maxRetries: Int
    public let enableLogging: Bool
    
    public init(
        baseURL: String,
        apiKey: String? = nil,
        firebaseTokenProvider: (() async throws -> String)? = nil,
        timeoutInterval: TimeInterval = 30.0,
        maxRetries: Int = 3,
        enableLogging: Bool = false
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.firebaseTokenProvider = firebaseTokenProvider
        self.timeoutInterval = timeoutInterval
        self.maxRetries = maxRetries
        self.enableLogging = enableLogging
    }
}