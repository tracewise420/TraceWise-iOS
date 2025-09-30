import XCTest
@testable import TraceWiseSDK

final class ModelsTests: XCTestCase {
    
    func testWarrantyStatusModel() {
        let warrantyStatus = WarrantyStatus(
            gtin: "12345678901234",
            serial: "ABC123",
            status: "active",
            validUntil: "2025-01-01",
            coverage: "full"
        )
        
        XCTAssertEqual(warrantyStatus.gtin, "12345678901234")
        XCTAssertEqual(warrantyStatus.serial, "ABC123")
        XCTAssertEqual(warrantyStatus.status, "active")
        XCTAssertEqual(warrantyStatus.validUntil, "2025-01-01")
        XCTAssertEqual(warrantyStatus.coverage, "full")
    }
    
    func testRepairOrderModel() {
        let repairOrder = RepairOrder(
            id: "repair123",
            gtin: "12345678901234",
            serial: "ABC123",
            issue: "Screen cracked",
            status: "pending",
            createdAt: "2024-01-01T10:00:00Z"
        )
        
        XCTAssertEqual(repairOrder.id, "repair123")
        XCTAssertEqual(repairOrder.gtin, "12345678901234")
        XCTAssertEqual(repairOrder.serial, "ABC123")
        XCTAssertEqual(repairOrder.issue, "Screen cracked")
        XCTAssertEqual(repairOrder.status, "pending")
        XCTAssertEqual(repairOrder.createdAt, "2024-01-01T10:00:00Z")
    }
    
    func testAuditLogModel() {
        let auditLog = AuditLog(
            id: "audit123",
            timestamp: "2024-01-01T10:00:00Z",
            userId: "user123",
            action: "create",
            resource: "product:12345678901234"
        )
        
        XCTAssertEqual(auditLog.id, "audit123")
        XCTAssertEqual(auditLog.timestamp, "2024-01-01T10:00:00Z")
        XCTAssertEqual(auditLog.userId, "user123")
        XCTAssertEqual(auditLog.action, "create")
        XCTAssertEqual(auditLog.resource, "product:12345678901234")
    }
    
    func testPartnerModel() {
        let partner = Partner(
            id: "partner123",
            name: "Repair Partner Inc",
            type: "repair",
            email: "contact@repairpartner.com",
            status: "active",
            createdAt: "2024-01-01T10:00:00Z"
        )
        
        XCTAssertEqual(partner.id, "partner123")
        XCTAssertEqual(partner.name, "Repair Partner Inc")
        XCTAssertEqual(partner.type, "repair")
        XCTAssertEqual(partner.email, "contact@repairpartner.com")
        XCTAssertEqual(partner.status, "active")
        XCTAssertEqual(partner.createdAt, "2024-01-01T10:00:00Z")
    }
    
    func testWarrantyStatusCodable() throws {
        let warrantyStatus = WarrantyStatus(
            gtin: "12345678901234",
            serial: "ABC123",
            status: "active",
            validUntil: "2025-01-01",
            coverage: "full"
        )
        
        let encoded = try JSONEncoder().encode(warrantyStatus)
        let decoded = try JSONDecoder().decode(WarrantyStatus.self, from: encoded)
        
        XCTAssertEqual(decoded.gtin, warrantyStatus.gtin)
        XCTAssertEqual(decoded.serial, warrantyStatus.serial)
        XCTAssertEqual(decoded.status, warrantyStatus.status)
        XCTAssertEqual(decoded.validUntil, warrantyStatus.validUntil)
        XCTAssertEqual(decoded.coverage, warrantyStatus.coverage)
    }
    
    func testRepairOrderCodable() throws {
        let repairOrder = RepairOrder(
            id: "repair123",
            gtin: "12345678901234",
            serial: "ABC123",
            issue: "Screen cracked",
            status: "pending",
            createdAt: "2024-01-01T10:00:00Z"
        )
        
        let encoded = try JSONEncoder().encode(repairOrder)
        let decoded = try JSONDecoder().decode(RepairOrder.self, from: encoded)
        
        XCTAssertEqual(decoded.id, repairOrder.id)
        XCTAssertEqual(decoded.gtin, repairOrder.gtin)
        XCTAssertEqual(decoded.serial, repairOrder.serial)
        XCTAssertEqual(decoded.issue, repairOrder.issue)
        XCTAssertEqual(decoded.status, repairOrder.status)
        XCTAssertEqual(decoded.createdAt, repairOrder.createdAt)
    }
}