import Foundation

// MARK: - Shared Response Models

public struct EventResponse: Codable {
    public let id: String
    public let status: String
    public let epcisUrn: String?
    
    public init(id: String, status: String, epcisUrn: String? = nil) {
        self.id = id
        self.status = status
        self.epcisUrn = epcisUrn
    }
}

public struct HealthResponse: Codable {
    public let status: String
    public let timestamp: String
    public let version: String?
    
    public init(status: String, timestamp: String, version: String? = nil) {
        self.status = status
        self.timestamp = timestamp
        self.version = version
    }
}

public struct APIErrorResponse: Codable {
    public let error: APIErrorDetail
    
    public init(error: APIErrorDetail) {
        self.error = error
    }
}

public struct APIErrorDetail: Codable {
    public let code: String
    public let message: String
    public let correlationId: String?
    
    public init(code: String, message: String, correlationId: String? = nil) {
        self.code = code
        self.message = message
        self.correlationId = correlationId
    }
}