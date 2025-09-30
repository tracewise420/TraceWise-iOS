import XCTest
@testable import TraceWiseSDK

final class MockTests: XCTestCase {
    
    var mockClient: SharedMockAPIClient!
    
    override func setUp() {
        super.setUp()
        mockClient = SharedMockAPIClient()
    }
    
    override func tearDown() {
        mockClient = nil
        super.tearDown()
    }
    
    func testMockAPIClientSuccess() async throws {
        let expectedProduct = Product(gtin: "1234567890123", name: "Test Product")
        mockClient.mockResponse = expectedProduct
        
        let result: Product = try await mockClient.request(
            method: .GET,
            endpoint: "/test",
            body: nil,
            responseType: Product.self
        )
        
        XCTAssertEqual(result.gtin, expectedProduct.gtin)
        XCTAssertEqual(result.name, expectedProduct.name)
        XCTAssertEqual(mockClient.requestCallCount, 1)
        XCTAssertEqual(mockClient.lastMethod, .GET)
        XCTAssertEqual(mockClient.lastEndpoint, "/test")
    }
    
    func testMockAPIClientError() async throws {
        mockClient.mockError = TraceWiseError.networkError(URLError(.notConnectedToInternet))
        
        do {
            let _: Product = try await mockClient.request(
                method: .GET,
                endpoint: "/test",
                body: nil,
                responseType: Product.self
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TraceWiseError)
        }
    }
}