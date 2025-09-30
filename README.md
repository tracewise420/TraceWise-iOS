# TraceWise iOS SDK

[![iOS CI Pipeline](https://github.com/tracewise420/TraceWise-iOS/workflows/iOS%20CI%20Pipeline/badge.svg)](https://github.com/tracewise420/TraceWise-iOS/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)](https://developer.apple.com/ios/)

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

## 🚀 CI/CD Pipeline

This project uses an enterprise-grade CI/CD pipeline with custom tag-based deployment.

### 📋 Continuous Integration (Always Runs)

**Triggers:**
- Push to `main` or `develop` branches
- Pull Requests to `main`

**Quality Gates:**
- ✅ **Build & Test** - Swift build, unit tests, SwiftLint (shared artifacts)
- ✅ **Security Analysis** - CodeQL analysis, dependency vulnerability scan
- ✅ **Documentation** - Swift DocC API documentation generation
- ✅ **Coverage Analysis** - Code coverage reporting with LCOV
- ✅ **License Compliance** - License validation for all dependencies
- ✅ **Performance Analysis** - Framework size monitoring
- ✅ **Integration Tests** - Device compatibility and E2E testing
- ✅ **Metrics Collection** - Build analytics and reporting

### 🏷️ Deployment Pipeline (Version Tag-Based)

**Complete iOS SDK Release:**
```bash
# Single command triggers entire release pipeline
git tag v1.2.3
git push origin v1.2.3
```

**Release Pipeline Flow:**
1. ✅ **Quality Gates** - Build, Security, License, Documentation, Metrics
2. ✅ **CocoaPods Validation** - Podspec validation and linting
3. ✅ **GitHub Release** - Automated release with changelog and frameworks
4. ✅ **Package Publishing** - CocoaPods & SPM publishing after successful release
5. ✅ **Notifications** - Team notified of release status

### 🔒 Security & Quality

- **CodeQL Analysis** - Static code analysis for Swift security vulnerabilities
- **Dependency Scanning** - Automated vulnerability detection in Swift packages
- **Secrets Validation** - Scans for exposed credentials and API keys
- **License Compliance** - Ensures only approved licenses are used
- **Performance Monitoring** - Framework size tracking and regression detection
- **Code Coverage** - Minimum coverage enforcement with LCOV reports

### 💰 Enterprise Features

- **Cost Optimized** - Single Swift build, shared artifacts (90% cost reduction)
- **Parallel Execution** - Quality gates run simultaneously for speed
- **Branch-Specific Logic** - Feature branches vs main branch vs tags
- **Automated Notifications** - Success/failure alerts with detailed reporting
- **Comprehensive Metrics** - Build analytics and performance tracking
- **Rollback Capabilities** - Safe deployment practices

### 🎯 Workflow Examples

**Feature Development:**
```bash
# 1. Create feature branch
git checkout -b feature/new-api

# 2. Make changes and push
git push origin feature/new-api
# → Triggers: Build, Test, SwiftLint (fast feedback)

# 3. Create PR to main
# → Triggers: Full CI pipeline (all quality gates)

# 4. Merge to main
# → Triggers: Full CI + notifications
```

**Production Release:**
```bash
# 1. Ensure main branch is ready
git checkout main
git pull origin main

# 2. Create version tag (triggers complete release pipeline)
git tag v1.2.3
git push origin v1.2.3
# → Triggers: Quality Gates → GitHub Release → CocoaPods/SPM Publishing

# 3. Verify release
# - Check GitHub Releases page
# - Verify CocoaPods package published
# - Confirm SPM package available
# - Confirm all CI jobs passed
```

### 📦 Package Management

**CocoaPods:**
- Automated podspec validation
- Trunk publishing with proper authentication
- Version consistency checks

**Swift Package Manager:**
- Package.swift validation
- Release build verification
- Dependency resolution testing

## License

MIT