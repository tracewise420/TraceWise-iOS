import XCTest
@testable import TraceWiseSDK

final class SearchModuleTests: XCTestCase {
    var mockAPIClient: SharedMockAPIClient!
    var searchModule: SearchModule!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = SharedMockAPIClient()
        searchModule = SearchModule(apiClient: mockAPIClient)
    }
    
    override func tearDown() {
        mockAPIClient = nil
        searchModule = nil
        super.tearDown()
    }
    
    func testSearch() async throws {
        // Given
        let expectedResults = [
            SearchResult(
                id: "result_1",
                type: "product",
                gtin: "1234567890123",
                serial: "SN123",
                name: "Test Product",
                description: "A test product",
                score: 0.95,
                metadata: nil
            )
        ]
        
        mockAPIClient.mockResponse = expectedResults
        
        // When
        let results = try await searchModule.search(query: "test", filters: nil, limit: 10)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Test Product")
        XCTAssertEqual(results[0].gtin, "1234567890123")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("/v1/search") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("query=test") == true)
    }
    
    func testSearchProducts() async throws {
        // Given
        let expectedResults = [
            SearchResult(
                id: "result_1",
                type: "product",
                gtin: "1234567890123",
                serial: "SN123",
                name: "Test Product",
                description: "A test product",
                score: 0.95,
                metadata: nil
            )
        ]
        
        mockAPIClient.mockResponse = expectedResults
        
        let filters = ProductFilters(category: "electronics", manufacturer: "TestCorp", minScore: 0.8, maxResults: 5)
        
        // When
        let products = try await searchModule.searchProducts(query: "test", filters: filters)
        
        // Then
        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products[0].name, "Test Product")
        XCTAssertEqual(products[0].gtin, "1234567890123")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
    }
    
    func testSearchWithFilters() async throws {
        // Given
        let expectedResults: [SearchResult] = []
        mockAPIClient.mockResponse = expectedResults
        
        let filters: [String: AnyCodable] = [
            "category": AnyCodable("electronics"),
            "manufacturer": AnyCodable("TestCorp")
        ]
        
        // When
        let results = try await searchModule.search(query: "test", filters: filters, limit: 20)
        
        // Then
        XCTAssertEqual(results.count, 0)
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("category=electronics") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("manufacturer=TestCorp") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("limit=20") == true)
    }
    
    func testSearchEvents() async throws {
        // Given
        let expectedEvents = [
            LifecycleEvent(
                gtin: "1234567890123",
                serial: "SN123",
                type: "ObjectEvent",
                action: "OBSERVE",
                bizStep: "shipping",
                disposition: "in_transit",
                timestamp: "2025-01-27T10:00:00Z",
                readPoint: "urn:epc:id:sgln:0614141.00777.0",
                bizLocation: "urn:epc:id:sgln:0614141.00888.0",
                details: nil
            )
        ]
        
        let expectedResponse = PaginatedResponse(
            items: expectedEvents,
            nextPageToken: nil,
            totalCount: 1
        )
        
        mockAPIClient.mockResponse = expectedResponse
        
        // When
        let result = try await searchModule.searchEvents(
            type: "ObjectEvent",
            bizStep: "shipping",
            readPoint: "urn:epc:id:sgln:0614141.00777.0",
            whenFrom: "2025-01-01T00:00:00Z",
            whenTo: "2025-12-31T23:59:59Z",
            pageSize: 20,
            pageToken: nil
        )
        
        // Then
        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(result.items[0].gtin, "1234567890123")
        XCTAssertEqual(result.items[0].bizStep, "shipping")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("/v1/search/events") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("type=ObjectEvent") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("bizStep=shipping") == true)
    }
}