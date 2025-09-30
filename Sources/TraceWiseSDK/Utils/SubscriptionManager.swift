import Foundation

class SubscriptionManager {
    private let storage = SubscriptionStorage()
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func getSubscriptionInfo() async throws -> SubscriptionInfo {
        let subscriptionInfo: SubscriptionInfo = try await apiClient.request(
            method: .GET,
            endpoint: "/v1/auth/me",
            body: nil,
            responseType: SubscriptionInfo.self
        )
        
        storage.save(subscriptionInfo)
        return subscriptionInfo
    }
    
    func checkRateLimit() throws {
        guard let subscriptionInfo = storage.load() else {
            // No subscription info, allow request
            return
        }
        
        if subscriptionInfo.usage.apiCallsThisMinute >= subscriptionInfo.limits.apiCallsPerMinute {
            throw TraceWiseError.rateLimitExceeded(retryAfter: subscriptionInfo.rateLimitInfo.retryAfter)
        }
    }
    
    func updateRateLimitInfo(from headers: [String: String]) {
        guard var subscriptionInfo = storage.load() else { return }
        
        let remaining = Int(headers["X-RateLimit-Remaining"] ?? "0") ?? 0
        let resetTime = headers["X-RateLimit-Reset"] ?? ""
        let retryAfter = Int(headers["Retry-After"] ?? "")
        
        let updatedRateLimitInfo = RateLimitInfo(
            remaining: remaining,
            resetTime: resetTime,
            retryAfter: retryAfter
        )
        
        let updatedUsage = CurrentUsage(
            productsThisMonth: subscriptionInfo.usage.productsThisMonth,
            eventsThisMonth: subscriptionInfo.usage.eventsThisMonth,
            apiCallsThisMinute: subscriptionInfo.limits.apiCallsPerMinute - remaining
        )
        
        subscriptionInfo = SubscriptionInfo(
            tier: subscriptionInfo.tier,
            limits: subscriptionInfo.limits,
            usage: updatedUsage,
            rateLimitInfo: updatedRateLimitInfo
        )
        
        storage.save(subscriptionInfo)
    }
}