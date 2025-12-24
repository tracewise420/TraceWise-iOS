import Foundation

/// JWT Authentication Response
public struct JWTAuthResponse: Codable {
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "access_token": accessToken,
            "token_type": tokenType,
            "expires_in": expiresIn
        ]
    }
}

/// JWT Token Payload
public struct JWTPayload: Codable {
    public let userId: String
    public let email: String
    public let tenantId: String
    public let roles: [String]
    public let exp: Int
    public let iat: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case tenantId = "tenant_id"
        case roles
        case exp
        case iat
    }
}