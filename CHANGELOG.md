# Changelog

All notable changes to TraceWise iOS SDK will be documented in this file.

## [1.0.0] - 2024-01-XX

### Added
- Initial release of TraceWise iOS SDK
- Firebase Auth integration
- GS1 Digital Link parser (AIs: 01, 21, 10, 17)
- Product management (getProduct, registerProduct)
- Lifecycle events with EPCIS 2.0 compliance
- CIRPASS product support
- Rate limiting with exponential backoff
- Subscription management with Keychain storage
- Swift Package Manager support
- CocoaPods support
- Comprehensive unit tests (>80% coverage)
- SwiftUI and UIKit example applications
- Complete API documentation

### Technical Features
- URLSession-based API client with async/await
- Protocol-oriented architecture
- Thread-safe operations
- Memory-optimized implementation
- Offline caching support
- Comprehensive error handling
- API versioning support
- Idempotency key support
- Correlation ID tracking
- CSRF protection
- Bundle size optimization (<100KB)

### Supported Platforms
- iOS 13.0+
- macOS 10.15+
- watchOS 6.0+
- tvOS 13.0+