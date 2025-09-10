import Foundation

public class TraceWiseSDK {
    private let apiClient: APIClient
    private let subscriptionStorage = SubscriptionStorage()
    
    public init(config: SDKConfig) {
        self.apiClient = APIClient(config: config)
    }
    
    public func parseDigitalLink(_ url: String) throws -> ProductIDs {
        return try DigitalLinkParser.parse(url)
    }
    
    // MARK: - Exact Trello Task Signatures
    
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
    
    public func addLifecycleEvent(event: LifecycleEvent) async throws {
        let data = try JSONEncoder().encode(event)
        
        let _: EventResponse = try await apiClient.request(
            method: .POST,
            endpoint: "/v1/events",
            body: data,
            responseType: EventResponse.self
        )
    }
    
    public func getProductEvents(id: String, limit: Int? = nil, pageToken: String? = nil) async throws -> [LifecycleEvent] {
        // Parse composite ID (gtin:serial format)
        let components = id.components(separatedBy: ":")
        guard let gtin = components.first else {
            throw TraceWiseError.invalidDigitalLink("Invalid product ID format")
        }
        let serial = components.count > 1 ? components[1] : ""
        
        var endpoint = "/v1/events/\(gtin)/\(serial)"
        var queryItems: [String] = []
        
        if let limit = limit {
            queryItems.append("pageSize=\(limit)")
        }
        if let pageToken = pageToken {
            queryItems.append("pageToken=\(pageToken)")
        }
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        let response: PaginatedResponse<LifecycleEvent> = try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<LifecycleEvent>.self
        )
        
        return response.items
    }
    
    public func getCirpassProduct(id: String) async throws -> CirpassProduct {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/cirpass-sim/product/\(id)",
            body: nil,
            responseType: CirpassProduct.self
        )
    }
    
    // MARK: - Additional Methods
    
    public func getSubscriptionInfo() async throws -> SubscriptionInfo {
        let subscriptionInfo: SubscriptionInfo = try await apiClient.request(
            method: .GET,
            endpoint: "/v1/auth/me",
            body: nil,
            responseType: SubscriptionInfo.self
        )
        
        subscriptionStorage.save(subscriptionInfo)
        return subscriptionInfo
    }
    
    public func healthCheck() async throws -> HealthResponse {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/health",
            body: nil,
            responseType: HealthResponse.self
        )
    }
}

// Supporting types
struct RegisterProductRequest: Codable {
    let gtin: String
    let serial: String?
    let userId: String?
}

struct RegisterResponse: Codable {
    let status: String
}