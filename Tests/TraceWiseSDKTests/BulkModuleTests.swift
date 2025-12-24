import XCTest
@testable import TraceWiseSDK

final class BulkModuleTests: XCTestCase {
    var mockAPIClient: MockAPIClient!
    var bulkModule: BulkModule!
    
    override func setUp() {
        super.setUp()
        let config = SDKConfig(baseURL: "https://test.com", apiKey: "test")
        let authProvider = AuthProvider(config: config)
        mockAPIClient = MockAPIClient(config: config, authProvider: authProvider)
        bulkModule = BulkModule(apiClient: mockAPIClient)
    }
    
    func testBulkCreateProducts() async throws {
        // Given
        let products = [
            Product(gtin: "123", serial: "SN1", name: "Test Product 1"),
            Product(gtin: "456", serial: "SN2", name: "Test Product 2")
        ]
        let expectedResponse = BulkResponse(success: true, processed: 2, failed: 0, errors: nil)
        mockAPIClient.mockResponse = expectedResponse
        
        // When
        let result = try await bulkModule.bulkCreateProducts(products: products)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.processed, 2)
        XCTAssertEqual(result.failed, 0)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/bulk/products")
        XCTAssertEqual(mockAPIClient.lastMethod, .POST)
    }
    
    func testBulkCreateEvents() async throws {
        // Given
        let events = [
            LifecycleEvent(gtin: "123", serial: "SN1", type: "ObjectEvent", bizStep: "shipping", timestamp: "2025-01-27T10:00:00Z"),
            LifecycleEvent(gtin: "456", serial: "SN2", type: "ObjectEvent", bizStep: "receiving", timestamp: "2025-01-27T11:00:00Z")
        ]
        let expectedResponse = BulkResponse(success: true, processed: 2, failed: 0, errors: nil)
        mockAPIClient.mockResponse = expectedResponse
        
        // When
        let result = try await bulkModule.bulkCreateEvents(events: events)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.processed, 2)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/bulk/events")
        XCTAssertEqual(mockAPIClient.lastMethod, .POST)
    }
    
    func testBulkDeleteProducts() async throws {
        // Given
        let ids = ["id1", "id2", "id3"]
        let expectedResponse = BulkResponse(success: true, processed: 3, failed: 0, errors: nil)
        mockAPIClient.mockResponse = expectedResponse
        
        // When
        let result = try await bulkModule.bulkDeleteProducts(ids: ids)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.processed, 3)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/bulk/products")
        XCTAssertEqual(mockAPIClient.lastMethod, .DELETE)
    }
}