import Foundation

// MARK: - Search Models

public struct SearchResult: Codable, Equatable {
    public let id: String
    public let type: String
    public let gtin: String?
    public let serial: String?
    public let name: String
    public let description: String?
    public let score: Double
    public let metadata: [String: AnyCodable]?
    
    public init(
        id: String,
        type: String,
        gtin: String? = nil,
        serial: String? = nil,
        name: String,
        description: String? = nil,
        score: Double,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.id = id
        self.type = type
        self.gtin = gtin
        self.serial = serial
        self.name = name
        self.description = description
        self.score = score
        self.metadata = metadata
    }
}

public struct ProductFilters: Codable {
    public let category: String?
    public let manufacturer: String?
    public let minScore: Double?
    public let maxResults: Int?
    
    public init(category: String? = nil, manufacturer: String? = nil, minScore: Double? = nil, maxResults: Int? = nil) {
        self.category = category
        self.manufacturer = manufacturer
        self.minScore = minScore
        self.maxResults = maxResults
    }
}

public struct SearchRequest: Codable {
    public let query: String
    public let filters: [String: AnyCodable]?
    public let limit: Int?
    
    public init(query: String, filters: [String: AnyCodable]? = nil, limit: Int? = nil) {
        self.query = query
        self.filters = filters
        self.limit = limit
    }
}