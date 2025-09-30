import Foundation

public class SearchModule {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - Search Operations
    
    public func search(query: String, filters: [String: AnyCodable]? = nil, limit: Int? = nil) async throws -> [SearchResult] {
        var queryItems: [String] = ["query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"]
        
        if let limit = limit {
            queryItems.append("limit=\(limit)")
        }
        
        if let filters = filters {
            for (key, value) in filters {
                if let stringValue = value.value as? String {
                    queryItems.append("\(key)=\(stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? stringValue)")
                }
            }
        }
        
        let queryString = queryItems.joined(separator: "&")
        let endpoint = "/v1/search?\(queryString)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: [SearchResult].self
        )
    }
    
    public func searchProducts(query: String, filters: ProductFilters? = nil) async throws -> [Product] {
        var searchFilters: [String: AnyCodable] = [:]
        
        if let filters = filters {
            if let category = filters.category {
                searchFilters["category"] = AnyCodable(category)
            }
            if let manufacturer = filters.manufacturer {
                searchFilters["manufacturer"] = AnyCodable(manufacturer)
            }
            if let minScore = filters.minScore {
                searchFilters["minScore"] = AnyCodable(minScore)
            }
        }
        
        let limit = filters?.maxResults
        let results = try await search(query: query, filters: searchFilters, limit: limit)
        
        // Convert search results to products
        return results.compactMap { result in
            guard let gtin = result.gtin else { return nil }
            return Product(
                gtin: gtin,
                serial: result.serial,
                name: result.name,
                description: result.description
            )
        }
    }
    
    public func searchEvents(
        type: String? = nil,
        bizStep: String? = nil,
        readPoint: String? = nil,
        whenFrom: String? = nil,
        whenTo: String? = nil,
        pageSize: Int? = nil,
        pageToken: String? = nil
    ) async throws -> PaginatedResponse<LifecycleEvent> {
        var queryItems: [String] = []
        
        if let type = type { queryItems.append("type=\(type)") }
        if let bizStep = bizStep { queryItems.append("bizStep=\(bizStep)") }
        if let readPoint = readPoint { queryItems.append("readPoint=\(readPoint)") }
        if let whenFrom = whenFrom { queryItems.append("when.from=\(whenFrom)") }
        if let whenTo = whenTo { queryItems.append("when.to=\(whenTo)") }
        if let pageSize = pageSize { queryItems.append("pageSize=\(pageSize)") }
        if let pageToken = pageToken { queryItems.append("pageToken=\(pageToken)") }
        
        let query = queryItems.isEmpty ? "" : "?" + queryItems.joined(separator: "&")
        let endpoint = "/v1/search/events\(query)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<LifecycleEvent>.self
        )
    }
}