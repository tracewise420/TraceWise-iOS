import XCTest
@testable import TraceWiseSDK

// Mock API Client for testing
class MockAPIClient: APIClientProtocol {
    var mockResponse: Any?
    var mockError: Error?
    var requestCallCount = 0
    var lastMethod: HTTPMethod?
    var lastEndpoint: String?
    
    func request<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: Data?,
        responseType: T.Type
    ) async throws -> T {
        requestCallCount += 1
        lastMethod = method
        lastEndpoint = endpoint
        
        if let error = mockError {
            throw error
        }
        
        guard let response = mockResponse as? T else {
            throw TraceWiseError.invalidResponse
        }
        
        return response
    }
}

final class MockTests: XCTestCase {
    
    var mockClient: MockAPIClient!
    
    override func setUp() {
        super.setUp()
        mockClient = MockAPIClient()
    }
    
    func testMockAPIClientSuccess() async throws {
        let expectedProduct = Product(gtin: "123", name: "Test Product")
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
    
    func testMockAPIClientError() async {
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
            XCTAssertEqual(mockClient.requestCallCount, 1)
        }
    }
    
    func testRetryManagerWithMock() async throws {
        let retryManager = RetryManager(maxRetries: 2)
        var attemptCount = 0
        
        let result = try await retryManager.retry {
            attemptCount += 1
            if attemptCount < 2 {
                throw TraceWiseError.networkError(URLError(.timedOut))
            }
            return "Success"
        }
        
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(attemptCount, 2)
    }
}