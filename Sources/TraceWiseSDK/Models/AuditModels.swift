import Foundation

public struct AuditLog: Codable {
    public let id: String
    public let timestamp: String
    public let userId: String
    public let action: String
    public let resource: String
    public let details: [String: AnyCodable]?
    
    public init(id: String, timestamp: String, userId: String, action: String, resource: String, details: [String: AnyCodable]? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.userId = userId
        self.action = action
        self.resource = resource
        self.details = details
    }
}