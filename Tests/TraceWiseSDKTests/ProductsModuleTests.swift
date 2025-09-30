import XCTest
@testable import TraceWiseSDK

final class ProductsModuleTests: XCTestCase {
    var mockAPIClient: SharedMockAPIClient!
    var productsModule: ProductsModule!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = SharedMockAPIClient()
        productsModule = ProductsModule(apiClient: mockAPIClient)
    }
    
    override func tearDown() {
        mockAPIClient = nil
        productsModule = nil
        super.tearDown()
    }
    
    func testListProducts() async throws {
        // Given
        let expectedResponse = PaginatedResponse(
            items: [
                Product(gtin: "1234567890123", serial: "SN123", name: "Product 1"),
                Product(gtin: "1234567890124", serial: "SN124", name: "Product 2")
            ],
            nextPageToken: "token123",
            totalCount: 100
        )
        
        mockAPIClient.mockResponse = expectedResponse
        
        // When
        let result = try await productsModule.listProducts(pageSize: 10, pageToken: "prev_token")
        
        // Then
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.nextPageToken, "token123")
        XCTAssertEqual(result.totalCount, 100)
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("/v1/products/list") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("pageSize=10") == true)
        XCTAssertTrue(mockAPIClient.lastEndpoint?.contains("pageToken=prev_token") == true)
    }
    
    func testCreateProduct() async throws {
        // Given
        let product = Product(gtin: "1234567890123", serial: "SN123", name: "New Product")
        let expectedResponse = CreateResponse(id: "prod_123", status: "created")
        
        mockAPIClient.mockResponse = expectedResponse
        
        // When
        let result = try await productsModule.createProduct(product: product)
        
        // Then
        XCTAssertEqual(result.id, "prod_123")
        XCTAssertEqual(result.status, "created")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.POST)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/products")
    }
    
    func testGetProductById() async throws {
        // Given
        let expectedProduct = Product(gtin: "1234567890123", serial: "SN123", name: "Test Product")
        mockAPIClient.mockResponse = expectedProduct
        
        // When
        let result = try await productsModule.getProductById(id: "prod_123")
        
        // Then
        XCTAssertEqual(result.name, "Test Product")
        XCTAssertEqual(result.gtin, "1234567890123")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/products/prod_123")
    }
    
    func testUpdateProduct() async throws {
        // Given
        let updates = ["name": "Updated Product", "description": "Updated description"]
        let expectedProduct = Product(gtin: "1234567890123", serial: "SN123", name: "Updated Product", description: "Updated description")
        
        mockAPIClient.mockResponse = expectedProduct
        
        // When
        let result = try await productsModule.updateProduct(id: "prod_123", updates: updates)
        
        // Then
        XCTAssertEqual(result.name, "Updated Product")
        XCTAssertEqual(result.description, "Updated description")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.PUT)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/products/prod_123")
    }
    
    func testDeleteProduct() async throws {
        // Given - Use a struct that can be cast to any Codable type
        struct TestEmptyResponse: Codable {}
        mockAPIClient.mockResponse = TestEmptyResponse()
        
        // When & Then - Should not throw
        try await productsModule.deleteProduct(id: "prod_123")
        
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.DELETE)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/products/prod_123")
    }
    
    func testGetUserProducts() async throws {
        // Given
        let expectedResponse = PaginatedResponse(
            items: [
                Product(gtin: "1234567890123", serial: "SN123", name: "User Product 1"),
                Product(gtin: "1234567890124", serial: "SN124", name: "User Product 2")
            ],
            nextPageToken: nil,
            totalCount: 2
        )
        
        mockAPIClient.mockResponse = expectedResponse
        
        // When
        let result = try await productsModule.getUserProducts(userId: "user_123", pageSize: 20)
        
        // Then
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.totalCount, 2)
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/products/users/user_123?pageSize=20")
    }
    
    func testGetProduct() async throws {
        // Given
        let expectedProduct = Product(gtin: "1234567890123", serial: "SN123", name: "Test Product")
        mockAPIClient.mockResponse = expectedProduct
        
        // When
        let result = try await productsModule.getProduct(gtin: "1234567890123", serial: "SN123")
        
        // Then
        XCTAssertEqual(result.name, "Test Product")
        XCTAssertEqual(result.gtin, "1234567890123")
        XCTAssertEqual(result.serial, "SN123")
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.GET)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/products?gtin=1234567890123&serial=SN123")
    }
    
    func testRegisterProduct() async throws {
        // Given
        let product = Product(gtin: "1234567890123", serial: "SN123", name: "Test Product")
        let expectedResponse = RegisterResponse(status: "registered")
        
        mockAPIClient.mockResponse = expectedResponse
        
        // When & Then - Should not throw
        try await productsModule.registerProduct(userId: "user_123", product: product)
        
        XCTAssertEqual(mockAPIClient.lastMethod, HTTPMethod.POST)
        XCTAssertEqual(mockAPIClient.lastEndpoint, "/v1/products/register")
    }
}