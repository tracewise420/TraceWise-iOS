import XCTest
@testable import TraceWiseSDK

final class SubscriptionManagerTests: XCTestCase {
    var mockAPIClient: SharedMockAPIClient!
    var subscriptionManager: SubscriptionManager!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = SharedMockAPIClient()
        subscriptionManager = SubscriptionManager(apiClient: mockAPIClient)
    }
    
    func testGetSubscriptionInfo() async throws {
        let expectedSubscription = SubscriptionInfo(
            tier: .free,
            limits: UsageLimits(productsPerMonth: 100, eventsPerMonth: 1000, apiCallsPerMinute: 60),
            usage: CurrentUsage(productsThisMonth: 10, eventsThisMonth: 50, apiCallsThisMinute: 5),
            rateLimitInfo: RateLimitInfo(remaining: 55, resetTime: "2025-01-27T11:00:00Z")
        )
        
        mockAPIClient.mockResponse = expectedSubscription
        
        let result = try await subscriptionManager.getSubscriptionInfo()
        
        XCTAssertEqual(result.tier, .free)
        XCTAssertEqual(result.limits.apiCallsPerMinute, 60)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/auth/me")
    }
    
    func testCheckRateLimit() throws {
        let subscription = SubscriptionInfo(
            tier: .free,
            limits: UsageLimits(productsPerMonth: 100, eventsPerMonth: 1000, apiCallsPerMinute: 60),
            usage: CurrentUsage(productsThisMonth: 10, eventsThisMonth: 50, apiCallsThisMinute: 65),
            rateLimitInfo: RateLimitInfo(remaining: 0, resetTime: "2025-01-27T11:00:00Z")
        )
        
        let storage = SubscriptionStorage()
        storage.save(subscription)
        
        XCTAssertThrowsError(try subscriptionManager.checkRateLimit()) { error in
            XCTAssertTrue(error is TraceWiseError)
        }
    }
}