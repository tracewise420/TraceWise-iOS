import Foundation

public class BulkModule {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    public func bulkCreateProducts(products: [Product]) async throws -> BulkResponse {
        let requestBody = BulkProductsRequest(items: products)
        let data = try JSONEncoder().encode(requestBody)
        
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/bulk/products",
            body: data,
            responseType: BulkResponse.self
        )
    }
    
    public func bulkCreateEvents(events: [LifecycleEvent]) async throws -> BulkResponse {
        let requestBody = BulkEventsRequest(items: events)
        let data = try JSONEncoder().encode(requestBody)
        
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/bulk/events",
            body: data,
            responseType: BulkResponse.self
        )
    }
    
    public func bulkUpdateProducts(updates: [ProductUpdate]) async throws -> BulkResponse {
        let requestBody = ["items": updates]
        let data = try JSONSerialization.data(withJSONObject: requestBody)
        
        return try await apiClient.request(
            method: .PUT,
            endpoint: "/v1/bulk/products",
            body: data,
            responseType: BulkResponse.self
        )
    }
    
    public func bulkDeleteProducts(ids: [String]) async throws -> BulkResponse {
        let requestBody = BulkDeleteRequest(ids: ids)
        let data = try JSONEncoder().encode(requestBody)
        
        return try await apiClient.request(
            method: .DELETE,
            endpoint: "/v1/bulk/products",
            body: data,
            responseType: BulkResponse.self
        )
    }
    
    public func bulkDeleteEvents(ids: [String]) async throws -> BulkResponse {
        let requestBody = BulkDeleteRequest(ids: ids)
        let data = try JSONEncoder().encode(requestBody)
        
        return try await apiClient.request(
            method: .DELETE,
            endpoint: "/v1/bulk/events",
            body: data,
            responseType: BulkResponse.self
        )
    }
}