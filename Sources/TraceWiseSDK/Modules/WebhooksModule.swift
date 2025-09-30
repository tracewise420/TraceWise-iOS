import Foundation

public class WebhooksModule {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    public func registerWebhook(_ webhook: Webhook) async throws -> CreateResponse {
        let data = try JSONEncoder().encode(webhook)
        
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/webhooks",
            body: data,
            responseType: CreateResponse.self
        )
    }
    
    public func updateWebhook(id: String, webhook: Webhook) async throws -> Webhook {
        let data = try JSONEncoder().encode(webhook)
        
        return try await apiClient.request(
            method: .PUT,
            endpoint: "/v1/webhooks/\(id)",
            body: data,
            responseType: Webhook.self
        )
    }
    
    public func deleteWebhook(id: String) async throws {
        _ = try await apiClient.request(
            method: .DELETE,
            endpoint: "/v1/webhooks/\(id)",
            body: nil,
            responseType: EmptyResponse.self
        )
    }
    
    public func listWebhooks() async throws -> [Webhook] {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/webhooks",
            body: nil,
            responseType: [Webhook].self
        )
    }
    
    public func getWebhook(id: String) async throws -> Webhook {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/webhooks/\(id)",
            body: nil,
            responseType: Webhook.self
        )
    }
    
    public func testWebhook(id: String) async throws -> WebhookTestResult {
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/webhooks/\(id)/test",
            body: nil,
            responseType: WebhookTestResult.self
        )
    }
    
    public func getWebhookDeliveries(webhookId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [WebhookDelivery] {
        var queryItems: [String] = []
        if let limit = limit { queryItems.append("limit=\(limit)") }
        if let offset = offset { queryItems.append("offset=\(offset)") }
        
        let query = queryItems.isEmpty ? "" : "?" + queryItems.joined(separator: "&")
        let endpoint = "/v1/webhooks/\(webhookId)/deliveries\(query)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: [WebhookDelivery].self
        )
    }
    
    public func retryWebhookDelivery(webhookId: String, deliveryId: String) async throws {
        _ = try await apiClient.request(
            method: .POST,
            endpoint: "/v1/webhooks/\(webhookId)/deliveries/\(deliveryId)/retry",
            body: nil,
            responseType: EmptyResponse.self
        )
    }
}