import Foundation

public class TenantsModule {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    public func createTenant(_ tenant: Tenant) async throws -> CreateResponse {
        let data = try JSONEncoder().encode(tenant)
        
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/tenants",
            body: data,
            responseType: CreateResponse.self
        )
    }
    
    public func getTenant(id: String) async throws -> Tenant {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/tenants/\(id)",
            body: nil,
            responseType: Tenant.self
        )
    }
    
    public func updateTenant(id: String, tenant: Tenant) async throws -> Tenant {
        let data = try JSONEncoder().encode(tenant)
        
        return try await apiClient.request(
            method: .PUT,
            endpoint: "/v1/tenants/\(id)",
            body: data,
            responseType: Tenant.self
        )
    }
    
    public func deleteTenant(id: String) async throws {
        _ = try await apiClient.request(
            method: .DELETE,
            endpoint: "/v1/tenants/\(id)",
            body: nil,
            responseType: EmptyResponse.self
        )
    }
    
    public func listTenants(pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Tenant> {
        var queryItems: [String] = []
        if let pageSize = pageSize { queryItems.append("pageSize=\(pageSize)") }
        if let pageToken = pageToken { queryItems.append("pageToken=\(pageToken)") }
        
        let query = queryItems.isEmpty ? "" : "?" + queryItems.joined(separator: "&")
        let endpoint = "/v1/tenants\(query)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<Tenant>.self
        )
    }
    
    public func updateTenantSettings(tenantId: String, settings: TenantSettings) async throws -> TenantSettings {
        let data = try JSONEncoder().encode(settings)
        
        return try await apiClient.request(
            method: .PUT,
            endpoint: "/v1/tenants/\(tenantId)/settings",
            body: data,
            responseType: TenantSettings.self
        )
    }
    
    // MARK: - User Management
    
    public func addUserToTenant(tenantId: String, user: TenantUser) async throws -> CreateResponse {
        let data = try JSONEncoder().encode(user)
        
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/tenants/\(tenantId)/users",
            body: data,
            responseType: CreateResponse.self
        )
    }
    
    public func removeUserFromTenant(tenantId: String, userId: String) async throws {
        _ = try await apiClient.request(
            method: .DELETE,
            endpoint: "/v1/tenants/\(tenantId)/users/\(userId)",
            body: nil,
            responseType: EmptyResponse.self
        )
    }
    
    public func updateUserRole(tenantId: String, userId: String, role: TenantUserRole, permissions: [String]? = nil) async throws -> TenantUser {
        let requestBody = [
            "role": role.rawValue,
            "permissions": permissions ?? []
        ] as [String: Any]
        let data = try JSONSerialization.data(withJSONObject: requestBody)
        
        return try await apiClient.request(
            method: .PUT,
            endpoint: "/v1/tenants/\(tenantId)/users/\(userId)",
            body: data,
            responseType: TenantUser.self
        )
    }
    
    public func listTenantUsers(tenantId: String, pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<TenantUser> {
        var queryItems: [String] = []
        if let pageSize = pageSize { queryItems.append("pageSize=\(pageSize)") }
        if let pageToken = pageToken { queryItems.append("pageToken=\(pageToken)") }
        
        let query = queryItems.isEmpty ? "" : "?" + queryItems.joined(separator: "&")
        let endpoint = "/v1/tenants/\(tenantId)/users\(query)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<TenantUser>.self
        )
    }
    
    // MARK: - Invitations
    
    public func inviteUser(tenantId: String, invitation: TenantInvitation) async throws -> CreateResponse {
        let data = try JSONEncoder().encode(invitation)
        
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/tenants/\(tenantId)/invitations",
            body: data,
            responseType: CreateResponse.self
        )
    }
    
    public func revokeInvitation(tenantId: String, invitationId: String) async throws {
        _ = try await apiClient.request(
            method: .DELETE,
            endpoint: "/v1/tenants/\(tenantId)/invitations/\(invitationId)",
            body: nil,
            responseType: EmptyResponse.self
        )
    }
    
    public func listInvitations(tenantId: String) async throws -> [TenantInvitation] {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/tenants/\(tenantId)/invitations",
            body: nil,
            responseType: [TenantInvitation].self
        )
    }
    
    public func acceptInvitation(invitationId: String) async throws {
        _ = try await apiClient.request(
            method: .POST,
            endpoint: "/v1/invitations/\(invitationId)/accept",
            body: nil,
            responseType: EmptyResponse.self
        )
    }
}