import XCTest
@testable import TraceWiseSDK

final class BasicFunctionalityTests: XCTestCase {
    
    func testSDKInitialization() {
        let config = SDKConfig(
            baseURL: "https://api.tracewise.io",
            apiKey: "test-key"
        )
        let sdk = TraceWiseSDK(config: config)
        
        XCTAssertNotNil(sdk)
        XCTAssertNotNil(sdk.products)
        XCTAssertNotNil(sdk.dpp)
        XCTAssertNotNil(sdk.search)
        XCTAssertNotNil(sdk.resolve)
        XCTAssertNotNil(sdk.cirpass)
    }
    
    func testDigitalLinkParsing() throws {
        let config = SDKConfig(baseURL: "https://api.tracewise.io", apiKey: "test-key")
        let sdk = TraceWiseSDK(config: config)
        
        let digitalLink = "https://id.gs1.org/01/12345678901234/21/ABC123"
        let result = try sdk.parseDigitalLink(digitalLink)
        
        XCTAssertEqual(result.gtin, "12345678901234")
        XCTAssertEqual(result.serial, "ABC123")
    }
    
    func testOfflineQueueSize() {
        let config = SDKConfig(baseURL: "https://api.tracewise.io", apiKey: "test-key")
        let sdk = TraceWiseSDK(config: config)
        
        let size = sdk.getOfflineQueueSize()
        XCTAssertGreaterThanOrEqual(size, 0)
    }
    
    func testPerformanceMetrics() {
        let config = SDKConfig(baseURL: "https://api.tracewise.io", apiKey: "test-key")
        let sdk = TraceWiseSDK(config: config)
        
        let metrics = sdk.getPerformanceMetrics()
        XCTAssertNotNil(metrics)
        
        sdk.resetPerformanceMetrics()
        let resetMetrics = sdk.getPerformanceMetrics()
        XCTAssertNotNil(resetMetrics)
    }
    
    func testHTTPMethods() {
        XCTAssertEqual(HTTPMethod.GET.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.POST.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.PUT.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.DELETE.rawValue, "DELETE")
    }
    
    func testTraceWiseErrors() {
        let invalidURL = TraceWiseError.invalidURL
        XCTAssertEqual(invalidURL.code, "INVALID_URL")
        
        let apiError = TraceWiseError.apiError(code: "TEST", message: "Test message", statusCode: 400)
        XCTAssertEqual(apiError.code, "TEST")
        XCTAssertEqual(apiError.errorDescription, "Test message")
        
        let rateLimitError = TraceWiseError.rateLimitExceeded(retryAfter: 60)
        XCTAssertEqual(rateLimitError.code, "RATE_LIMIT_EXCEEDED")
    }
    
    func testAnyCodableEquality() {
        let string1 = AnyCodable("test")
        let string2 = AnyCodable("test")
        let string3 = AnyCodable("different")
        let int1 = AnyCodable(42)
        
        XCTAssertEqual(string1, string2)
        XCTAssertNotEqual(string1, string3)
        XCTAssertNotEqual(string1, int1)
    }
    
    func testProductModel() {
        let product = Product(
            gtin: "12345678901234",
            serial: "SN123",
            name: "Test Product"
        )
        
        XCTAssertEqual(product.gtin, "12345678901234")
        XCTAssertEqual(product.serial, "SN123")
        XCTAssertEqual(product.name, "Test Product")
    }
    
    func testProductIDs() {
        let productIds = ProductIDs(
            gtin: "12345678901234",
            serial: "SN123"
        )
        
        XCTAssertEqual(productIds.gtin, "12345678901234")
        XCTAssertEqual(productIds.serial, "SN123")
    }
    
    func testSubscriptionTier() {
        XCTAssertEqual(SubscriptionTier.free.rawValue, "free")
        XCTAssertEqual(SubscriptionTier.paid.rawValue, "paid")
    }
}