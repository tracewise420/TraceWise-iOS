import Foundation

public struct Partner: Codable {
    public let id: String?
    public let name: String
    public let type: String
    public let email: String?
    public let status: String?
    public let createdAt: String?
    
    public init(id: String? = nil, name: String, type: String, email: String? = nil, status: String? = nil, createdAt: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.email = email
        self.status = status
        self.createdAt = createdAt
    }
}