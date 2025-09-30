import Foundation

public class AuditModule {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    public func getAuditLogs(
        entityType: String? = nil,
        entityId: String? = nil,
        action: String? = nil,
        fromDate: String? = nil,
        toDate: String? = nil,
        limit: Int? = nil
    ) async throws -> [AuditLog] {
        var queryItems: [String] = []
        
        if let entityType = entityType { queryItems.append("entityType=\(entityType)") }
        if let entityId = entityId { queryItems.append("entityId=\(entityId)") }
        if let action = action { queryItems.append("action=\(action)") }
        if let fromDate = fromDate { queryItems.append("fromDate=\(fromDate)") }
        if let toDate = toDate { queryItems.append("toDate=\(toDate)") }
        if let limit = limit { queryItems.append("limit=\(limit)") }
        
        let query = queryItems.isEmpty ? "" : "?" + queryItems.joined(separator: "&")
        let endpoint = "/v1/audit\(query)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: [AuditLog].self
        )
    }
}