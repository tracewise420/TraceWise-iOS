import Foundation
import FirebaseAuth

public class AuthProvider {
    private let config: SDKConfig
    private let keychain = KeychainManager()
    private let jwtTokenKey = "tracewise_jwt_token"
    
    init(config: SDKConfig) {
        self.config = config
    }
    
    func getHeaders() async throws -> [String: String] {
        var headers: [String: String] = [:]
        
        // Add API key
        headers["x-api-key"] = config.apiKey
        
        // Always use Firebase token (like Android)
        if let firebaseUser = Auth.auth().currentUser {
            do {
                let firebaseToken = try await firebaseUser.getIDToken()
                headers["Authorization"] = "Bearer \(firebaseToken)"
            } catch {
                // Silent fallback - no token available
            }
        }
        
        return headers
    }
    
    // MARK: - JWT Authentication Methods
    
    public func getAuthToken(_ firebaseToken: String) async throws -> JWTAuthResponse {
        let url = URL(string: "\(config.baseURL)v1/auth/token")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        
        let body = ["firebaseToken": firebaseToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TraceWiseError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TraceWiseError.authenticationError("JWT exchange failed: \(httpResponse.statusCode)")
        }
        
        let jwtResponse = try JSONDecoder().decode(JWTAuthResponse.self, from: data)
        storeJWTToken(jwtResponse.accessToken)
        
        return jwtResponse
    }
    
    public func refreshJWTToken() async throws -> String {
        guard let tokenProvider = config.firebaseTokenProvider else {
            throw TraceWiseError.authenticationError("No Firebase token provider available")
        }
        
        let firebaseToken = try await tokenProvider()
        let jwtResponse = try await getAuthToken(firebaseToken)
        return jwtResponse.accessToken
    }
    
    public func getStoredJWTToken() async throws -> String {
        guard let token = keychain.retrieve(forKey: jwtTokenKey) else {
            throw TraceWiseError.authenticationError("No JWT token stored")
        }
        return token
    }
    
    func getJWTHeaders() async throws -> [String: String] {
        guard let jwtToken = keychain.retrieve(forKey: jwtTokenKey) else {
            throw TraceWiseError.authenticationError("No JWT token available")
        }
        
        if !isTokenValid(jwtToken) {
            let newToken = try await refreshJWTToken()
            return ["Authorization": "Bearer \(newToken)"]
        }
        
        return ["Authorization": "Bearer \(jwtToken)"]
    }
    
    func storeJWTToken(_ token: String) {
        keychain.store(token, forKey: jwtTokenKey)
    }
    
    private func isTokenValid(_ token: String) -> Bool {
        guard let payload = decodeJWTPayload(token) else { return false }
        let now = Int(Date().timeIntervalSince1970)
        return payload.exp > now
    }
    
    private func decodeJWTPayload(_ token: String) -> JWTPayload? {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }
        
        var base64 = parts[1]
        while base64.count % 4 != 0 {
            base64 += "="
        }
        
        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONDecoder().decode(JWTPayload.self, from: data)
    }
}

private class KeychainManager {
    func store(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
}