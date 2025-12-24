import Foundation

public class TraceWiseSDK {
    private let apiClient: APIClient
    private let subscriptionManager: SubscriptionManager
    private let csrfManager: CSRFManager
    private let offlineQueue: OfflineQueue
    
    // MARK: - Auth Provider
    public let authProvider: AuthProvider
    
    // MARK: - Modules
    public let products: ProductsModule
    public let dpp: DPPModule
    public let search: SearchModule
    public let resolve: ResolveModule
    public let cirpass: CirpassModule
    public let bulk: BulkModule
    public let webhooks: WebhooksModule
    public let tenants: TenantsModule
    public let assets: AssetsModule
    
    public init(config: SDKConfig) {
        self.authProvider = AuthProvider(config: config)
        self.apiClient = APIClient(config: config, authProvider: authProvider)
        self.subscriptionManager = SubscriptionManager(apiClient: apiClient)
        self.csrfManager = CSRFManager(apiClient: apiClient)
        self.offlineQueue = OfflineQueue()
        
        // Initialize modules
        self.products = ProductsModule(apiClient: apiClient)
        self.dpp = DPPModule(apiClient: apiClient)
        self.search = SearchModule(apiClient: apiClient)
        self.resolve = ResolveModule(apiClient: apiClient)
        self.cirpass = CirpassModule(apiClient: apiClient)
        self.bulk = BulkModule(apiClient: apiClient)
        self.webhooks = WebhooksModule(apiClient: apiClient)
        self.tenants = TenantsModule(apiClient: apiClient)
        self.assets = AssetsModule(apiClient: apiClient)
    }
    
    public static func initialize(config: SDKConfig) async throws -> TraceWiseSDK {
        return TraceWiseSDK(config: config)
    }
    
    // MARK: - JWT Authentication Methods
    
    public func exchangeFirebaseForJWT(_ firebaseToken: String) async throws -> [String: Any] {
        print("🔄 [DEBUG] iOS SDK: exchangeFirebaseForJWT called")
        do {
            let jwtResponse = try await authProvider.getAuthToken(firebaseToken)
            print("✅ [DEBUG] iOS SDK: JWT exchange successful in main SDK")
            return jwtResponse.toDictionary()
        } catch {
            print("❌ [DEBUG] iOS SDK: JWT exchange failed in main SDK: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func getStoredJWTToken() async throws -> String {
        return try await authProvider.getStoredJWTToken()
    }
    
    public func refreshJWTToken() async throws -> String {
        return try await authProvider.refreshJWTToken()
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
        return try await cirpass.getCirpassProduct(id: id)
    }
    
    // MARK: - Enhanced Product Methods
    
    public func listProducts(pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Product> {
        return try await products.listProducts(pageSize: pageSize, pageToken: pageToken)
    }
    
    public func createProduct(product: Product) async throws -> CreateResponse {
        return try await products.createProduct(product: product)
    }
    
    public func getProductById(id: String) async throws -> Product {
        return try await products.getProductById(id: id)
    }
    
    public func updateProduct(id: String, updates: [String: Any]) async throws -> Product {
        return try await products.updateProduct(id: id, updates: updates)
    }
    
    public func deleteProduct(id: String) async throws {
        try await products.deleteProduct(id: id)
    }
    
    public func getUserProducts(userId: String, pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Product> {
        return try await products.getUserProducts(userId: userId, pageSize: pageSize, pageToken: pageToken)
    }
    
    // MARK: - GS1 Digital Link Methods
    
    public func resolveDigitalLinkEnhanced(url: String) async throws -> ResolveDigitalLinkResponse {
        return try await products.resolveDigitalLink(url: url)
    }
    
    public func getProductByGtin(gtin: String, serial: String? = nil) async throws -> EnhancedProductResponse {
        return try await products.getProductByGtin(gtin: gtin, serial: serial)
    }
    
    public func generateQRCode(gtin: String, serial: String? = nil) async throws -> QRCodeResponse {
        return try await products.generateQRCode(gtin: gtin, serial: serial)
    }
    
    // MARK: - Enhanced CIRPASS Methods
    
    public func seedCirpassProducts(products: [CirpassProduct]) async throws {
        try await cirpass.seedCirpassProducts(products: products)
    }
    
    public func listCirpassProducts(limit: Int? = nil) async throws -> CirpassProductsResponse {
        return try await cirpass.listCirpassProducts(limit: limit)
    }
    
    // MARK: - DPP Methods
    
    public func createDPP(dppData: DPPCreateRequest) async throws -> DPP {
        return try await dpp.createDPP(dppData: dppData)
    }
    
    public func getDPP(gtin: String, serial: String? = nil) async throws -> DPP {
        return try await dpp.getDPP(gtin: gtin, serial: serial)
    }
    
    public func updateDPPClaims(gtin: String, serial: String? = nil, claimsUpdate: DPPClaimsUpdate) async throws -> DPP {
        return try await dpp.updateDPPClaims(gtin: gtin, serial: serial, claimsUpdate: claimsUpdate)
    }
    
    public func verifyDPP(gtin: String, serial: String? = nil, checks: [String] = ["schema", "signature", "consistency"]) async throws -> DPPVerificationResult {
        return try await dpp.verifyDPP(gtin: gtin, serial: serial, checks: checks)
    }
    
    // MARK: - Search Methods
    
    public func search(query: String, filters: [String: AnyCodable]? = nil, limit: Int? = nil) async throws -> [SearchResult] {
        return try await search.search(query: query, filters: filters, limit: limit)
    }
    
    public func searchProducts(query: String? = nil, filters: ProductFilters? = nil) async throws -> PaginatedResponse<Product> {
        if let query = query {
            let products = try await search.searchProducts(query: query, filters: filters)
            return PaginatedResponse(items: products, nextPageToken: nil, totalCount: products.count)
        } else {
            return try await products.listProducts()
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
        return try await search.searchEvents(
            type: type,
            bizStep: bizStep,
            readPoint: readPoint,
            whenFrom: whenFrom,
            whenTo: whenTo,
            pageSize: pageSize,
            pageToken: pageToken
        )
    }
    
    // MARK: - Resolve Methods
    
    public func resolve(url: String) async throws -> ResolvedProduct {
        return try await resolve.resolve(url: url)
    }
    
    public func resolveDigitalLink(url: String) async throws -> ProductIDs {
        return try await resolve.resolveDigitalLink(url: url)
    }
    
    public func resolveWithOptions(url: String, includeProduct: Bool = true, includeDpp: Bool = false, includeCirpass: Bool = false) async throws -> ResolvedProduct {
        return try await resolve.resolveWithOptions(url: url, includeProduct: includeProduct, includeDpp: includeDpp, includeCirpass: includeCirpass)
    }
    
    public func resolveProductLinks(gtin: String, serial: String? = nil, linkType: String? = nil) async throws -> ResolveResponse {
        return try await resolve.resolveProductLinks(gtin: gtin, serial: serial, linkType: linkType)
    }
    
    // MARK: - Additional Methods
    
    public func getSubscriptionInfo() async throws -> SubscriptionInfo {
        return try await subscriptionManager.getSubscriptionInfo()
    }
    
    public func refreshCSRFToken() async throws {
        csrfManager.clearToken()
        _ = try await csrfManager.getCSRFToken()
    }
    
    public func healthCheck() async throws -> HealthResponse {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/health",
            body: nil,
            responseType: HealthResponse.self
        )
    }
    
    public func getPerformanceMetrics() -> PerformanceMetrics {
        return PerformanceMonitor.shared.getMetrics()
    }
    
    public func resetPerformanceMetrics() {
        PerformanceMonitor.shared.reset()
    }
    
    // MARK: - Offline Queue Management
    
    public func processOfflineQueue() async {
        await offlineQueue.processQueue()
    }
    
    public func getOfflineQueueSize() -> Int {
        return offlineQueue.getQueueSize()
    }
    
    // MARK: - Widget Functionality
    
    @available(iOS 14.0, macOS 11.0, *)
    public func showDppPopup(dpp: DPP, onRepair: (() -> Void)? = nil, onResell: (() -> Void)? = nil, onFullDpp: (() -> Void)? = nil) -> DppPopupView {
        return DppPopupView(
            dpp: dpp,
            isPresented: .constant(true),
            onRepair: onRepair,
            onResell: onResell,
            onFullDpp: onFullDpp
        )
    }
    

}

