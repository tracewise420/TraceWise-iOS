import XCTest
@testable import TraceWiseSDK

final class ResolveModuleTests: XCTestCase {
    var mockAPIClient: SharedMockAPIClient!
    var resolveModule: ResolveModule!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = SharedMockAPIClient()
        resolveModule = ResolveModule(apiClient: mockAPIClient)
    }
    
    override func tearDown() {
        mockAPIClient = nil
        resolveModule = nil
        super.tearDown()
    }
    
    func testResolve() async throws {
        // Given
        let expectedResult = ResolvedProduct(
            url: "https://id.gs1.org/01/09506000134352/21/SN12345",
            resolvedUrl: "https://api.tracewise.io/resolve/123",
            productIds: ProductIDs(gtin: "09506000134352", serial: "SN12345"),
            product: Product(gtin: "09506000134352", serial: "SN12345", name: "Test Product"),
            dpp: nil,
            cirpassProduct: nil,
            resolvedAt: "2025-01-27T10:00:00Z",
            source: "gs1"
        )
        
        mockAPIClient.mockResponse = expectedResult
        
        // When
        let result = try await resolveModule.resolve(url: "https://id.gs1.org/01/09506000134352/21/SN12345")
        
        // Then
        XCTAssertEqual(result.url, "https://id.gs1.org/01/09506000134352/21/SN12345")
        XCTAssertEqual(result.productIds.gtin, "09506000134352")
        XCTAssertEqual(result.productIds.serial, "SN12345")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("/v1/resolve") == true)
    }
    
    func testResolveDigitalLink() async throws {
        // Given - Test local parsing first
        let validUrl = "https://id.gs1.org/01/09506000134352/21/SN12345"
        
        // When
        let result = try await resolveModule.resolveDigitalLink(url: validUrl)
        
        // Then - Should use local parser, not API
        XCTAssertEqual(result.gtin, "09506000134352")
        XCTAssertEqual(result.serial, "SN12345")
        XCTAssertNil(mockAPIClient.lastMethod) // Should not call API for valid URLs
    }
    
    func testResolveDigitalLinkFallbackToAPI() async throws {
        // Given - Invalid URL that will fail local parsing
        let invalidUrl = "https://example.com/invalid"
        
        let expectedResult = ResolvedProduct(
            url: invalidUrl,
            resolvedUrl: nil,
            productIds: ProductIDs(gtin: "1234567890123", serial: "ABC123"),
            product: nil,
            dpp: nil,
            cirpassProduct: nil,
            resolvedAt: "2025-01-27T10:00:00Z",
            source: "api"
        )
        
        mockAPIClient.mockResponse = expectedResult
        
        // When
        let result = try await resolveModule.resolveDigitalLink(url: invalidUrl)
        
        // Then - Should fallback to API
        XCTAssertEqual(result.gtin, "1234567890123")
        XCTAssertEqual(result.serial, "ABC123")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
    }
    
    func testResolveWithOptions() async throws {
        // Given
        let expectedResult = ResolvedProduct(
            url: "https://id.gs1.org/01/09506000134352/21/SN12345",
            resolvedUrl: nil,
            productIds: ProductIDs(gtin: "09506000134352", serial: "SN12345"),
            product: Product(gtin: "09506000134352", serial: "SN12345", name: "Test Product"),
            dpp: DPP(
                id: "dpp_123",
                gtin: "09506000134352",
                serial: "SN12345",
                claims: [:],
                links: [:],
                signatures: [],
                source: "test",
                fetchedAt: "2025-01-27T10:00:00Z",
                rawHash: "hash123",
                createdAt: "2025-01-27T10:00:00Z",
                updatedAt: "2025-01-27T10:00:00Z"
            ),
            cirpassProduct: nil,
            resolvedAt: "2025-01-27T10:00:00Z",
            source: "api"
        )
        
        mockAPIClient.mockResponse = expectedResult
        
        // When
        let result = try await resolveModule.resolveWithOptions(
            url: "https://id.gs1.org/01/09506000134352/21/SN12345",
            includeProduct: true,
            includeDpp: true,
            includeCirpass: false
        )
        
        // Then
        XCTAssertEqual(result.productIds.gtin, "09506000134352")
        XCTAssertNotNil(result.product)
        XCTAssertNotNil(result.dpp)
        XCTAssertNil(result.cirpassProduct)
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("includeProduct=true") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("includeDpp=true") == true)
    }
    
    func testResolveProductLinks() async throws {
        // Given
        let expectedResponse = ResolveResponse(
            gtin: "1234567890123",
            serial: "SN123",
            links: [
                "dppUrl": "https://example.com/dpp/1234567890123/SN123",
                "productUrl": "https://example.com/product/1234567890123",
                "repairUrl": "https://example.com/repair/1234567890123"
            ],
            resolvedAt: "2025-01-27T10:00:00Z"
        )
        
        mockAPIClient.mockResponse = expectedResponse
        
        // When
        let result = try await resolveModule.resolveProductLinks(
            gtin: "1234567890123",
            serial: "SN123",
            linkType: "dppUrl"
        )
        
        // Then
        XCTAssertEqual(result.gtin, "1234567890123")
        XCTAssertEqual(result.serial, "SN123")
        XCTAssertEqual(result.links["dppUrl"], "https://example.com/dpp/1234567890123/SN123")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("/v1/resolve") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("gtin=1234567890123") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("serial=SN123") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("linkType=dppUrl") == true)
    }
    
    func testResolveProductLinksWithoutOptionalParams() async throws {
        // Given
        let expectedResponse = ResolveResponse(
            gtin: "1234567890123",
            serial: nil,
            links: [
                "productUrl": "https://example.com/product/1234567890123"
            ],
            resolvedAt: "2025-01-27T10:00:00Z"
        )
        
        mockAPIClient.mockResponse = expectedResponse
        
        // When
        let result = try await resolveModule.resolveProductLinks(gtin: "1234567890123")
        
        // Then
        XCTAssertEqual(result.gtin, "1234567890123")
        XCTAssertNil(result.serial)
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("gtin=1234567890123") == true)
        XCTAssertFalse(mockAPIClient.lastEndpoint?.contains("serial=") == true)
        XCTAssertFalse(mockAPIClient.lastEndpoint?.contains("linkType=") == true)
    }
}