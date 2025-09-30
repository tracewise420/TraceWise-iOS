import Foundation

// MARK: - Subscription Models

public struct SubscriptionInfo: Codable, Equatable {
    public let tier: SubscriptionTier
    public let limits: UsageLimits
    public let usage: CurrentUsage
    public let rateLimitInfo: RateLimitInfo
    
    public init(tier: SubscriptionTier, limits: UsageLimits, usage: CurrentUsage, rateLimitInfo: RateLimitInfo) {
        self.tier = tier
        self.limits = limits
        self.usage = usage
        self.rateLimitInfo = rateLimitInfo
    }
}

public enum SubscriptionTier: String, Codable {
    case free = "free"
    case paid = "paid"
}

public struct UsageLimits: Codable, Equatable {
    public let productsPerMonth: Int
    public let eventsPerMonth: Int
    public let apiCallsPerMinute: Int
    
    public init(productsPerMonth: Int, eventsPerMonth: Int, apiCallsPerMinute: Int) {
        self.productsPerMonth = productsPerMonth
        self.eventsPerMonth = eventsPerMonth
        self.apiCallsPerMinute = apiCallsPerMinute
    }
}

public struct CurrentUsage: Codable, Equatable {
    public let productsThisMonth: Int
    public let eventsThisMonth: Int
    public let apiCallsThisMinute: Int
    
    public init(productsThisMonth: Int, eventsThisMonth: Int, apiCallsThisMinute: Int) {
        self.productsThisMonth = productsThisMonth
        self.eventsThisMonth = eventsThisMonth
        self.apiCallsThisMinute = apiCallsThisMinute
    }
}

public struct RateLimitInfo: Codable, Equatable {
    public let remaining: Int
    public let resetTime: String
    public let retryAfter: Int?
    
    public init(remaining: Int, resetTime: String, retryAfter: Int? = nil) {
        self.remaining = remaining
        self.resetTime = resetTime
        self.retryAfter = retryAfter
    }
}