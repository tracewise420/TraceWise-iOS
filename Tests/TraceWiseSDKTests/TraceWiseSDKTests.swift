import XCTest
@testable import TraceWiseSDK

final class TraceWiseSDKTests: XCTestCase {
    
    var sdk: TraceWiseSDK!
    
    override func setUp() {
        super.setUp()
        let config = SDKConfig(
            baseURL: "https://api.test.com",
            enableLogging: true
        )
        sdk = TraceWiseSDK(config: config)
    }
    
    func testParseDigitalLinkIntegration() throws {
        let url = "https://id.gs1.org/01/09506000134352/21/SN12345"
        let result = try sdk.parseDigitalLink(url)
        
        XCTAssertEqual(result.gtin, "09506000134352")
        XCTAssertEqual(result.serial, "SN12345")
    }
    
    func testSDKInitialization() {
        XCTAssertNotNil(sdk)
    }
    
    func testSDKConfigurationWithFirebase() {
        let config = SDKConfig(
            baseURL: "https://trace-wise.eu/api",
            apiKey: "test-key",
            firebaseTokenProvider: {
                return "mock-firebase-token"
            },
            timeoutInterval: 60.0,
            maxRetries: 5,
            enableLogging: true
        )
        
        let sdkWithFirebase = TraceWiseSDK(config: config)
        XCTAssertNotNil(sdkWithFirebase)
    }
    
    func testErrorHandling() {
        let invalidURL = "invalid-url"
        
        XCTAssertThrowsError(try sdk.parseDigitalLink(invalidURL)) { error in
            XCTAssertTrue(error is TraceWiseError)
        }
    }
}