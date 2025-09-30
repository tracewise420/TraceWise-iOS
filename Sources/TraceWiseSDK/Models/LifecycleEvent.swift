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



