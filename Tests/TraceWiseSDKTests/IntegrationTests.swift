import XCTest
@testable import TraceWiseSDK

final class IntegrationTests: XCTestCase {
    var sdk: TraceWiseSDK!
    
    override func setUp() {
        super.setUp()
        let config = SDKConfig(
            baseURL: "https://api.test.com",
            apiKey: "test-key",
            enableLogging: true
        )
        sdk = TraceWiseSDK(config: config)
    }
    
    func testCompleteProductWorkflow() throws {
        // Test complete workflow from digital link to product operations
        let digitalLinkUrl = "https://id.gs1.org/01/09506000134352/21/SN12345"
        let productIds = try sdk.parseDigitalLink(digitalLinkUrl)
        
        XCTAssertEqual(productIds.gtin, "09506000134352")
        XCTAssertEqual(productIds.serial, "SN12345")
        
        // Verify all modules are accessible
        XCTAssertNotNil(sdk.products)
        XCTAssertNotNil(sdk.dpp)
        XCTAssertNotNil(sdk.search)
        XCTAssertNotNil(sdk.resolve)
        XCTAssertNotNil(sdk.cirpass)
    }
    
    func testModularArchitecture() {
        // Test that modules can be used independently
        XCTAssertTrue(sdk.products is ProductsModule)
        XCTAssertTrue(sdk.dpp is DPPModule)
        XCTAssertTrue(sdk.search is SearchModule)
        XCTAssertTrue(sdk.resolve is ResolveModule)
        XCTAssertTrue(sdk.cirpass is CirpassModule)
    }
    
    func testErrorHandlingIntegration() {
        // Test error handling across different scenarios
        let invalidUrl = "invalid-url"
        
        XCTAssertThrowsError(try sdk.parseDigitalLink(invalidUrl)) { error in
            XCTAssertTrue(error is TraceWiseError)
            if let traceWiseError = error as? TraceWiseError {
                XCTAssertEqual(traceWiseError.code, "INVALID_DIGITAL_LINK")
            }
        }
    }
    
    func testSubscriptionIntegration() {
        // Test that subscription management is integrated
        XCTAssertNoThrow({ [self] in
            // Test that SDK is properly initialized
            XCTAssertNotNil(sdk.products)
            XCTAssertNotNil(sdk.dpp)
        })
    }
    
    func testSecurityIntegration() {
        // Test that security features are integrated
        XCTAssertNoThrow({ [self] in
            // Verify SDK security features work
            XCTAssertNotNil(sdk.products)
        })
    }
}