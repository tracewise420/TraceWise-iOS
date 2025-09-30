import Foundation

// MARK: - Resolve Models

public struct ResolvedProduct: Codable, Equatable {
    public let url: String
    public let resolvedUrl: String?
    public let productIds: ProductIDs
    public let product: Product?
    public let dpp: DPP?
    public let cirpassProduct: CirpassProduct?
    public let resolvedAt: String
    public let source: String
    
    public init(
        url: String,
        resolvedUrl: String? = nil,
        productIds: ProductIDs,
        product: Product? = nil,
        dpp: DPP? = nil,
        cirpassProduct: CirpassProduct? = nil,
        resolvedAt: String,
        source: String
    ) {
        self.url = url
        self.resolvedUrl = resolvedUrl
        self.productIds = productIds
        self.product = product
        self.dpp = dpp
        self.cirpassProduct = cirpassProduct
        self.resolvedAt = resolvedAt
        self.source = source
    }
}

public struct ResolveRequest: Codable {
    public let url: String
    public let includeProduct: Bool
    public let includeDpp: Bool
    public let includeCirpass: Bool
    
    public init(url: String, includeProduct: Bool = true, includeDpp: Bool = false, includeCirpass: Bool = false) {
        self.url = url
        self.includeProduct = includeProduct
        self.includeDpp = includeDpp
        self.includeCirpass = includeCirpass
    }
}

public struct ResolveResponse: Codable, Equatable {
    public let gtin: String
    public let serial: String?
    public let links: [String: String]
    public let resolvedAt: String
    
    public init(gtin: String, serial: String? = nil, links: [String: String], resolvedAt: String) {
        self.gtin = gtin
        self.serial = serial
        self.links = links
        self.resolvedAt = resolvedAt
    }
}