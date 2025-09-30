import XCTest
@testable import TraceWiseSDK

final class DPPModuleTests: XCTestCase {
    var mockAPIClient: SharedMockAPIClient!
    var dppModule: DPPModule!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = SharedMockAPIClient()
        dppModule = DPPModule(apiClient: mockAPIClient)
    }
    
    override func tearDown() {
        mockAPIClient = nil
        dppModule = nil
        super.tearDown()
    }
    
    func testCreateDPP() async throws {
        // Given
        let dppData = DPPCreateRequest(
            gtin: "1234567890123",
            serial: "SN123",
            claims: ["name": AnyCodable("Test Product")],
            links: ["website": "https://example.com"],
            source: "test"
        )
        
        let expectedDPP = DPP(
            id: "dpp_123",
            gtin: "1234567890123",
            serial: "SN123",
            claims: ["name": AnyCodable("Test Product")],
            links: ["website": "https://example.com"],
            signatures: [],
            source: "test",
            fetchedAt: "2025-01-27T10:00:00Z",
            rawHash: "hash123",
            createdAt: "2025-01-27T10:00:00Z",
            updatedAt: "2025-01-27T10:00:00Z"
        )
        
        mockAPIClient.mockResponse = expectedDPP
        
        // When
        let result = try await dppModule.createDPP(dppData: dppData)
        
        // Then
        XCTAssertEqual(result.id, "dpp_123")
        XCTAssertEqual(result.gtin, "1234567890123")
        XCTAssertEqual(result.serial, "SN123")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.POST)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/dpp")
    }
    
    func testGetDPP() async throws {
        // Given
        let expectedDPP = DPP(
            id: "dpp_123",
            gtin: "1234567890123",
            serial: "SN123",
            claims: ["name": AnyCodable("Test Product")],
            links: ["website": "https://example.com"],
            signatures: [],
            source: "test",
            fetchedAt: "2025-01-27T10:00:00Z",
            rawHash: "hash123",
            createdAt: "2025-01-27T10:00:00Z",
            updatedAt: "2025-01-27T10:00:00Z"
        )
        
        mockAPIClient.mockResponse = expectedDPP
        
        // When
        let result = try await dppModule.getDPP(gtin: "1234567890123", serial: "SN123")
        
        // Then
        XCTAssertEqual(result.id, "dpp_123")
        XCTAssertEqual(result.gtin, "1234567890123")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/dpp/1234567890123/SN123")
    }
    
    func testVerifyDPP() async throws {
        // Given
        let expectedResult = DPPVerificationResult(valid: true, details: ["All checks passed"])
        mockAPIClient.mockResponse = expectedResult
        
        // When
        let result = try await dppModule.verifyDPP(gtin: "1234567890123", serial: "SN123")
        
        // Then
        XCTAssertTrue(result.valid)
        XCTAssertEqual(result.details, ["All checks passed"])
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.POST)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/dpp/1234567890123/SN123/verify")
    }
}

