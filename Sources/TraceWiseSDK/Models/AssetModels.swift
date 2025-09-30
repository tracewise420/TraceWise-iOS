import Foundation

public struct Asset: Codable {
    public let id: String?
    public let name: String
    public let type: AssetType
    public let url: String?
    public let size: Int
    public let mimeType: String
    public let tags: [String]?
    public let productId: String?
    public let eventId: String?
    public let createdAt: String?
    public let updatedAt: String?
    
    public init(name: String, type: AssetType, size: Int, mimeType: String, tags: [String]? = nil, productId: String? = nil, eventId: String? = nil) {
        self.id = nil
        self.name = name
        self.type = type
        self.url = nil
        self.size = size
        self.mimeType = mimeType
        self.tags = tags
        self.productId = productId
        self.eventId = eventId
        self.createdAt = nil
        self.updatedAt = nil
    }
}

public enum AssetType: String, Codable {
    case image
    case document
    case video
    case audio
    case other
}

public struct AssetUploadRequest: Codable {
    public let name: String
    public let type: String
    public let size: Int
    public let mimeType: String
    public let tags: [String]?
    public let productId: String?
    public let eventId: String?
    
    public init(name: String, type: String, size: Int, mimeType: String, tags: [String]? = nil, productId: String? = nil, eventId: String? = nil) {
        self.name = name
        self.type = type
        self.size = size
        self.mimeType = mimeType
        self.tags = tags
        self.productId = productId
        self.eventId = eventId
    }
}

public struct AssetUploadResponse: Codable {
    public let id: String
    public let uploadUrl: String
    public let fields: [String: String]?
}

public struct AssetSearchParams {
    public let type: String?
    public let productId: String?
    public let eventId: String?
    public let tags: [String]?
    public let mimeType: String?
    public let pageSize: Int?
    public let pageToken: String?
    
    public init(type: String? = nil, productId: String? = nil, eventId: String? = nil, tags: [String]? = nil, mimeType: String? = nil, pageSize: Int? = nil, pageToken: String? = nil) {
        self.type = type
        self.productId = productId
        self.eventId = eventId
        self.tags = tags
        self.mimeType = mimeType
        self.pageSize = pageSize
        self.pageToken = pageToken
    }
}

public struct AssetDownloadResponse: Codable {
    public let url: String
    public let expiresAt: String
}