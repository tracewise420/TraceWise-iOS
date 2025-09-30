import Foundation

public class RepairModule {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    public func createRepairOrder(order: RepairOrder) async throws -> CreateResponse {
        let data = try JSONEncoder().encode(order)
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/repair-orders",
            body: data,
            responseType: CreateResponse.self
        )
    }
    
    public func getRepairOrder(id: String) async throws -> RepairOrder {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/repair-orders/\(id)",
            body: nil,
            responseType: RepairOrder.self
        )
    }
}