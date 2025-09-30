import Foundation

public class WarrantyModule {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    public func getWarrantyStatus(gtin: String, serial: String? = nil) async throws -> WarrantyStatus {
        let endpoint = serial != nil ? "/v1/warranty/\(gtin)/\(serial!)" : "/v1/warranty/\(gtin)"
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: WarrantyStatus.self
        )
    }
}