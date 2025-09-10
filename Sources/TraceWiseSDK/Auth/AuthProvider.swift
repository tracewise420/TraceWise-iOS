import Foundation
import FirebaseAuth

class AuthProvider {
    private let config: SDKConfig
    
    init(config: SDKConfig) {
        self.config = config
    }
    
    func getHeaders() async throws -> [String: String] {
        var headers: [String: String] = [:]
        
        // Add API key if available
        if let apiKey = config.apiKey {
            headers["x-api-key"] = apiKey
        }
        
        // Add Firebase token if available
        if let tokenProvider = config.firebaseTokenProvider {
            do {
                let token = try await tokenProvider()
                headers["Authorization"] = "Bearer \(token)"
            } catch {
                throw TraceWiseError.authenticationError("Failed to get Firebase token: \(error.localizedDescription)")
            }
        }
        
        return headers
    }
}