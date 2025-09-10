# Missing Requirements Analysis & Corrections

## 🚨 Critical Gaps Found in Implementation Guides

After cross-checking all three requirement documents, several critical items were missing from the platform-specific guides:

---

## 📋 Missing from Original Requirements Document

### 1. **Exact Class Structure from Original Specs**
```typescript
// MISSING: Original TracewiseSDK class structure
export default class TracewiseSDK {
  constructor(cfg: { baseUrl: string; apiKey?: string; getToken?: () => Promise<string>; timeoutMs?: number });
  parseDigitalLink(url: string): ProductIDs;
  getProductData(gtin: string, serial?: string): Promise<any>;
  registerProductToUser(userId: string, product: any): Promise<void>;
  submitLifecycleEvent(event: { gtin: string; serial?: string; eventType: string; timestamp: string; details?: any }): Promise<void>;
}
```

### 2. **GS1 Digital Link Parser Specifications**
```typescript
// MISSING: Exact GS1 AI specifications
// `01` GTIN (14 digits), `21` Serial, `10` Batch/Lot, `17` Expiry (YYMMDD)
export function parseDigitalLink(url: string): ProductIDs {
  const gtin = url.match(/\/01\/(\d{14})/)?.[1];
  const serial = url.match(/\/21\/([^\/]+)/)?.[1];
  const batch = url.match(/\/10\/([^\/]+)/)?.[1];
  const expiry = url.match(/\/17\/(\d{6})/)?.[1];
  if (!gtin) throw new Error('Invalid GS1 Digital Link');
  return { gtin, serial, batch, expiry };
}
```

### 3. **API Standards & Conventions**
- **MISSING**: Idempotency-Key support for POST `/lifecycle`
- **MISSING**: Rate limiting headers (`X-RateLimit-Remaining`, `Retry-After`)
- **MISSING**: Error format: `{ "error": { "code": "VALIDATION_ERROR", "message": "gtin is required", "details": { "field": "gtin" } } }`
- **MISSING**: API versioning with `X-API-Version: 1` header

### 4. **CIRPASS-sim Endpoints**
- **MISSING**: `GET /api/cirpass-sim/product/:cirpassId`
- **MISSING**: `POST /api/cirpass-sim/seed` with body `{ "products": [ ... ] }`

---

## 📋 Missing from Trello Task Document

### 1. **Exact Method Signatures (All Platforms)**

#### Web SDK Missing Signatures:
```typescript
// MISSING: Object parameter format
getProduct({ gtin, serial })                    // ✗ Had: getProduct(gtin, serial)
registerProductToUser({ userId, product })      // ✗ Had: registerProductToUser(userId, product)
addLifecycleEvent({ gtin, serial, eventType, timestamp, details })  // ✗ Missing entirely
getProductEvents({ id, limit?, pageToken? })    // ✗ Missing entirely
getCirpassProduct({ id })                       // ✗ Missing entirely
```

#### Android SDK Missing Signatures:
```kotlin
// MISSING: Exact method names
registerProduct(userId: String, product: Product)  // ✗ Had: registerToUser()
addLifecycleEvent(event: LifecycleEvent)           // ✗ Missing entirely
getProductEvents(id: String, limit: Int, pageToken: String?)  // ✗ Missing entirely
getCirpassProduct(id: String)                      // ✗ Missing entirely
```

#### iOS SDK Missing Signatures:
```swift
// MISSING: Exact method names
registerProduct(userId: String, product: Product)  // ✗ Had: registerToUser()
addLifecycleEvent(event: LifecycleEvent)           // ✗ Missing entirely
getProductEvents(id: String, limit: Int, pageToken: String?)  // ✗ Missing entirely
getCirpassProduct(id: String)                      // ✗ Missing entirely
```

### 2. **Subscription Management & Rate Limiting**
- **MISSING**: Free tier vs paid tier implementation
- **MISSING**: Firebase custom claims for tier tracking
- **MISSING**: Usage tracking (productsPerMonth, eventsPerMonth, apiCallsPerMinute)
- **MISSING**: 429 rate limit response handling
- **MISSING**: Quota enforcement at SDK level

### 3. **Repository Names**
- **MISSING**: Exact repository names specified
  - Web: `sdk-js` ✓ (Correct)
  - Android: `tracewise-sdk` ✓ (Correct)  
  - iOS: `TraceWise-iOS` ✓ (Correct)

### 4. **Publishing Requirements**
- **MISSING**: CocoaPods AND Swift Package Manager for iOS
- **MISSING**: Maven Central OR GitHub Packages for Android
- **MISSING**: Semantic versioning enforcement

### 5. **Testing Requirements**
- **MISSING**: Mock responses for offline testing
- **MISSING**: End-to-end tests with rate limiting
- **MISSING**: Automated CI pipelines with manual approval for major releases

---

## 📋 Missing from Development Plan Document

### 1. **API Endpoint Discrepancies**
The development plan shows `/v1/` endpoints, but original requirements show `/api/` endpoints:

**Original Requirements:**
- Base URL: `https://europe-central2-<project>.cloudfunctions.net/api`
- Endpoints: `/api/cirpass-sim/product/:id`

**Development Plan:**
- Base URL: `https://trace-wise.eu/api`
- Endpoints: `/v1/cirpass-sim/product/:id`

### 2. **Missing Core Features**
- **MISSING**: Scanning integration (mentioned in context)
- **MISSING**: Lightweight requirement (bundle size targets)
- **MISSING**: Tree-shakable builds for optimal import size

---

## 🔧 Required Corrections

### Web SDK Corrections:
1. **Add original TracewiseSDK class** alongside modern TraceWiseSDK
2. **Implement exact Trello task signatures** with object parameters
3. **Add CIRPASS-sim endpoints** support
4. **Add idempotency key** generation and handling
5. **Add subscription management** with tier checking
6. **Fix GS1 Digital Link parser** to support all AIs (01, 21, 10, 17)

### Android SDK Corrections:
1. **Add exact method signatures** from Trello task
2. **Implement subscription management** with SharedPreferences
3. **Add CIRPASS support** with proper data models
4. **Add rate limiting handling** with 429 response processing
5. **Fix repository pattern** to include all required endpoints

### iOS SDK Corrections:
1. **Add exact method signatures** from Trello task
2. **Implement subscription management** with Keychain storage
3. **Add CIRPASS support** with Codable models
4. **Add CocoaPods support** alongside Swift Package Manager
5. **Add rate limiting handling** with proper retry logic

### All Platforms:
1. **Add comprehensive error handling** with exact error format
2. **Add idempotency support** for lifecycle events
3. **Add rate limiting** with proper headers and retry logic
4. **Add subscription tier management** with usage tracking
5. **Add offline testing** with mock responses
6. **Add CI/CD pipelines** with manual approval steps

---

## 🎯 Priority Fixes

### High Priority (Must Fix):
1. ✅ **Exact method signatures** from Trello task
2. ✅ **Original class structure** from requirements
3. ✅ **CIRPASS-sim endpoints** implementation
4. ✅ **Subscription management** with rate limiting
5. ✅ **GS1 Digital Link parser** with all AIs

### Medium Priority (Should Fix):
1. ✅ **Idempotency key support**
2. ✅ **Error format standardization**
3. ✅ **Publishing requirements** (CocoaPods + SPM for iOS)
4. ✅ **Testing with mock responses**
5. ✅ **CI/CD with manual approval**

### Low Priority (Nice to Have):
1. ✅ **Bundle size optimization**
2. ✅ **Tree-shaking improvements**
3. ✅ **Advanced caching strategies**
4. ✅ **Performance monitoring**
5. ✅ **Developer experience enhancements**

---

## 📝 Action Items

1. **Update Web SDK Guide** with missing signatures and features
2. **Update Android SDK Guide** with exact method names and subscription management
3. **Update iOS SDK Guide** with CocoaPods support and rate limiting
4. **Add comprehensive testing strategies** across all platforms
5. **Standardize error handling** and response formats
6. **Implement subscription management** with proper tier tracking
7. **Add CIRPASS-sim support** with complete endpoint coverage

**All corrections must maintain backward compatibility while adding the missing functionality.**