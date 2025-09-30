import Foundation
import TraceWiseSDK

/**
 * TraceWise iOS SDK Usage Examples
 * 
 * Demonstrates complete SDK functionality:
 * - DPP Module, Search Module, Resolve Module
 * - Enhanced Products and CIRPASS modules
 */

class SDKUsageExample {
    private let sdk: TraceWiseSDK
    
    init() {
        let config = SDKConfig(
            baseURL: "https://api.tracewise.io",
            apiKey: "your-api-key",
            enableLogging: true
        )
        self.sdk = TraceWiseSDK(config: config)
    }
    
    // MARK: - DPP Operations
    
    func dppOperations() async throws {
        // Create DPP
        let dppData = DPPCreateRequest(
            gtin: "1234567890123",
            serial: "SN12345",
            claims: ["name": AnyCodable("EcoSmart Kettle")],
            links: ["website": "https://example.com"],
            source: "manufacturer"
        )
        let dpp = try await sdk.createDPP(dppData: dppData)
        
        // Get DPP
        let retrievedDPP = try await sdk.getDPP(gtin: "1234567890123", serial: "SN12345")
        
        // Verify DPP
        let verification = try await sdk.verifyDPP(gtin: "1234567890123", serial: "SN12345")
    }
    
    // MARK: - Search Operations
    
    func searchOperations() async throws {
        // Basic search
        let results = try await sdk.search(query: "kettle", limit: 10)
        
        // Product search with filters
        let filters = ProductFilters(category: "appliances", manufacturer: "GreenTech")
        let products = try await sdk.searchProducts(query: "eco kettle", filters: filters)
    }
    
    // MARK: - Resolve Operations
    
    func resolveOperations() async throws {
        let url = "https://id.gs1.org/01/09506000134352/21/SN12345"
        
        // Resolve URL
        let resolved = try await sdk.resolve(url: url)
        
        // Parse digital link
        let productIds = try await sdk.resolveDigitalLink(url: url)
    }
    
    // MARK: - Products Operations
    
    func productsOperations() async throws {
        // List products
        let productsList = try await sdk.listProducts(pageSize: 20)
        
        // Create product
        let product = Product(gtin: "1234567890999", name: "Test Product")
        let created = try await sdk.createProduct(product: product)
        
        // Get user products
        let userProducts = try await sdk.getUserProducts(userId: "user_123")
    }
    
    // MARK: - Modular Access
    
    func modularAccess() async throws {
        // Use modules directly
        let product = try await sdk.products.getProduct(gtin: "1234567890123")
        let dpp = try await sdk.dpp.getDPP(gtin: "1234567890123")
        let results = try await sdk.search.search(query: "test")
        let resolved = try await sdk.resolve.resolve(url: "https://example.com")
        let cirpass = try await sdk.cirpass.getCirpassProduct(id: "cirpass:123")
    }
}