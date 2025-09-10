import Foundation

public struct SubscriptionInfo: Codable {
    public let tier: String // free, premium, enterprise
    public let limits: Limits
    public let usage: Usage
    
    public struct Limits: Codable {
        public let productsPerMonth: Int
        public let eventsPerMonth: Int
        public let apiCallsPerMinute: Int
    }
    
    public struct Usage: Codable {
        public let productsThisMonth: Int
        public let eventsThisMonth: Int
        public let apiCallsThisMinute: Int
    }
}

public struct HealthResponse: Codable {
    public let status: String
    public let timestamp: String
    public let version: String?
}