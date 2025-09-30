import Foundation

public class DPPModule {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - DPP Operations
    
    public func createDPP(dppData: DPPCreateRequest) async throws -> DPP {
        let data = try JSONEncoder().encode(dppData)
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/dpp",
            body: data,
            responseType: DPP.self
        )
    }
    
    public func getDPP(gtin: String, serial: String? = nil) async throws -> DPP {
        let serialPath = serial ?? ""
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/dpp/\(gtin)/\(serialPath)",
            body: nil,
            responseType: DPP.self
        )
    }
    
    public func updateDPPClaims(gtin: String, serial: String? = nil, claimsUpdate: DPPClaimsUpdate) async throws -> DPP {
        let serialPath = serial ?? ""
        let data = try JSONEncoder().encode(claimsUpdate)
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/dpp/\(gtin)/\(serialPath)/claims",
            body: data,
            responseType: DPP.self
        )
    }
    
    public func verifyDPP(gtin: String, serial: String? = nil, checks: [String] = ["schema", "signature", "consistency"]) async throws -> DPPVerificationResult {
        let serialPath = serial ?? ""
        let requestBody = ["checks": checks]
        let data = try JSONSerialization.data(withJSONObject: requestBody)
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/dpp/\(gtin)/\(serialPath)/verify",
            body: data,
            responseType: DPPVerificationResult.self
        )
    }
}