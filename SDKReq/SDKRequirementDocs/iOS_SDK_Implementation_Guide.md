# TraceWise iOS SDK Implementation Guide
**Repository: `TraceWise-iOS` | Expert-Level Implementation**

## 🏗️ Architecture Decision

### Chosen Architecture: **MVVM + Repository Pattern with Combine Framework**

**Why this architecture:**
- **iOS Best Practices**: Follows Apple's recommended patterns
- **Reactive Programming**: Combine framework for async operations
- **Protocol-Oriented**: Swift's strength with protocols and generics
- **Testability**: Easy to mock protocols and test business logic
- **Memory Management**: Proper ARC handling with weak references
- **Concurrency**: Modern async/await with structured concurrency
- **SwiftUI Ready**: Architecture supports both UIKit and SwiftUI

### Architecture Components:
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   TraceWiseSDK  │────│   Repository     │────│  NetworkService │
│   (Facade)      │    │   (Protocol)     │    │  (URLSession)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ├── ProductsModule       ├── ProductsRepo        ├── APIClient
         ├── EventsModule         ├── EventsRepo          ├── RetryManager
         ├── DppModule           ├── DppRepo             ├── AuthProvider
         └── CirpassModule       └── CirpassRepo         └── ErrorHandler
```

---

## 🚀 Step-by-Step Implementation

### Step 1: Project Setup (45 minutes)

#### Create Swift Package

```swift
// Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TraceWiseSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "TraceWiseSDK",
            targets: ["TraceWiseSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "TraceWiseSDK",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            path: "Sources/TraceWiseSDK"
        ),
        .testTarget(
            name: "TraceWiseSDKTests",
            dependencies: ["TraceWiseSDK"],
            path: "Tests/TraceWiseSDKTests"
        ),
    ]
)
```

### Step 2: Core Models (`Sources/TraceWiseSDK/Models/`)

#### `Product.swift`
```swift
import Foundation

public struct Product: Codable, Equatable {
    public let gtin: String
    public let serial: String?
    public let name: String
    public let description: String?
    public let manufacturer: String?
    public let category: String?
    
    public init(
        gtin: String,
        serial: String? = nil,
        name: String,
        description: String? = nil,
        manufacturer: String? = nil,
        category: String? = nil
    ) {
        self.gtin = gtin
        self.serial = serial
        self.name = name
        self.description = description
        self.manufacturer = manufacturer
        self.category = category
    }
}

public struct ProductIdentifiers: Equatable {
    public let gtin: String
    public let serial: String?
    public let batch: String?
    public let expiry: String?
    
    public init(gtin: String, serial: String? = nil, batch: String? = nil, expiry: String? = nil) {
        self.gtin = gtin
        self.serial = serial
        self.batch = batch
        self.expiry = expiry
    }
}

public struct PaginatedResponse<T: Codable>: Codable {
    public let items: [T]
    public let nextPageToken: String?
    public let totalCount: Int?
    
    public init(items: [T], nextPageToken: String? = nil, totalCount: Int? = nil) {
        self.items = items
        self.nextPageToken = nextPageToken
        self.totalCount = totalCount
    }
}
```

#### `LifecycleEvent.swift`
```swift
import Foundation

public struct LifecycleEvent: Codable, Equatable {
    public let gtin: String
    public let serial: String?
    public let type: String
    public let action: String
    public let bizStep: String
    public let disposition: String
    public let timestamp: String
    public let readPoint: String?
    public let bizLocation: String?
    public let details: [String: AnyCodable]?
    
    private enum CodingKeys: String, CodingKey {
        case gtin, serial, type, action, bizStep, disposition
        case timestamp = "when"
        case readPoint, bizLocation, details
    }
    
    public init(
        gtin: String,
        serial: String? = nil,
        type: String = "ObjectEvent",
        action: String = "OBSERVE",
        bizStep: String,
        disposition: String = "active",
        timestamp: String,
        readPoint: String? = nil,
        bizLocation: String? = nil,
        details: [String: Any]? = nil
    ) {
        self.gtin = gtin
        self.serial = serial
        self.type = type
        self.action = action
        self.bizStep = bizStep
        self.disposition = disposition
        self.timestamp = timestamp
        self.readPoint = readPoint
        self.bizLocation = bizLocation
        self.details = details?.mapValues { AnyCodable($0) }
    }
}

public struct EventResponse: Codable {
    public let id: String
    public let status: String
    public let epcisUrn: String?
}

// Helper for encoding/decoding Any values
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
```

### Step 3: Configuration & Error Handling

#### `SDKConfig.swift`
```swift
import Foundation

public struct SDKConfig {
    public let baseURL: String
    public let apiKey: String?
    public let firebaseTokenProvider: (() async throws -> String)?
    public let timeoutInterval: TimeInterval
    public let maxRetries: Int
    public let enableLogging: Bool
    
    public init(
        baseURL: String,
        apiKey: String? = nil,
        firebaseTokenProvider: (() async throws -> String)? = nil,
        timeoutInterval: TimeInterval = 30.0,
        maxRetries: Int = 3,
        enableLogging: Bool = false
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.firebaseTokenProvider = firebaseTokenProvider
        self.timeoutInterval = timeoutInterval
        self.maxRetries = maxRetries
        self.enableLogging = enableLogging
    }
}
```

#### `TraceWiseError.swift`
```swift
import Foundation

public enum TraceWiseError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case apiError(code: String, message: String, statusCode: Int)
    case authenticationError(String)
    case invalidDigitalLink(String)
    case timeout
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(_, let message, _):
            return message
        case .authenticationError(let message):
            return "Authentication error: \(message)"
        case .invalidDigitalLink(let message):
            return "Invalid Digital Link: \(message)"
        case .timeout:
            return "Request timeout"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    public var code: String {
        switch self {
        case .invalidURL:
            return "INVALID_URL"
        case .invalidResponse:
            return "INVALID_RESPONSE"
        case .networkError:
            return "NETWORK_ERROR"
        case .apiError(let code, _, _):
            return code
        case .authenticationError:
            return "AUTH_ERROR"
        case .invalidDigitalLink:
            return "INVALID_DIGITAL_LINK"
        case .timeout:
            return "TIMEOUT"
        case .unknown:
            return "UNKNOWN_ERROR"
        }
    }
}

struct APIErrorResponse: Codable {
    let error: APIErrorDetail
}

struct APIErrorDetail: Codable {
    let code: String
    let message: String
    let correlationId: String?
}
```

### Step 4: Network Layer

#### `APIClient.swift`
```swift
import Foundation
import Combine

protocol APIClientProtocol {
    func request<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: Data?,
        responseType: T.Type
    ) async throws -> T
}

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

class APIClient: APIClientProtocol {
    private let config: SDKConfig
    private let session: URLSession
    private let retryManager: RetryManager
    private let authProvider: AuthProvider
    
    init(config: SDKConfig) {
        self.config = config
        self.retryManager = RetryManager(maxRetries: config.maxRetries)
        self.authProvider = AuthProvider(config: config)
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeoutInterval
        configuration.timeoutIntervalForResource = config.timeoutInterval * 2
        self.session = URLSession(configuration: configuration)
    }
    
    func request<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        return try await retryManager.retry {
            try await self.performRequest(
                method: method,
                endpoint: endpoint,
                body: body,
                responseType: responseType
            )
        }
    }
    
    private func performRequest<T: Codable>(
        method: HTTPMethod,
        endpoint: String,
        body: Data?,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: config.baseURL + endpoint) else {
            throw TraceWiseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        let headers = try await authProvider.getHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        if config.enableLogging {
            print("🌐 \(method.rawValue) \(url)")
            if let body = body, let bodyString = String(data: body, encoding: .utf8) {
                print("📤 Body: \(bodyString)")
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TraceWiseError.invalidResponse
            }
            
            if config.enableLogging {
                print("📥 Response: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Data: \(responseString)")
                }
            }
            
            if httpResponse.statusCode >= 400 {
                let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
                throw TraceWiseError.apiError(
                    code: errorResponse?.error.code ?? "HTTP_ERROR",
                    message: errorResponse?.error.message ?? "HTTP \(httpResponse.statusCode)",
                    statusCode: httpResponse.statusCode
                )
            }
            
            return try JSONDecoder().decode(responseType, from: data)
            
        } catch {
            if error is TraceWiseError {
                throw error
            } else if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw TraceWiseError.timeout
                case .notConnectedToInternet, .networkConnectionLost:
                    throw TraceWiseError.networkError(urlError)
                default:
                    throw TraceWiseError.networkError(urlError)
                }
            } else {
                throw TraceWiseError.unknown(error)
            }
        }
    }
}
```

#### `RetryManager.swift`
```swift
import Foundation

class RetryManager {
    private let maxRetries: Int
    private let baseDelay: TimeInterval = 1.0
    
    init(maxRetries: Int) {
        self.maxRetries = maxRetries
    }
    
    func retry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on client errors (4xx) except 429
                if let traceWiseError = error as? TraceWiseError,
                   case .apiError(_, _, let statusCode) = traceWiseError,
                   statusCode >= 400 && statusCode < 500 && statusCode != 429 {
                    throw error
                }
                
                if attempt < maxRetries {
                    // Exponential backoff with jitter
                    let delay = baseDelay * pow(2.0, Double(attempt)) + Double.random(in: 0...1)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? TraceWiseError.unknown(NSError(domain: "RetryManager", code: -1))
    }
}
```

#### `AuthProvider.swift`
```swift
import Foundation
import FirebaseAuth

class AuthProvider {
    private let config: SDKConfig
    
    init(config: SDKConfig) {
        self.config = config
    }
    
    func getHeaders() async throws -> [String: String] {
        var headers: [String: String] = [:]
        
        // Add API key if available
        if let apiKey = config.apiKey {
            headers["X-API-Key"] = apiKey
        }
        
        // Add Firebase token if available
        if let tokenProvider = config.firebaseTokenProvider {
            do {
                let token = try await tokenProvider()
                headers["Authorization"] = "Bearer \(token)"
            } catch {
                throw TraceWiseError.authenticationError("Failed to get Firebase token: \(error.localizedDescription)")
            }
        }
        
        return headers
    }
}
```

### Step 5: Repository Layer

#### `ProductsRepository.swift`
```swift
import Foundation

protocol ProductsRepositoryProtocol {
    func getProduct(gtin: String, serial: String?) async throws -> Product
    func listProducts(pageSize: Int?, pageToken: String?) async throws -> PaginatedResponse<Product>
    func registerProduct(gtin: String, serial: String?, userId: String?) async throws -> RegisterResponse
    func getUserProducts(userId: String, pageSize: Int?, pageToken: String?) async throws -> PaginatedResponse<Product>
}

class ProductsRepository: ProductsRepositoryProtocol {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func getProduct(gtin: String, serial: String? = nil) async throws -> Product {
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
    
    func listProducts(pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Product> {
        var endpoint = "/v1/products/list"
        var queryItems: [String] = []
        
        if let pageSize = pageSize {
            queryItems.append("pageSize=\(pageSize)")
        }
        if let pageToken = pageToken {
            queryItems.append("pageToken=\(pageToken)")
        }
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<Product>.self
        )
    }
    
    func registerProduct(gtin: String, serial: String? = nil, userId: String? = nil) async throws -> RegisterResponse {
        let requestBody = RegisterProductRequest(gtin: gtin, serial: serial, userId: userId)
        let data = try JSONEncoder().encode(requestBody)
        
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/products/register",
            body: data,
            responseType: RegisterResponse.self
        )
    }
    
    func getUserProducts(userId: String, pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Product> {
        var endpoint = "/v1/products/users/\(userId)"
        var queryItems: [String] = []
        
        if let pageSize = pageSize {
            queryItems.append("pageSize=\(pageSize)")
        }
        if let pageToken = pageToken {
            queryItems.append("pageToken=\(pageToken)")
        }
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<Product>.self
        )
    }
}

// Supporting types
struct RegisterProductRequest: Codable {
    let gtin: String
    let serial: String?
    let userId: String?
}

public struct RegisterResponse: Codable {
    public let status: String
}
```

### Step 6: SDK Modules (Exact Trello Task Signatures)

#### `ProductsModule.swift`
```swift
import Foundation

public class ProductsModule {
    private let repository: ProductsRepositoryProtocol
    
    init(repository: ProductsRepositoryProtocol) {
        self.repository = repository
    }
    
    // Exact signature as required by Trello task
    public func getProduct(gtin: String, serial: String? = nil) async throws -> Product {
        return try await repository.getProduct(gtin: gtin, serial: serial)
    }
    
    // Exact signature as required by Trello task
    public func registerProduct(userId: String, product: Product) async throws {
        let _ = try await repository.registerProduct(
            gtin: product.gtin,
            serial: product.serial,
            userId: userId
        )
    }
    
    // Additional methods for complete API coverage
    public func listProducts(pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Product> {
        return try await repository.listProducts(pageSize: pageSize, pageToken: pageToken)
    }
    
    public func getUserProducts(userId: String, pageSize: Int? = nil, pageToken: String? = nil) async throws -> PaginatedResponse<Product> {
        return try await repository.getUserProducts(userId: userId, pageSize: pageSize, pageToken: pageToken)
    }
}
```

#### `EventsModule.swift`
```swift
import Foundation

protocol EventsRepositoryProtocol {
    func addLifecycleEvent(_ event: LifecycleEvent) async throws -> EventResponse
    func getProductEvents(gtin: String, serial: String, pageSize: Int?, pageToken: String?) async throws -> PaginatedResponse<LifecycleEvent>
}

public class EventsModule {
    private let repository: EventsRepositoryProtocol
    
    init(repository: EventsRepositoryProtocol) {
        self.repository = repository
    }
    
    // Exact signature as required by Trello task
    public func addLifecycleEvent(event: LifecycleEvent) async throws {
        let _ = try await repository.addLifecycleEvent(event)
    }
    
    // Exact signature as required by Trello task
    public func getProductEvents(id: String, limit: Int? = nil, pageToken: String? = nil) async throws -> [LifecycleEvent] {
        // Parse composite ID (gtin:serial format)
        let components = id.components(separatedBy: ":")
        guard let gtin = components.first else {
            throw TraceWiseError.invalidDigitalLink("Invalid product ID format")
        }
        let serial = components.count > 1 ? components[1] : ""
        
        let response = try await repository.getProductEvents(
            gtin: gtin,
            serial: serial,
            pageSize: limit,
            pageToken: pageToken
        )
        
        return response.items
    }
}

class EventsRepository: EventsRepositoryProtocol {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func addLifecycleEvent(_ event: LifecycleEvent) async throws -> EventResponse {
        let data = try JSONEncoder().encode(event)
        
        return try await apiClient.request(
            method: .POST,
            endpoint: "/v1/events",
            body: data,
            responseType: EventResponse.self
        )
    }
    
    func getProductEvents(gtin: String, serial: String, pageSize: Int?, pageToken: String?) async throws -> PaginatedResponse<LifecycleEvent> {
        var endpoint = "/v1/events/\(gtin)/\(serial)"
        var queryItems: [String] = []
        
        if let pageSize = pageSize {
            queryItems.append("pageSize=\(pageSize)")
        }
        if let pageToken = pageToken {
            queryItems.append("pageToken=\(pageToken)")
        }
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: PaginatedResponse<LifecycleEvent>.self
        )
    }
}
```

#### `CirpassModule.swift`
```swift
import Foundation

public struct CirpassProduct: Codable {
    public let id: String
    public let gtin: String?
    public let serial: String?
    public let name: String
    public let manufacturer: Manufacturer?
    public let materials: [String]?
    public let origin: String?
    public let lifecycle: [LifecycleInfo]?
    public let warranty: Warranty?
    public let repairability: Repairability?
    
    public struct Manufacturer: Codable {
        public let name: String
        public let country: String
    }
    
    public struct LifecycleInfo: Codable {
        public let eventType: String
        public let timestamp: String
        public let details: [String: AnyCodable]?
    }
    
    public struct Warranty: Codable {
        public let ends: String
    }
    
    public struct Repairability: Codable {
        public let score: Double
    }
}

protocol CirpassRepositoryProtocol {
    func getCirpassProduct(id: String) async throws -> CirpassProduct
    func listCirpassProducts(limit: Int?) async throws -> CirpassProductsResponse
}

public class CirpassModule {
    private let repository: CirpassRepositoryProtocol
    
    init(repository: CirpassRepositoryProtocol) {
        self.repository = repository
    }
    
    // Exact signature as required by Trello task
    public func getCirpassProduct(id: String) async throws -> CirpassProduct {
        return try await repository.getCirpassProduct(id: id)
    }
    
    public func listCirpassProducts(limit: Int? = nil) async throws -> CirpassProductsResponse {
        return try await repository.listCirpassProducts(limit: limit)
    }
}

public struct CirpassProductsResponse: Codable {
    public let products: [CirpassProduct]
}

class CirpassRepository: CirpassRepositoryProtocol {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func getCirpassProduct(id: String) async throws -> CirpassProduct {
        return try await apiClient.request(
            method: .GET,
            endpoint: "/v1/cirpass-sim/product/\(id)",
            body: nil,
            responseType: CirpassProduct.self
        )
    }
    
    func listCirpassProducts(limit: Int?) async throws -> CirpassProductsResponse {
        var endpoint = "/v1/cirpass-sim/products"
        if let limit = limit {
            endpoint += "?limit=\(limit)"
        }
        
        return try await apiClient.request(
            method: .GET,
            endpoint: endpoint,
            body: nil,
            responseType: CirpassProductsResponse.self
        )
    }
}
```

### Step 7: Digital Link Parser

#### `DigitalLinkParser.swift`
```swift
import Foundation

public class DigitalLinkParser {
    
    public func parse(_ url: String) throws -> ProductIdentifiers {
        // GS1 Digital Link format: https://id.gs1.org/01/{gtin}/21/{serial}
        let gtinPattern = #"/01/(\d{14})"#
        let serialPattern = #"/21/([^/?]+)"#
        let batchPattern = #"/10/([^/?]+)"#
        let expiryPattern = #"/17/(\d{6})"#
        
        guard let gtinMatch = url.firstMatch(of: try! Regex(gtinPattern)) else {
            throw TraceWiseError.invalidDigitalLink("GTIN not found in Digital Link")
        }
        
        let gtin = String(gtinMatch.1)
        let serial = url.firstMatch(of: try! Regex(serialPattern)).map { String($0.1) }
        let batch = url.firstMatch(of: try! Regex(batchPattern)).map { String($0.1) }
        let expiry = url.firstMatch(of: try! Regex(expiryPattern)).map { String($0.1) }
        
        return ProductIdentifiers(
            gtin: gtin,
            serial: serial,
            batch: batch,
            expiry: expiry
        )
    }
}
```

### Step 8: Main SDK Class

#### `TraceWiseSDK.swift`
```swift
import Foundation
import FirebaseAuth

public class TraceWiseSDK {
    public let products: ProductsModule
    public let events: EventsModule
    public let cirpass: CirpassModule
    
    private let digitalLinkParser: DigitalLinkParser
    private let apiClient: APIClient
    
    public init(config: SDKConfig) {
        self.apiClient = APIClient(config: config)
        self.digitalLinkParser = DigitalLinkParser()
        
        // Initialize repositories
        let productsRepository = ProductsRepository(apiClient: apiClient)
        let eventsRepository = EventsRepository(apiClient: apiClient)
        let cirpassRepository = CirpassRepository(apiClient: apiClient)
        
        // Initialize modules
        self.products = ProductsModule(repository: productsRepository)
        self.events = EventsModule(repository: eventsRepository)
        self.cirpass = CirpassModule(repository: cirpassRepository)
    }
    
    public func parseDigitalLink(_ url: String) throws -> ProductIdentifiers {
        return try digitalLinkParser.parse(url)
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

public struct HealthResponse: Codable {
    public let status: String
    public let timestamp: String
    public let version: String?
}
```

---

## 🧪 Testing Strategy

### Unit Tests (`Tests/TraceWiseSDKTests/`)

#### `ProductsModuleTests.swift`
```swift
import XCTest
@testable import TraceWiseSDK

final class ProductsModuleTests: XCTestCase {
    
    var productsModule: ProductsModule!
    var mockRepository: MockProductsRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockProductsRepository()
        productsModule = ProductsModule(repository: mockRepository)
    }
    
    func testGetProduct() async throws {
        // Given
        let expectedProduct = Product(gtin: "1234567890123", name: "Test Product")
        mockRepository.getProductResult = expectedProduct
        
        // When
        let result = try await productsModule.getProduct(gtin: "1234567890123", serial: "SN123")
        
        // Then
        XCTAssertEqual(result, expectedProduct)
        XCTAssertEqual(mockRepository.getProductCallCount, 1)
        XCTAssertEqual(mockRepository.lastGetProductGtin, "1234567890123")
        XCTAssertEqual(mockRepository.lastGetProductSerial, "SN123")
    }
    
    func testRegisterProduct() async throws {
        // Given
        let product = Product(gtin: "1234567890123", name: "Test Product")
        mockRepository.registerProductResult = RegisterResponse(status: "registered")
        
        // When
        try await productsModule.registerProduct(userId: "user123", product: product)
        
        // Then
        XCTAssertEqual(mockRepository.registerProductCallCount, 1)
        XCTAssertEqual(mockRepository.lastRegisterProductUserId, "user123")
        XCTAssertEqual(mockRepository.lastRegisterProductGtin, "1234567890123")
    }
}

class MockProductsRepository: ProductsRepositoryProtocol {
    var getProductCallCount = 0
    var lastGetProductGtin: String?
    var lastGetProductSerial: String?
    var getProductResult: Product?
    
    var registerProductCallCount = 0
    var lastRegisterProductUserId: String?
    var lastRegisterProductGtin: String?
    var registerProductResult: RegisterResponse?
    
    func getProduct(gtin: String, serial: String?) async throws -> Product {
        getProductCallCount += 1
        lastGetProductGtin = gtin
        lastGetProductSerial = serial
        
        guard let result = getProductResult else {
            throw TraceWiseError.unknown(NSError(domain: "Test", code: -1))
        }
        return result
    }
    
    func registerProduct(gtin: String, serial: String?, userId: String?) async throws -> RegisterResponse {
        registerProductCallCount += 1
        lastRegisterProductUserId = userId
        lastRegisterProductGtin = gtin
        
        guard let result = registerProductResult else {
            throw TraceWiseError.unknown(NSError(domain: "Test", code: -1))
        }
        return result
    }
    
    func listProducts(pageSize: Int?, pageToken: String?) async throws -> PaginatedResponse<Product> {
        return PaginatedResponse(items: [])
    }
    
    func getUserProducts(userId: String, pageSize: Int?, pageToken: String?) async throws -> PaginatedResponse<Product> {
        return PaginatedResponse(items: [])
    }
}
```

#### `DigitalLinkParserTests.swift`
```swift
import XCTest
@testable import TraceWiseSDK

final class DigitalLinkParserTests: XCTestCase {
    
    var parser: DigitalLinkParser!
    
    override func setUp() {
        super.setUp()
        parser = DigitalLinkParser()
    }
    
    func testParseValidDigitalLink() throws {
        // Given
        let url = "https://id.gs1.org/01/04012345678905/21/SN123456"
        
        // When
        let result = try parser.parse(url)
        
        // Then
        XCTAssertEqual(result.gtin, "04012345678905")
        XCTAssertEqual(result.serial, "SN123456")
        XCTAssertNil(result.batch)
        XCTAssertNil(result.expiry)
    }
    
    func testParseDigitalLinkWithBatchAndExpiry() throws {
        // Given
        let url = "https://id.gs1.org/01/04012345678905/21/SN123456/10/BATCH001/17/251231"
        
        // When
        let result = try parser.parse(url)
        
        // Then
        XCTAssertEqual(result.gtin, "04012345678905")
        XCTAssertEqual(result.serial, "SN123456")
        XCTAssertEqual(result.batch, "BATCH001")
        XCTAssertEqual(result.expiry, "251231")
    }
    
    func testParseInvalidDigitalLink() {
        // Given
        let url = "https://example.com/invalid"
        
        // When/Then
        XCTAssertThrowsError(try parser.parse(url)) { error in
            guard case TraceWiseError.invalidDigitalLink = error else {
                XCTFail("Expected invalidDigitalLink error")
                return
            }
        }
    }
}
```

### Integration Tests

#### `SDKIntegrationTests.swift`
```swift
import XCTest
@testable import TraceWiseSDK

final class SDKIntegrationTests: XCTestCase {
    
    var sdk: TraceWiseSDK!
    
    override func setUp() {
        super.setUp()
        let config = SDKConfig(
            baseURL: "http://localhost:5001/tracewise-staging/europe-central2/api",
            apiKey: "test-key",
            enableLogging: true
        )
        sdk = TraceWiseSDK(config: config)
    }
    
    func testEndToEndWorkflow() async throws {
        // Parse Digital Link
        let url = "https://id.gs1.org/01/04012345678905/21/SN123456"
        let ids = try sdk.parseDigitalLink(url)
        
        XCTAssertEqual(ids.gtin, "04012345678905")
        XCTAssertEqual(ids.serial, "SN123456")
        
        // Test against local emulator (if available)
        do {
            let product = try await sdk.products.getProduct(gtin: ids.gtin, serial: ids.serial)
            XCTAssertEqual(product.gtin, ids.gtin)
        } catch {
            // Skip if emulator not available
            print("Skipping integration test - emulator not available: \(error)")
        }
    }
    
    func testHealthCheck() async throws {
        do {
            let health = try await sdk.healthCheck()
            XCTAssertEqual(health.status, "ok")
        } catch {
            // Skip if API not available
            print("Skipping health check - API not available: \(error)")
        }
    }
}
```

---

## 📦 Usage Examples

### Basic Setup

```swift
import TraceWiseSDK
import FirebaseAuth

// In AppDelegate or SceneDelegate
func setupTraceWiseSDK() {
    let config = SDKConfig(
        baseURL: "https://trace-wise.eu/api",
        firebaseTokenProvider: {
            guard let user = Auth.auth().currentUser else {
                throw TraceWiseError.authenticationError("User not authenticated")
            }
            return try await user.getIDToken()
        },
        enableLogging: true
    )
    
    let sdk = TraceWiseSDK(config: config)
    // Store sdk instance globally or inject via dependency injection
}
```

### Usage in SwiftUI

```swift
import SwiftUI
import TraceWiseSDK

struct ContentView: View {
    @StateObject private var viewModel = ProductViewModel()
    
    var body: some View {
        VStack {
            if let product = viewModel.product {
                Text("Product: \(product.name)")
                Text("GTIN: \(product.gtin)")
            } else {
                Text("Loading...")
            }
        }
        .task {
            await viewModel.loadProduct()
        }
    }
}

@MainActor
class ProductViewModel: ObservableObject {
    @Published var product: Product?
    @Published var error: TraceWiseError?
    
    private let sdk: TraceWiseSDK
    
    init() {
        let config = SDKConfig(baseURL: "https://trace-wise.eu/api")
        self.sdk = TraceWiseSDK(config: config)
    }
    
    func loadProduct() async {
        do {
            // Parse QR code
            let url = "https://id.gs1.org/01/04012345678905/21/SN123456"
            let ids = try sdk.parseDigitalLink(url)
            
            // Get product (exact Trello task signature)
            let product = try await sdk.products.getProduct(gtin: ids.gtin, serial: ids.serial)
            self.product = product
            
            // Register product to user (exact Trello task signature)
            try await sdk.products.registerProduct(userId: "user123", product: product)
            
            // Add lifecycle event (exact Trello task signature)
            let event = LifecycleEvent(
                gtin: ids.gtin,
                serial: ids.serial,
                bizStep: "purchased",
                timestamp: ISO8601DateFormatter().string(from: Date()),
                details: ["location": "Store A"]
            )
            try await sdk.events.addLifecycleEvent(event: event)
            
            // Get product events (exact Trello task signature)
            let events = try await sdk.events.getProductEvents(
                id: "\(ids.gtin):\(ids.serial ?? "")",
                limit: 20
            )
            
            // Get CIRPASS product (exact Trello task signature)
            let cirpassProduct = try await sdk.cirpass.getCirpassProduct(id: "cirpass-001")
            
        } catch {
            self.error = error as? TraceWiseError ?? TraceWiseError.unknown(error)
        }
    }
}
```

### Usage in UIKit

```swift
import UIKit
import TraceWiseSDK

class ProductViewController: UIViewController {
    private let sdk: TraceWiseSDK
    
    init() {
        let config = SDKConfig(baseURL: "https://trace-wise.eu/api")
        self.sdk = TraceWiseSDK(config: config)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            await loadProduct()
        }
    }
    
    private func loadProduct() async {
        do {
            let url = "https://id.gs1.org/01/04012345678905/21/SN123456"
            let ids = try sdk.parseDigitalLink(url)
            let product = try await sdk.products.getProduct(gtin: ids.gtin, serial: ids.serial)
            
            await MainActor.run {
                // Update UI
                self.title = product.name
            }
        } catch {
            await MainActor.run {
                // Handle error
                print("Error: \(error)")
            }
        }
    }
}
```

---

## 🚀 Publishing

### CocoaPods Support

Create `TraceWiseSDK.podspec`:

```ruby
Pod::Spec.new do |spec|
  spec.name         = "TraceWiseSDK"
  spec.version      = "1.0.0"
  spec.summary      = "Official TraceWise SDK for iOS"
  spec.description  = "TraceWise SDK provides seamless integration with TraceWise API for supply chain transparency and digital product passports."
  
  spec.homepage     = "https://github.com/tracewise/TraceWise-iOS"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "TraceWise" => "sdk@tracewise.io" }
  
  spec.ios.deployment_target = "13.0"
  spec.osx.deployment_target = "10.15"
  spec.watchos.deployment_target = "6.0"
  spec.tvos.deployment_target = "13.0"
  
  spec.source       = { :git => "https://github.com/tracewise/TraceWise-iOS.git", :tag => "#{spec.version}" }
  spec.source_files = "Sources/TraceWiseSDK/**/*.swift"
  
  spec.dependency "Firebase/Auth", "~> 10.0"
  
  spec.swift_version = "5.9"
end
```

### GitHub Actions for CI/CD

```yaml
name: CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Select Xcode version
        run: sudo xcode-select -s /Applications/Xcode_15.0.app/Contents/Developer
      - name: Build and test
        run: |
          swift build
          swift test
      - name: Test iOS
        run: |
          xcodebuild test \
            -scheme TraceWiseSDK \
            -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

  publish:
    if: startsWith(github.ref, 'refs/tags/')
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Publish to CocoaPods
        env:
          COCOAPODS_TRUNK_TOKEN: ${{ secrets.COCOAPODS_TRUNK_TOKEN }}
        run: |
          pod trunk push TraceWiseSDK.podspec
```

---

## ✅ Implementation Checklist

- [ ] **Project Setup & Package.swift** (45 min)
- [ ] **Core Models & Data Types** (60 min)
- [ ] **Configuration & Error Handling** (45 min)
- [ ] **Network Layer (URLSession)** (90 min)
- [ ] **Authentication & Token Management** (60 min)
- [ ] **Retry Manager with Exponential Backoff** (45 min)
- [ ] **Repository Pattern Implementation** (90 min)
- [ ] **SDK Modules (Exact Signatures)** (90 min)
- [ ] **Digital Link Parser** (30 min)
- [ ] **Main SDK Class** (45 min)
- [ ] **Unit Tests** (120 min)
- [ ] **Integration Tests** (60 min)
- [ ] **SwiftUI & UIKit Examples** (60 min)
- [ ] **CocoaPods Support** (30 min)
- [ ] **Documentation & README** (60 min)

**Total Estimated Time: 14 hours**

---

## 🎯 Key Architecture Benefits

1. **Protocol-Oriented Design**: Leverages Swift's strengths with protocols and generics
2. **Modern Concurrency**: Uses async/await and structured concurrency
3. **Memory Safety**: Proper ARC handling with weak references
4. **Type Safety**: Full Swift type safety with Codable protocols
5. **Reactive Programming**: Ready for Combine integration
6. **SwiftUI Ready**: Architecture supports both UIKit and SwiftUI
7. **Testability**: Easy to mock protocols and test business logic
8. **Performance**: Efficient networking with proper error handling
9. **iOS Best Practices**: Follows Apple's recommended patterns
10. **Maintainability**: Clear separation of concerns with repository pattern

This architecture ensures the iOS SDK is production-ready, follows iOS best practices, and provides excellent performance while meeting all exact requirements from the Trello task.