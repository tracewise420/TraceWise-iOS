import Foundation

class CSRFManager {
    private let apiClient: APIClientProtocol
    private var cachedToken: String?
    private var tokenExpiry: Date?
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func getCSRFToken() async throws -> String {
        // Check if we have a valid cached token
        if let token = cachedToken,
           let expiry = tokenExpiry,
           expiry > Date() {
            return token
        }
        
        // Fetch new token
        let response: CSRFTokenResponse = try await apiClient.request(
            method: .GET,
            endpoint: "/v1/csrf-token",
            body: nil,
            responseType: CSRFTokenResponse.self
        )
        
        // Cache token for 30 minutes
        cachedToken = response.csrfToken
        tokenExpiry = Date().addingTimeInterval(30 * 60)
        
        return response.csrfToken
    }
    
    func clearToken() {
        cachedToken = nil
        tokenExpiry = nil
    }
}

struct CSRFTokenResponse: Codable {
    let csrfToken: String
    let timestamp: String
}