import Foundation
@testable import TraceWiseSDK

// Shared Mock API Client for all tests
class SharedMockAPIClient: APIClientProtocol {
    var mockResponse: Any?
    var mockError: Error?
    var requestCallCount = 0
    var lastMethod: HTTPMethod?
    var lastEndpoint: String?
    var lastBody: Data?
    
    func request<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: Data?,
        responseType: T.Type
    ) async throws -> T {
        requestCallCount += 1
        lastMethod = method
        lastEndpoint = endpoint
        lastBody = body
        
        if let error = mockError {
            throw error
        }
        
        // Handle empty response types by creating an instance from empty JSON
        if let response = mockResponse as? T {
            return response
        } else {
            // Try to decode from empty JSON for empty response types
            let emptyJSON = "{}".data(using: .utf8)!
            if let emptyResponse = try? JSONDecoder().decode(T.self, from: emptyJSON) {
                return emptyResponse
            }
            throw TraceWiseError.invalidResponse
        }
    }
    
    func reset() {
        mockResponse = nil
        mockError = nil
        requestCallCount = 0
        lastMethod = nil
        lastEndpoint = nil
        lastBody = nil
    }
}