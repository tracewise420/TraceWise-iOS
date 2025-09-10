import Foundation

// EPCIS 2.0 compliant lifecycle event structure
public struct LifecycleEvent: Codable, Equatable {
    public let gtin: String
    public let serial: String?
    public let type: String
    public let action: String
    public let bizStep: String
    public let disposition: String
    public let timestamp: String
    public let readPoint: String?
    public let bizLocation: String?
    public let details: [String: AnyCodable]?
    
    private enum CodingKeys: String, CodingKey {
        case gtin, serial, type, action, bizStep, disposition
        case timestamp = "when"
        case readPoint, bizLocation, details
    }
    
    public init(
        gtin: String,
        serial: String? = nil,
        type: String = "ObjectEvent",
        action: String = "OBSERVE",
        bizStep: String,
        disposition: String = "active",
        timestamp: String,
        readPoint: String? = nil,
        bizLocation: String? = nil,
        details: [String: Any]? = nil
    ) {
        self.gtin = gtin
        self.serial = serial
        self.type = type
        self.action = action
        self.bizStep = bizStep
        self.disposition = disposition
        self.timestamp = timestamp
        self.readPoint = readPoint
        self.bizLocation = bizLocation
        self.details = details?.mapValues { AnyCodable($0) }
    }
}

public struct EventResponse: Codable {
    public let id: String
    public let status: String
    public let epcisUrn: String?
}

// Helper for encoding/decoding Any values
public struct AnyCodable: Codable, Equatable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (l as Int, r as Int): return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as String, r as String): return l == r
        case let (l as Bool, r as Bool): return l == r
        default: return false
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}