import Foundation

public class ResolveModule {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - Resolve Operations
    
    public func resolve(url: String) async throws -> ResolvedProduct {
        let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
        let endpoint = "/v1/resolve?url=\(encodedUrl)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: ResolvedProduct.self
        )
    }
    
    public func resolveDigitalLink(url: String) async throws -> ProductIDs {
        // First try to parse locally using the existing parser
        do {
            return try DigitalLinkParser.parse(url)
        } catch {
            // If local parsing fails, use the API
            let resolved = try await resolve(url: url)
            return resolved.productIds
        }
    }
    
    public func resolveWithOptions(url: String, includeProduct: Bool = true, includeDpp: Bool = false, includeCirpass: Bool = false) async throws -> ResolvedProduct {
        let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
        var queryItems = ["url=\(encodedUrl)"]
        
        if includeProduct {
            queryItems.append("includeProduct=true")
        }
        if includeDpp {
            queryItems.append("includeDpp=true")
        }
        if includeCirpass {
            queryItems.append("includeCirpass=true")
        }
        
        let queryString = queryItems.joined(separator: "&")
        let endpoint = "/v1/resolve?\(queryString)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: ResolvedProduct.self
        )
    }
    
    public func resolveProductLinks(gtin: String, serial: String? = nil, linkType: String? = nil) async throws -> ResolveResponse {
        var queryItems = ["gtin=\(gtin)"]
        
        if let serial = serial {
            queryItems.append("serial=\(serial)")
        }
        if let linkType = linkType {
            queryItems.append("linkType=\(linkType)")
        }
        
        let queryString = queryItems.joined(separator: "&")
        let endpoint = "/v1/resolve?\(queryString)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: ResolveResponse.self
        )
    }
}