import Foundation

public struct Product: Codable, Equatable {
    public let gtin: String
    public let serial: String?
    public let name: String
    public let description: String?
    public let manufacturer: String?
    public let category: String?
    
    public init(
        gtin: String,
        serial: String? = nil,
        name: String,
        description: String? = nil,
        manufacturer: String? = nil,
        category: String? = nil
    ) {
        self.gtin = gtin
        self.serial = serial
        self.name = name
        self.description = description
        self.manufacturer = manufacturer
        self.category = category
    }
}

public struct ProductIDs: Equatable {
    public let gtin: String
    public let serial: String?
    public let batch: String?
    public let expiry: String?
    
    public init(gtin: String, serial: String? = nil, batch: String? = nil, expiry: String? = nil) {
        self.gtin = gtin
        self.serial = serial
        self.batch = batch
        self.expiry = expiry
    }
}

public struct PaginatedResponse<T: Codable>: Codable {
    public let items: [T]
    public let nextPageToken: String?
    public let totalCount: Int?
    
    public init(items: [T], nextPageToken: String? = nil, totalCount: Int? = nil) {
        self.items = items
        self.nextPageToken = nextPageToken
        self.totalCount = totalCount
    }
}