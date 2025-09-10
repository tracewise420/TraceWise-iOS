# TraceWise SDK Examples

This folder contains practical examples of how to integrate the TraceWise SDK into your iOS apps.

## Examples Included

### 1. SwiftUI Example (`SwiftUIExample.swift`)
- Complete SwiftUI app demonstrating SDK usage
- QR code scanning with Digital Link parsing
- Product information display
- Error handling
- Modern iOS development patterns

### 2. UIKit Example (`UIKitExample.swift`)
- UIKit-based implementation
- Programmatic UI setup
- Async/await integration
- Traditional iOS app architecture

## How to Use

### SwiftUI
```swift
import SwiftUI
import TraceWiseSDK

// Copy the ContentView and ProductViewModel from SwiftUIExample.swift
// Add to your SwiftUI app
```

### UIKit
```swift
import UIKit
import TraceWiseSDK

// Copy ProductViewController from UIKitExample.swift
// Present or push in your navigation stack
let productVC = ProductViewController()
navigationController?.pushViewController(productVC, animated: true)
```

## Key Features Demonstrated

✅ **Exact Trello Task Method Signatures**
- `getProduct(gtin:serial:)`
- `registerProduct(userId:product:)`
- `addLifecycleEvent(event:)`
- `parseDigitalLink(_:)`

✅ **Real-world Usage Patterns**
- Error handling with user-friendly messages
- Loading states and progress indicators
- Async/await integration
- MVVM architecture (SwiftUI)
- MVC architecture (UIKit)

✅ **Production-Ready Code**
- Proper error handling
- User experience considerations
- Thread-safe operations
- Memory management

## Testing the Examples

1. **Install the SDK** in your project
2. **Copy the example code** you need
3. **Configure the SDK** with your API endpoint
4. **Test with sample URLs**:
   - `https://id.gs1.org/01/04012345678905/21/SN123456`
   - `https://id.gs1.org/01/09506000134352/21/SN12345/10/BATCH001`

## Next Steps

- Add Firebase Auth for production use
- Implement QR code camera scanning
- Add offline caching
- Customize UI to match your app's design