import Foundation

public struct CirpassProduct: Codable {
    public let id: String
    public let gtin: String?
    public let serial: String?
    public let name: String
    public let manufacturer: Manufacturer?
    public let materials: [String]?
    public let origin: String?
    public let lifecycle: [LifecycleInfo]?
    public let warranty: Warranty?
    public let repairability: Repairability?
    
    public struct Manufacturer: Codable {
        public let name: String
        public let country: String
    }
    
    public struct LifecycleInfo: Codable {
        public let eventType: String
        public let timestamp: String
        public let details: [String: AnyCodable]?
    }
    
    public struct Warranty: Codable {
        public let ends: String
    }
    
    public struct Repairability: Codable {
        public let score: Double
    }
}

public struct CirpassProductsResponse: Codable {
    public let products: [CirpassProduct]
}