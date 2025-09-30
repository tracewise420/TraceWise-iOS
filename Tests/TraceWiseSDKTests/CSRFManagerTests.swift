import XCTest
@testable import TraceWiseSDK

final class CSRFManagerTests: XCTestCase {
    var mockAPIClient: SharedMockAPIClient!
    var csrfManager: CSRFManager!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = SharedMockAPIClient()
        csrfManager = CSRFManager(apiClient: mockAPIClient)
    }
    
    func testGetCSRFToken() async throws {
        let expectedResponse = CSRFTokenResponse(
            csrfToken: "csrf_token_123",
            timestamp: "2025-01-27T10:00:00Z"
        )
        
        mockAPIClient.mockResponse = expectedResponse
        
        let token = try await csrfManager.getCSRFToken()
        
        XCTAssertEqual(token, "csrf_token_123")
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/csrf-token")
    }
    
    func testTokenCaching() async throws {
        let expectedResponse = CSRFTokenResponse(
            csrfToken: "csrf_token_123",
            timestamp: "2025-01-27T10:00:00Z"
        )
        
        mockAPIClient.mockResponse = expectedResponse
        
        // First call should fetch token
        let token1 = try await csrfManager.getCSRFToken()
        
        // Second call should use cached token (no API call)
        mockAPIClient.lastEndpoint = nil
        let token2 = try await csrfManager.getCSRFToken()
        
        XCTAssertEqual(token1, token2)
        XCTAssertNil(mockAPIClient.lastEndpoint)
    }
    
    func testClearToken() async throws {
        let expectedResponse = CSRFTokenResponse(
            csrfToken: "csrf_token_123",
            timestamp: "2025-01-27T10:00:00Z"
        )
        
        mockAPIClient.mockResponse = expectedResponse
        
        // Get token first
        _ = try await csrfManager.getCSRFToken()
        
        // Clear token
        csrfManager.clearToken()
        
        // Next call should fetch new token
        mockAPIClient.lastEndpoint = nil
        _ = try await csrfManager.getCSRFToken()
        
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/csrf-token")
    }
}