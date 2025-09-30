import Foundation

// MARK: - API Response Models

public struct CreateResponse: Codable {
    public let id: String
    public let status: String
    
    public init(id: String, status: String) {
        self.id = id
        self.status = status
    }
}



public struct APIError: Codable {
    public let code: String
    public let message: String
    public let details: [String: AnyCodable]?
    
    public init(code: String, message: String, details: [String: AnyCodable]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

// MARK: - Supporting Request Models

public struct RegisterProductRequest: Codable {
    public let gtin: String
    public let serial: String?
    public let userId: String?
    
    public init(gtin: String, serial: String? = nil, userId: String? = nil) {
        self.gtin = gtin
        self.serial = serial
        self.userId = userId
    }
}

public struct RegisterResponse: Codable {
    public let status: String
    
    public init(status: String) {
        self.status = status
    }
}

public struct EmptyResponse: Codable {
    public init() {}
}