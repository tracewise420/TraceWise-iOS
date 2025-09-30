import Foundation

public class PartnersModule {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    public func createPartner(partner: Partner) async throws -> CreateResponse {
        let data = try JSONEncoder().encode(partner)
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/partners",
            body: data,
            responseType: CreateResponse.self
        )
    }
    
    public func getPartner(id: String) async throws -> Partner {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/partners/\(id)",
            body: nil,
            responseType: Partner.self
        )
    }
    
    public func listPartners(pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Partner> {
        var queryItems: [String] = []
        if let pageSize = pageSize { queryItems.append("pageSize=\(pageSize)") }
        if let pageToken = pageToken { queryItems.append("pageToken=\(pageToken)") }
        
        let query = queryItems.isEmpty ? "" : "?" + queryItems.joined(separator: "&")
        let endpoint = "/v1/partners\(query)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<Partner>.self
        )
    }
    
    public func updatePartner(id: String, updates: [String: Any]) async throws -> Partner {
        let data = try JSONSerialization.data(withJSONObject: updates)
        return try await apiClient.request(
            method: .PUT,
            endpoint: "/v1/partners/\(id)",
            body: data,
            responseType: Partner.self
        )
    }
    
    public func deletePartner(id: String) async throws {
        let _: EmptyResponse = try await apiClient.request(
            method: .DELETE,
            endpoint: "/v1/partners/\(id)",
            body: nil,
            responseType: EmptyResponse.self
        )
    }
}