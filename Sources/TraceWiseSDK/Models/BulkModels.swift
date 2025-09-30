import Foundation

public struct BulkResponse: Codable {
    public let success: Bool
    public let processed: Int
    public let failed: Int
    public let errors: [BulkError]?
}

public struct BulkError: Codable {
    public let index: Int
    public let error: String
    public let code: String?
}

public struct BulkProductsRequest: Codable {
    public let items: [Product]
}

public struct BulkEventsRequest: Codable {
    public let items: [LifecycleEvent]
}

public struct ProductUpdate: Codable {
    public let id: String
    public let name: String?
    public let description: String?
    
    public init(id: String, name: String? = nil, description: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
    }
}

public struct BulkDeleteRequest: Codable {
    public let ids: [String]
}