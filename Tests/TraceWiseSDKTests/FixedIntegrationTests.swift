import XCTest
@testable import TraceWiseSDK

final class FixedIntegrationTests: XCTestCase {
    var sdk: TraceWiseSDK!
    let testGtin = "12345678901234"
    let testSerial = "SN123456"
    
    override func setUp() {
        super.setUp()
        let config = SDKConfig(
            baseURL: "https://api.tracewise.io",
            apiKey: "test-key"
        )
        sdk = TraceWiseSDK(config: config)
    }
    
    override func tearDown() {
        sdk = nil
        super.tearDown()
    }
    
    func testSDKInitialization() {
        XCTAssertNotNil(sdk)
        XCTAssertNotNil(sdk.products)
        XCTAssertNotNil(sdk.dpp)
        XCTAssertNotNil(sdk.search)
        XCTAssertNotNil(sdk.resolve)
        XCTAssertNotNil(sdk.cirpass)
    }
    
    func testDigitalLinkParsing() throws {
        let digitalLink = "https://id.gs1.org/01/\(testGtin)/21/\(testSerial)"
        let result = try sdk.parseDigitalLink(digitalLink)
        
        XCTAssertEqual(result.gtin, testGtin)
        XCTAssertEqual(result.serial, testSerial)
    }
    
    func testOfflineQueueManagement() {
        let initialSize = sdk.getOfflineQueueSize()
        XCTAssertGreaterThanOrEqual(initialSize, 0)
    }
    
    func testPerformanceMetrics() {
        let metrics = sdk.getPerformanceMetrics()
        XCTAssertNotNil(metrics)
        
        sdk.resetPerformanceMetrics()
        let resetMetrics = sdk.getPerformanceMetrics()
        XCTAssertNotNil(resetMetrics)
    }
}