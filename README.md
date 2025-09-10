# TraceWise iOS SDK

Official iOS SDK for TraceWise API - supply chain transparency and digital product passports.

## Installation

### Swift Package Manager
```swift
.package(url: "https://github.com/tracewise/TraceWise-iOS.git", from: "1.0.0")
```

### CocoaPods
```ruby
pod 'TraceWiseSDK', '~> 1.0'
```

## Quick Start

```swift
import TraceWiseSDK
import FirebaseAuth

// Setup
let config = SDKConfig(
    baseURL: "https://trace-wise.eu/api",
    firebaseTokenProvider: {
        return try await Auth.auth().currentUser?.getIDToken() ?? ""
    }
)
let sdk = TraceWiseSDK(config: config)

// Parse QR code
let ids = try sdk.parseDigitalLink("https://id.gs1.org/01/04012345678905/21/SN123")

// Get product
let product = try await sdk.getProduct(gtin: ids.gtin, serial: ids.serial)

// Register to user
try await sdk.registerProduct(userId: "user123", product: product)

// Add event
let event = LifecycleEvent(
    gtin: ids.gtin,
    serial: ids.serial,
    bizStep: "shipping",
    timestamp: ISO8601DateFormatter().string(from: Date())
)
try await sdk.addLifecycleEvent(event: event)

// Get events
let events = try await sdk.getProductEvents(id: "\(ids.gtin):\(ids.serial ?? "")")

// CIRPASS
let cirpassProduct = try await sdk.getCirpassProduct(id: "cirpass-001")
```

## SwiftUI Example

```swift
struct ProductView: View {
    @State private var product: Product?
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if let product = product {
                Text(product.name)
                Text("GTIN: \(product.gtin)")
            } else if isLoading {
                ProgressView()
            }
        }
        .task { await loadProduct() }
    }
    
    func loadProduct() async {
        isLoading = true
        do {
            let config = SDKConfig(baseURL: "https://trace-wise.eu/api")
            let sdk = TraceWiseSDK(config: config)
            let ids = try sdk.parseDigitalLink("https://id.gs1.org/01/04012345678905/21/SN123")
            product = try await sdk.getProduct(gtin: ids.gtin, serial: ids.serial)
        } catch {
            print("Error: \(error)")
        }
        isLoading = false
    }
}
```

## Configuration

```swift
let config = SDKConfig(
    baseURL: "https://trace-wise.eu/api",     // Production
    // baseURL: "http://localhost:5001/...", // Local development
    apiKey: "your-api-key",                  // Optional
    firebaseTokenProvider: { /* token */ },   // Firebase Auth
    timeoutInterval: 30.0,                    // Request timeout
    maxRetries: 3,                           // Retry attempts
    enableLogging: true                      // Debug logs
)
```

## Error Handling

```swift
do {
    let product = try await sdk.getProduct(gtin: "123")
} catch TraceWiseError.rateLimitExceeded(let retryAfter) {
    print("Rate limited. Retry after \(retryAfter ?? 60)s")
} catch TraceWiseError.authenticationError(let message) {
    print("Auth error: \(message)")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.9+
- Firebase Auth (optional)

## License

MIT