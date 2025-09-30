import Foundation

public class ProductsModule {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - Core Product Operations
    
    public func getProduct(gtin: String, serial: String? = nil) async throws -> Product {
        var endpoint = "/v1/products?gtin=\(gtin)"
        if let serial = serial {
            endpoint += "&serial=\(serial)"
        }
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: Product.self
        )
    }
    
    public func registerProduct(userId: String, product: Product) async throws {
        let requestBody = RegisterProductRequest(gtin: product.gtin, serial: product.serial, userId: userId)
        let data = try JSONEncoder().encode(requestBody)
        
        let _: RegisterResponse = try await apiClient.request(
            method: .POST,
            endpoint: "/v1/products/register",
            body: data,
            responseType: RegisterResponse.self
        )
    }
    
    // MARK: - Extended Product Operations
    
    public func listProducts(pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Product> {
        var queryItems: [String] = []
        
        if let pageSize = pageSize {
            queryItems.append("pageSize=\(pageSize)")
        }
        if let pageToken = pageToken {
            queryItems.append("pageToken=\(pageToken)")
        }
        
        let queryString = queryItems.isEmpty ? "" : "?" + queryItems.joined(separator: "&")
        let endpoint = "/v1/products/list\(queryString)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<Product>.self
        )
    }
    
    public func createProduct(product: Product) async throws -> CreateResponse {
        let data = try JSONEncoder().encode(product)
        
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/products",
            body: data,
            responseType: CreateResponse.self
        )
    }
    
    public func getProductById(id: String) async throws -> Product {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/products/\(id)",
            body: nil,
            responseType: Product.self
        )
    }
    
    public func updateProduct(id: String, updates: [String: Any]) async throws -> Product {
        let data = try JSONSerialization.data(withJSONObject: updates)
        
        return try await apiClient.request(
            method: .PUT,
            endpoint: "/v1/products/\(id)",
            body: data,
            responseType: Product.self
        )
    }
    
    public func deleteProduct(id: String) async throws {
        let _: EmptyResponse = try await apiClient.request(
            method: .DELETE,
            endpoint: "/v1/products/\(id)",
            body: nil,
            responseType: EmptyResponse.self
        )
    }
    
    public func getUserProducts(userId: String, pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Product> {
        var queryItems: [String] = []
        
        if let pageSize = pageSize {
            queryItems.append("pageSize=\(pageSize)")
        }
        if let pageToken = pageToken {
            queryItems.append("pageToken=\(pageToken)")
        }
        
        let queryString = queryItems.isEmpty ? "" : "?" + queryItems.joined(separator: "&")
        let endpoint = "/v1/products/users/\(userId)\(queryString)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<Product>.self
        )
    }
}

