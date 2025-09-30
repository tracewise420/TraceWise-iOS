import Foundation

public class CirpassModule {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - CIRPASS Operations
    
    public func getCirpassProduct(id: String) async throws -> CirpassProduct {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/cirpass-sim/product/\(id)",
            body: nil,
            responseType: CirpassProduct.self
        )
    }
    
    public func seedCirpassProducts(products: [CirpassProduct]) async throws {
        let requestBody = ["products": products]
        let data = try JSONEncoder().encode(requestBody)
        
        let _: EmptyResponse = try await apiClient.request(
            method: .POST,
            endpoint: "/v1/cirpass-sim/seed",
            body: data,
            responseType: EmptyResponse.self
        )
    }
    
    public func listCirpassProducts(limit: Int? = nil) async throws -> CirpassProductsResponse {
        var endpoint = "/v1/cirpass-sim/products"
        
        if let limit = limit {
            endpoint += "?limit=\(limit)"
        }
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: CirpassProductsResponse.self
        )
    }
}

// MARK: - CIRPASS Response Models

public struct CirpassProductsResponse: Codable {
    public let products: [CirpassProduct]
    
    public init(products: [CirpassProduct]) {
        self.products = products
    }
}

