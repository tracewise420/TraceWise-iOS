import Foundation

public struct WarrantyStatus: Codable {
    public let gtin: String
    public let serial: String?
    public let status: String
    public let validUntil: String?
    public let coverage: String?
    
    public init(gtin: String, serial: String? = nil, status: String, validUntil: String? = nil, coverage: String? = nil) {
        self.gtin = gtin
        self.serial = serial
        self.status = status
        self.validUntil = validUntil
        self.coverage = coverage
    }
}

public struct RepairOrder: Codable {
    public let id: String?
    public let gtin: String
    public let serial: String?
    public let issue: String
    public let status: String?
    public let createdAt: String?
    
    public init(id: String? = nil, gtin: String, serial: String? = nil, issue: String, status: String? = nil, createdAt: String? = nil) {
        self.id = id
        self.gtin = gtin
        self.serial = serial
        self.issue = issue
        self.status = status
        self.createdAt = createdAt
    }
}