import Foundation
@testable import TraceWiseSDK

class MockAPIClient: APIClient {
    var lastMethod: HTTPMethod?
    var lastEndpoint: String?
    var lastBody: Data?
    var mockResponse: Any?
    var shouldThrowError: Error?
    
    override func request<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: Data?,
        responseType: T.Type
    ) async throws -> T {
        self.lastMethod = method
        self.lastEndpoint = endpoint
        self.lastBody = body
        
        if let error = shouldThrowError {
            throw error
        }
        
        if let response = mockResponse as? T {
            return response
        }
        
        // Return a default response for testing
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        throw TraceWiseError.invalidResponse
    }
}