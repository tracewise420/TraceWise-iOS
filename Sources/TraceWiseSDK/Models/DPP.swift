import Foundation

// MARK: - DPP Models

public struct DPP: Codable, Equatable {
    public let id: String
    public let gtin: String
    public let serial: String?
    public let claims: [String: AnyCodable]
    public let links: [String: String]
    public let signatures: [DPPSignature]
    public let source: String
    public let fetchedAt: String
    public let rawHash: String
    public let createdAt: String
    public let updatedAt: String
    
    public init(
        id: String,
        gtin: String,
        serial: String? = nil,
        claims: [String: AnyCodable],
        links: [String: String],
        signatures: [DPPSignature] = [],
        source: String,
        fetchedAt: String,
        rawHash: String,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.gtin = gtin
        self.serial = serial
        self.claims = claims
        self.links = links
        self.signatures = signatures
        self.source = source
        self.fetchedAt = fetchedAt
        self.rawHash = rawHash
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct DPPSignature: Codable, Equatable {
    public let algorithm: String
    public let signature: String
    public let publicKey: String
    public let timestamp: String
    
    public init(algorithm: String, signature: String, publicKey: String, timestamp: String) {
        self.algorithm = algorithm
        self.signature = signature
        self.publicKey = publicKey
        self.timestamp = timestamp
    }
}

public struct DPPCreateRequest: Codable {
    public let gtin: String
    public let serial: String?
    public let claims: [String: AnyCodable]
    public let links: [String: String]
    public let source: String
    
    public init(gtin: String, serial: String? = nil, claims: [String: AnyCodable], links: [String: String], source: String) {
        self.gtin = gtin
        self.serial = serial
        self.claims = claims
        self.links = links
        self.source = source
    }
}

public struct DPPVerificationResult: Codable, Equatable {
    public let valid: Bool
    public let details: [String]
    
    public init(valid: Bool, details: [String]) {
        self.valid = valid
        self.details = details
    }
}

public struct DPPClaimsUpdate: Codable {
    public let path: String
    public let op: String
    public let value: AnyCodable?
    
    public init(path: String, op: String, value: AnyCodable? = nil) {
        self.path = path
        self.op = op
        self.value = value
    }
}

// MARK: - AnyCodable Helper

public struct AnyCodable: Codable, Equatable {
    public let value: Any
    
    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.init(())
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([AnyCodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        default:
            return false
        }
    }
}