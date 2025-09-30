import Foundation

public class AssetsModule {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    public func uploadAsset(data: Data, request: AssetUploadRequest) async throws -> Asset {
        // Step 1: Get upload URL
        let requestData = try JSONEncoder().encode(request)
        let uploadResponse: AssetUploadResponse = try await apiClient.request(
            method: .POST,
            endpoint: "/v1/assets/upload",
            body: requestData,
            responseType: AssetUploadResponse.self
        )
        
        // Step 2: Upload file to signed URL
        var urlRequest = URLRequest(url: URL(string: uploadResponse.uploadUrl)!)
        urlRequest.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add fields if present
        if let fields = uploadResponse.fields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(request.name)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(request.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw TraceWiseError.uploadFailed
        }
        
        // Step 3: Confirm upload
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/assets/\(uploadResponse.id)/confirm",
            body: nil,
            responseType: Asset.self
        )
    }
    
    public func getAsset(id: String) async throws -> Asset {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/assets/\(id)",
            body: nil,
            responseType: Asset.self
        )
    }
    
    public func updateAsset(id: String, asset: Asset) async throws -> Asset {
        let data = try JSONEncoder().encode(asset)
        
        return try await apiClient.request(
            method: .PUT,
            endpoint: "/v1/assets/\(id)",
            body: data,
            responseType: Asset.self
        )
    }
    
    public func deleteAsset(id: String) async throws {
        _ = try await apiClient.request(
            method: .DELETE,
            endpoint: "/v1/assets/\(id)",
            body: nil,
            responseType: EmptyResponse.self
        )
    }
    
    public func searchAssets(params: AssetSearchParams) async throws -> PaginatedResponse<Asset> {
        var queryItems: [String] = []
        
        if let type = params.type { queryItems.append("type=\(type)") }
        if let productId = params.productId { queryItems.append("productId=\(productId)") }
        if let eventId = params.eventId { queryItems.append("eventId=\(eventId)") }
        if let mimeType = params.mimeType { queryItems.append("mimeType=\(mimeType)") }
        if let pageSize = params.pageSize { queryItems.append("pageSize=\(pageSize)") }
        if let pageToken = params.pageToken { queryItems.append("pageToken=\(pageToken)") }
        if let tags = params.tags {
            for tag in tags {
                queryItems.append("tags=\(tag)")
            }
        }
        
        let query = queryItems.isEmpty ? "" : "?" + queryItems.joined(separator: "&")
        let endpoint = "/v1/assets\(query)"
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<Asset>.self
        )
    }
    
    public func getAssetsByProduct(productId: String, pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Asset> {
        let params = AssetSearchParams(productId: productId, pageSize: pageSize, pageToken: pageToken)
        return try await searchAssets(params: params)
    }
    
    public func getAssetsByEvent(eventId: String, pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Asset> {
        let params = AssetSearchParams(eventId: eventId, pageSize: pageSize, pageToken: pageToken)
        return try await searchAssets(params: params)
    }
    
    public func addTagsToAsset(id: String, tags: [String]) async throws -> Asset {
        let requestBody = ["tags": tags]
        let data = try JSONSerialization.data(withJSONObject: requestBody)
        
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/assets/\(id)/tags",
            body: data,
            responseType: Asset.self
        )
    }
    
    public func removeTagsFromAsset(id: String, tags: [String]) async throws -> Asset {
        let requestBody = ["tags": tags]
        let data = try JSONSerialization.data(withJSONObject: requestBody)
        
        return try await apiClient.request(
            method: .DELETE,
            endpoint: "/v1/assets/\(id)/tags",
            body: data,
            responseType: Asset.self
        )
    }
    
    public func getAssetDownloadUrl(id: String) async throws -> AssetDownloadResponse {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/assets/\(id)/download",
            body: nil,
            responseType: AssetDownloadResponse.self
        )
    }
}