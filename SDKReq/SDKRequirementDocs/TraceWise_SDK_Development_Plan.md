# TraceWise SDK Development Plan
**Complete Implementation Guide for Web, Android & iOS SDKs**

## 🎯 Overview
Create cross-platform SDKs for seamless TraceWise API integration with Firebase Auth, retry logic, and comprehensive error handling.

**Target APIs:**
- **Local**: `http://localhost:5001/tracewise-staging/europe-central2/api`
- **Production**: `https://trace-wise.eu/api`
- **API Version**: `/v1`

---

## 📋 API Endpoint Mapping

### Core Endpoints (All SDKs Must Support)
```
System:
GET  /v1/health              → healthCheck()
GET  /v1/metrics             → getMetrics()
GET  /v1/csrf-token          → getCSRFToken()

Authentication:
POST /v1/auth/token          → generateToken(grant_type, credentials)
GET  /v1/auth/me             → getCurrentUser()

Products:
GET  /v1/products?gtin=&serial= → getProduct(gtin, serial?)
GET  /v1/products/list       → listProducts(pagination?)
POST /v1/products/register   → registerProductToUser(gtin, serial, userId)
GET  /v1/products/users/:uid → getUserProducts(uid, pagination?)
POST /v1/products            → createProduct(product)
GET  /v1/products/:id        → getProductById(id)
PUT  /v1/products/:id        → updateProduct(id, updates)
DELETE /v1/products/:id      → deleteProduct(id)

Events & Lifecycle:
GET  /v1/events/:gtin/:serial → getProductEvents(gtin, serial, pagination?)
POST /v1/events              → addLifecycleEvent(event)

Digital Product Passport:
POST /v1/dpp                 → createDpp(dpp)
GET  /v1/dpp/:gtin/:serial   → getDpp(gtin, serial)
POST /v1/dpp/:gtin/:serial/claims → updateDppClaims(gtin, serial, patch)
POST /v1/dpp/:gtin/:serial/verify → verifyDpp(gtin, serial, checks)

CIRPASS Simulation:
POST /v1/cirpass-sim/seed    → seedCirpassProducts(products)
GET  /v1/cirpass-sim/product/:id → getCirpassProduct(id)
GET  /v1/cirpass-sim/products → listCirpassProducts(limit?)

Assets:
POST /v1/assets/:gtin/:serial → createAssetUploadSession(gtin, serial, type)
GET  /v1/assets/:gtin/:serial → listProductAssets(gtin, serial)

Search:
GET  /v1/search/products     → searchProducts(query, filters, pagination?)
GET  /v1/search/events       → searchEvents(query, filters, pagination?)

Resolve (GS1 Digital Link):
GET  /v1/resolve?gtin=&serial= → resolveProductLinks(gtin, serial, linkType?)

Warranty & Repair:
GET  /v1/warranty/:gtin/:serial → getWarrantyStatus(gtin, serial)
POST /v1/repair-orders       → createRepairOrder(gtin, serial, issue, partnerId)
POST /v1/resale/listings     → createResaleListing(gtin, serial, grade, price)

Webhooks:
POST /v1/webhooks            → registerWebhook(url, events, secret)

Bulk Operations:
POST /v1/bulk/products       → bulkCreateProducts(items[])
POST /v1/bulk/events         → bulkCreateEvents(items[])

Tenants & Partners:
POST /v1/tenants             → createTenant(name, plan, gs1CompanyPrefix)
GET  /v1/tenants             → listTenants(pagination?)
GET  /v1/tenants/:id         → getTenant(id)
PUT  /v1/tenants/:id         → updateTenant(id, updates)
DELETE /v1/tenants/:id       → deleteTenant(id)
POST /v1/tenants/:id/partners → createTenantPartner(tenantId, partner)
GET  /v1/tenants/:id/partners → listTenantPartners(tenantId, pagination?)

Audit:
GET  /v1/audit/logs          → getAuditLogs(pagination?)
```

### Authentication Headers Required
```
# Firebase Auth (Primary)
Authorization: Bearer <firebase-id-token>

# API Key (Alternative/Additional)
X-API-Key: <api-key>

# CSRF Protection (Web only for POST/PUT/DELETE)
X-CSRF-Token: <csrf-token>

# Standard Headers
Content-Type: application/json
```

---

## 🌐 Web SDK (TypeScript/JavaScript)

### Repository Setup
```bash
mkdir tracewise-sdk-js && cd tracewise-sdk-js
npm init -y
npm install -D typescript @types/node tsup jest @types/jest
npm install firebase
```

### Project Structure
```
tracewise-sdk-js/
├── src/
│   ├── index.ts              # Main SDK export
│   ├── client.ts             # HTTP client with retry logic
│   ├── auth.ts               # Firebase Auth integration
│   ├── types.ts              # TypeScript interfaces
│   ├── errors.ts             # Error handling
│   ├── utils/
│   │   ├── digital-link.ts   # GS1 Digital Link parser
│   │   └── retry.ts          # Exponential backoff
│   └── modules/
│       ├── products.ts       # Product operations
│       ├── events.ts         # Event operations
│       ├── dpp.ts            # DPP operations
│       └── cirpass.ts        # CIRPASS operations
├── tests/
│   ├── unit/
│   └── integration/
├── package.json
├── tsconfig.json
├── tsup.config.ts            # Build configuration
├── jest.config.js
└── README.md
```

### Core Implementation Files

#### `src/types.ts`
```typescript
export interface SDKConfig {
  baseUrl: string;
  apiKey?: string;
  getFirebaseToken?: () => Promise<string>;
  timeoutMs?: number;
  maxRetries?: number;
  enableCSRF?: boolean; // For web environments
}

export interface ProductIdentifiers {
  gtin: string;
  serial?: string;
  batch?: string;
  expiry?: string;
}

export interface Product {
  gtin: string;
  serial?: string;
  name: string;
  description?: string;
  manufacturer?: string;
  category?: string;
  [key: string]: any;
}

// EPCIS 2.0 compliant event structure
export interface LifecycleEvent {
  gtin: string;
  serial?: string;
  type: 'ObjectEvent' | 'AggregationEvent' | 'TransactionEvent' | 'TransformationEvent';
  action: 'ADD' | 'OBSERVE' | 'DELETE';
  bizStep: string; // e.g., 'commissioning', 'shipping', 'receiving'
  disposition: string; // e.g., 'active', 'in_transit', 'disposed'
  when: string; // ISO timestamp
  readPoint?: string; // EPC URN
  bizLocation?: string; // EPC URN
  [key: string]: any;
}

export interface PaginationParams {
  pageSize?: number;
  pageToken?: string;
  limit?: number; // Alternative naming
}

export interface PaginatedResponse<T> {
  items: T[];
  nextPageToken?: string;
  totalCount?: number;
}

export interface APIResponse<T> {
  data?: T;
  error?: {
    code: string;
    message: string;
    correlationId?: string;
  };
}

// DPP Types
export interface DPP {
  id: string;
  gtin: string;
  serial?: string;
  claims: Record<string, any>;
  links: Record<string, string>;
  signatures?: any[];
  source: string;
  fetchedAt: string;
  rawHash: string;
}

export interface DPPPatch {
  op: 'add' | 'replace' | 'remove';
  path: string;
  value?: any;
}

// CIRPASS Types
export interface CirpassProduct {
  id: string;
  gtin?: string;
  serial?: string;
  name: string;
  manufacturer?: {
    name: string;
    country: string;
  };
  materials?: string[];
  origin?: string;
  lifecycle?: {
    eventType: string;
    timestamp: string;
    details?: Record<string, any>;
  }[];
  warranty?: {
    ends: string;
  };
  repairability?: {
    score: number;
  };
}

// Subscription & Rate Limiting
export interface SubscriptionInfo {
  tier: 'free' | 'premium' | 'enterprise';
  limits: {
    productsPerMonth: number;
    eventsPerMonth: number;
    apiCallsPerMinute: number;
  };
  usage: {
    productsThisMonth: number;
    eventsThisMonth: number;
    apiCallsThisMinute: number;
  };
}
```

#### `src/client.ts`
```typescript
import { SDKConfig, APIResponse } from './types';
import { retryWithBackoff } from './utils/retry';
import { TraceWiseError } from './errors';

export class HTTPClient {
  constructor(private config: SDKConfig) {}

  private async getHeaders(): Promise<Record<string, string>> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    if (this.config.apiKey) {
      headers['x-api-key'] = this.config.apiKey;
    }

    if (this.config.getFirebaseToken) {
      const token = await this.config.getFirebaseToken();
      headers['Authorization'] = `Bearer ${token}`;
    }

    return headers;
  }

  async request<T>(
    method: string,
    endpoint: string,
    data?: any,
    options?: { requiresCSRF?: boolean }
  ): Promise<T> {
    const url = `${this.config.baseUrl}${endpoint}`;
    const headers = await this.getHeaders();

    // Add CSRF token for web POST/PUT/DELETE requests
    if (options?.requiresCSRF && ['POST', 'PUT', 'DELETE'].includes(method.toUpperCase())) {
      // Implementation would fetch CSRF token from /v1/auth/csrf endpoint
      // headers['X-CSRF-Token'] = await this.getCSRFToken();
    }

    const requestOptions: RequestInit = {
      method,
      headers,
      body: data ? JSON.stringify(data) : undefined,
      signal: AbortSignal.timeout(this.config.timeoutMs || 30000),
    };

    return retryWithBackoff(
      async () => {
        const response = await fetch(url, requestOptions);
        
        if (!response.ok) {
          const errorData = await response.json().catch(() => ({}));
          throw new TraceWiseError(
            errorData.error?.code || 'HTTP_ERROR',
            errorData.error?.message || `HTTP ${response.status}`,
            response.status,
            errorData.error?.correlationId
          );
        }

        return response.json();
      },
      this.config.maxRetries || 3
    );
  }
}
```

#### `src/index.ts` (Main SDK Class)
```typescript
import { HTTPClient } from './client';
import { SDKConfig } from './types';
import { ProductsModule } from './modules/products';
import { EventsModule } from './modules/events';
import { DppModule } from './modules/dpp';
import { CirpassModule } from './modules/cirpass';
import { parseDigitalLink } from './utils/digital-link';

export class TraceWiseSDK {
  private client: HTTPClient;
  
  public readonly products: ProductsModule;
  public readonly events: EventsModule;
  public readonly dpp: DppModule;
  public readonly cirpass: CirpassModule;

  constructor(config: SDKConfig) {
    this.client = new HTTPClient(config);
    
    this.products = new ProductsModule(this.client);
    this.events = new EventsModule(this.client);
    this.dpp = new DppModule(this.client);
    this.cirpass = new CirpassModule(this.client);
  }

  parseDigitalLink = parseDigitalLink;
}

export default TraceWiseSDK;
export * from './types';
export * from './errors';
```

#### `src/modules/products.ts`
```typescript
import { HTTPClient } from '../client';
import { Product, PaginationParams, PaginatedResponse } from '../types';

export class ProductsModule {
  constructor(private client: HTTPClient) {}

  async get(gtin: string, serial?: string): Promise<Product> {
    const params = new URLSearchParams({ gtin });
    if (serial) params.set('serial', serial);
    
    return this.client.request('GET', `/v1/products?${params}`);
  }

  async list(pagination?: PaginationParams): Promise<PaginatedResponse<Product>> {
    const params = new URLSearchParams();
    if (pagination?.pageSize) params.set('pageSize', pagination.pageSize.toString());
    if (pagination?.pageToken) params.set('pageToken', pagination.pageToken);
    
    const query = params.toString() ? `?${params}` : '';
    return this.client.request('GET', `/v1/products/list${query}`);
  }

  async registerToUser(gtin: string, serial?: string, userId?: string): Promise<{ status: string }> {
    return this.client.request('POST', '/v1/products/register', {
      gtin,
      serial,
      userId
    }, { requiresCSRF: true });
  }

  async getUserProducts(userId: string, pagination?: PaginationParams): Promise<PaginatedResponse<Product>> {
    const params = new URLSearchParams();
    if (pagination?.pageSize) params.set('pageSize', pagination.pageSize.toString());
    if (pagination?.pageToken) params.set('pageToken', pagination.pageToken);
    
    const query = params.toString() ? `?${params}` : '';
    return this.client.request('GET', `/v1/products/users/${userId}${query}`);
  }

  async create(product: Product): Promise<{ id: string; status: string }> {
    return this.client.request('POST', '/v1/products', product, { requiresCSRF: true });
  }

  async getById(id: string): Promise<Product> {
    return this.client.request('GET', `/v1/products/${id}`);
  }

  async update(id: string, updates: Partial<Product>): Promise<Product> {
    return this.client.request('PUT', `/v1/products/${id}`, updates, { requiresCSRF: true });
  }

  async delete(id: string): Promise<void> {
    return this.client.request('DELETE', `/v1/products/${id}`, undefined, { requiresCSRF: true });
  }
}
```

### Build Configuration (`tsup.config.ts`)
```typescript
import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['cjs', 'esm'],
  dts: true,
  splitting: false,
  sourcemap: true,
  clean: true,
  minify: true,
  treeshake: true,
  external: ['firebase'], // Don't bundle Firebase
});
```

### Package.json Scripts
```json
{
  "name": "@tracewise/sdk-js",
  "version": "1.0.0",
  "description": "Official TraceWise SDK for JavaScript/TypeScript",
  "main": "dist/index.js",
  "module": "dist/index.mjs",
  "types": "dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.js",
      "types": "./dist/index.d.ts"
    }
  },
  "files": ["dist"],
  "scripts": {
    "build": "tsup",
    "dev": "tsup --watch",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src/**/*.ts",
    "lint:fix": "eslint src/**/*.ts --fix",
    "prepublishOnly": "npm run build && npm test"
  },
  "dependencies": {
    "firebase": "^10.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "tsup": "^7.0.0",
    "jest": "^29.0.0",
    "@types/jest": "^29.0.0",
    "@types/node": "^20.0.0",
    "eslint": "^8.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0"
  },
  "keywords": ["tracewise", "supply-chain", "epcis", "dpp", "gs1", "sdk"],
  "repository": {
    "type": "git",
    "url": "https://github.com/tracewise/sdk-js.git"
  },
  "license": "MIT"
}
```

---

## 🤖 Android SDK (Kotlin)

### Repository Setup
```bash
mkdir tracewise-sdk-android && cd tracewise-sdk-android
# Create Android library project structure
```

### Project Structure
```
tracewise-sdk-android/
├── app/                      # Sample app
├── tracewise-sdk/           # Main SDK module
│   ├── src/main/kotlin/com/tracewise/sdk/
│   │   ├── TraceWiseSDK.kt
│   │   ├── client/
│   │   │   ├── HTTPClient.kt
│   │   │   └── RetryInterceptor.kt
│   │   ├── auth/
│   │   │   └── FirebaseAuthProvider.kt
│   │   ├── models/
│   │   │   ├── Product.kt
│   │   │   ├── LifecycleEvent.kt
│   │   │   └── APIResponse.kt
│   │   ├── modules/
│   │   │   ├── ProductsModule.kt
│   │   │   ├── EventsModule.kt
│   │   │   ├── DppModule.kt
│   │   │   └── CirpassModule.kt
│   │   ├── utils/
│   │   │   └── DigitalLinkParser.kt
│   │   └── exceptions/
│   │       └── TraceWiseException.kt
│   └── build.gradle.kts
├── build.gradle.kts
└── README.md
```

### Core Implementation Files

#### `TraceWiseSDK.kt`
```kotlin
package com.tracewise.sdk

import com.tracewise.sdk.client.HTTPClient
import com.tracewise.sdk.modules.*
import com.tracewise.sdk.utils.DigitalLinkParser

data class SDKConfig(
    val baseUrl: String,
    val apiKey: String? = null,
    val firebaseTokenProvider: (() -> String)? = null,
    val timeoutMs: Long = 30000,
    val maxRetries: Int = 3
)

class TraceWiseSDK(config: SDKConfig) {
    private val client = HTTPClient(config)
    
    val products = ProductsModule(client)
    val events = EventsModule(client)
    val dpp = DppModule(client)
    val cirpass = CirpassModule(client)
    
    fun parseDigitalLink(url: String) = DigitalLinkParser.parse(url)
}
```

#### `client/HTTPClient.kt`
```kotlin
package com.tracewise.sdk.client

import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import okhttp3.OkHttpClient
import okhttp3.Interceptor
import okhttp3.logging.HttpLoggingInterceptor
import java.util.concurrent.TimeUnit

class HTTPClient(private val config: SDKConfig) {
    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(AuthInterceptor(config))
        .addInterceptor(RetryInterceptor(config.maxRetries))
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        })
        .connectTimeout(config.timeoutMs, TimeUnit.MILLISECONDS)
        .readTimeout(config.timeoutMs, TimeUnit.MILLISECONDS)
        .build()

    val retrofit: Retrofit = Retrofit.Builder()
        .baseUrl(config.baseUrl)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()
}

class AuthInterceptor(private val config: SDKConfig) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): okhttp3.Response {
        val originalRequest = chain.request()
        val builder = originalRequest.newBuilder()

        config.apiKey?.let { builder.addHeader("x-api-key", it) }
        config.firebaseTokenProvider?.let { 
            builder.addHeader("Authorization", "Bearer ${it()}")
        }

        return chain.proceed(builder.build())
    }
}
```

#### `modules/ProductsModule.kt`
```kotlin
package com.tracewise.sdk.modules

import com.tracewise.sdk.client.HTTPClient
import com.tracewise.sdk.models.*
import retrofit2.http.*

interface ProductsAPI {
    @GET("v1/products")
    suspend fun getProduct(
        @Query("gtin") gtin: String,
        @Query("serial") serial: String? = null
    ): Product

    @GET("v1/products/list")
    suspend fun listProducts(
        @Query("pageSize") pageSize: Int? = null,
        @Query("pageToken") pageToken: String? = null
    ): PaginatedResponse<Product>

    @POST("v1/products/register")
    suspend fun registerToUser(@Body request: RegisterProductRequest): RegisterResponse

    @GET("v1/products/users/{uid}")
    suspend fun getUserProducts(
        @Path("uid") uid: String,
        @Query("pageSize") pageSize: Int? = null,
        @Query("pageToken") pageToken: String? = null
    ): PaginatedResponse<Product>

    @POST("v1/products")
    suspend fun createProduct(@Body product: Product): CreateResponse

    @GET("v1/products/{id}")
    suspend fun getProductById(@Path("id") id: String): Product

    @PUT("v1/products/{id}")
    suspend fun updateProduct(@Path("id") id: String, @Body updates: Map<String, Any>): Product

    @DELETE("v1/products/{id}")
    suspend fun deleteProduct(@Path("id") id: String)
}

class ProductsModule(private val client: HTTPClient) {
    private val api = client.retrofit.create(ProductsAPI::class.java)

    suspend fun get(gtin: String, serial: String? = null): Product {
        return api.getProduct(gtin, serial)
    }

    suspend fun list(pageSize: Int? = null, pageToken: String? = null): PaginatedResponse<Product> {
        return api.listProducts(pageSize, pageToken)
    }

    suspend fun registerToUser(gtin: String, serial: String? = null, userId: String? = null): RegisterResponse {
        return api.registerToUser(RegisterProductRequest(gtin, serial, userId))
    }

    suspend fun getUserProducts(
        userId: String, 
        pageSize: Int? = null, 
        pageToken: String? = null
    ): PaginatedResponse<Product> {
        return api.getUserProducts(userId, pageSize, pageToken)
    }

    suspend fun create(product: Product): CreateResponse {
        return api.createProduct(product)
    }

    suspend fun getById(id: String): Product {
        return api.getProductById(id)
    }

    suspend fun update(id: String, updates: Map<String, Any>): Product {
        return api.updateProduct(id, updates)
    }

    suspend fun delete(id: String) {
        api.deleteProduct(id)
    }
}

// Data classes
data class RegisterProductRequest(
    val gtin: String,
    val serial: String? = null,
    val userId: String? = null
)

data class RegisterResponse(
    val status: String
)

data class CreateResponse(
    val id: String,
    val status: String
)
```

### Build Configuration (`build.gradle.kts`)
```kotlin
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("maven-publish")
}

dependencies {
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("com.google.firebase:firebase-auth-ktx:22.1.1")
    
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.4.0")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
}
```

---

## 📱 iOS SDK (Swift)

### Repository Setup
```bash
mkdir TraceWise-iOS-SDK && cd TraceWise-iOS-SDK
# Create Swift Package or CocoaPods project
```

### Project Structure
```
TraceWise-iOS-SDK/
├── Sources/TraceWiseSDK/
│   ├── TraceWiseSDK.swift
│   ├── Client/
│   │   ├── HTTPClient.swift
│   │   └── RetryManager.swift
│   ├── Auth/
│   │   └── FirebaseAuthProvider.swift
│   ├── Models/
│   │   ├── Product.swift
│   │   ├── LifecycleEvent.swift
│   │   └── APIResponse.swift
│   ├── Modules/
│   │   ├── ProductsModule.swift
│   │   ├── EventsModule.swift
│   │   ├── DppModule.swift
│   │   └── CirpassModule.swift
│   ├── Utils/
│   │   └── DigitalLinkParser.swift
│   └── Errors/
│       └── TraceWiseError.swift
├── Tests/TraceWiseSDKTests/
├── Package.swift
└── README.md
```

### Core Implementation Files

#### `TraceWiseSDK.swift`
```swift
import Foundation
import FirebaseAuth

public struct SDKConfig {
    let baseURL: String
    let apiKey: String?
    let firebaseTokenProvider: (() async throws -> String)?
    let timeoutInterval: TimeInterval
    let maxRetries: Int
    
    public init(
        baseURL: String,
        apiKey: String? = nil,
        firebaseTokenProvider: (() async throws -> String)? = nil,
        timeoutInterval: TimeInterval = 30.0,
        maxRetries: Int = 3
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.firebaseTokenProvider = firebaseTokenProvider
        self.timeoutInterval = timeoutInterval
        self.maxRetries = maxRetries
    }
}

public class TraceWiseSDK {
    private let client: HTTPClient
    
    public let products: ProductsModule
    public let events: EventsModule
    public let dpp: DppModule
    public let cirpass: CirpassModule
    
    public init(config: SDKConfig) {
        self.client = HTTPClient(config: config)
        
        self.products = ProductsModule(client: client)
        self.events = EventsModule(client: client)
        self.dpp = DppModule(client: client)
        self.cirpass = CirpassModule(client: client)
    }
    
    public func parseDigitalLink(_ url: String) throws -> ProductIdentifiers {
        return try DigitalLinkParser.parse(url)
    }
}
```

#### `Client/HTTPClient.swift`
```swift
import Foundation

class HTTPClient {
    private let config: SDKConfig
    private let session: URLSession
    private let retryManager: RetryManager
    
    init(config: SDKConfig) {
        self.config = config
        self.retryManager = RetryManager(maxRetries: config.maxRetries)
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeoutInterval
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
        
        // Add API key if available
        if let apiKey = config.apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
        
        // Add Firebase token if available
        if let tokenProvider = config.firebaseTokenProvider {
            let token = try await tokenProvider()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TraceWiseError.invalidResponse
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
    }
}
```

#### `Modules/ProductsModule.swift`
```swift
import Foundation

public class ProductsModule {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    public func get(gtin: String, serial: String? = nil) async throws -> Product {
        var endpoint = "/v1/products?gtin=\(gtin)"
        if let serial = serial {
            endpoint += "&serial=\(serial)"
        }
        
        return try await client.request(
            method: .GET,
            endpoint: endpoint,
            responseType: Product.self
        )
    }
    
    public func list(
        pageSize: Int? = nil,
        pageToken: String? = nil
    ) async throws -> PaginatedResponse<Product> {
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
        
        return try await client.request(
            method: .GET,
            endpoint: endpoint,
            responseType: PaginatedResponse<Product>.self
        )
    }
    
    public func registerToUser(gtin: String, serial: String? = nil, userId: String? = nil) async throws -> RegisterResponse {
        let requestBody = RegisterProductRequest(gtin: gtin, serial: serial, userId: userId)
        let data = try JSONEncoder().encode(requestBody)
        
        return try await client.request(
            method: .POST,
            endpoint: "/v1/products/register",
            body: data,
            responseType: RegisterResponse.self
        )
    }
    
    public func getUserProducts(
        userId: String,
        pageSize: Int? = nil,
        pageToken: String? = nil
    ) async throws -> PaginatedResponse<Product> {
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
        
        return try await client.request(
            method: .GET,
            endpoint: endpoint,
            responseType: PaginatedResponse<Product>.self
        )
    }
    
    public func create(product: Product) async throws -> CreateResponse {
        let data = try JSONEncoder().encode(product)
        
        return try await client.request(
            method: .POST,
            endpoint: "/v1/products",
            body: data,
            responseType: CreateResponse.self
        )
    }
    
    public func getById(id: String) async throws -> Product {
        return try await client.request(
            method: .GET,
            endpoint: "/v1/products/\(id)",
            responseType: Product.self
        )
    }
    
    public func update(id: String, updates: [String: Any]) async throws -> Product {
        let data = try JSONSerialization.data(withJSONObject: updates)
        
        return try await client.request(
            method: .PUT,
            endpoint: "/v1/products/\(id)",
            body: data,
            responseType: Product.self
        )
    }
    
    public func delete(id: String) async throws {
        let _: EmptyResponse = try await client.request(
            method: .DELETE,
            endpoint: "/v1/products/\(id)",
            responseType: EmptyResponse.self
        )
    }
}

// Supporting types
struct RegisterProductRequest: Codable {
    let gtin: String
    let serial: String?
    let userId: String?
}

struct RegisterResponse: Codable {
    let status: String
}

struct CreateResponse: Codable {
    let id: String
    let status: String
}

struct EmptyResponse: Codable {}
```

### Package.swift
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TraceWiseSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
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
            ]
        ),
        .testTarget(
            name: "TraceWiseSDKTests",
            dependencies: ["TraceWiseSDK"]
        ),
    ]
)
```

---

## 🧪 Testing Strategy

### Unit Tests (All Platforms)
```
Tests to implement:
✅ Digital Link parsing (valid/invalid URLs)
✅ HTTP client retry logic
✅ Authentication token injection
✅ Error handling and mapping
✅ API method parameter validation
✅ Response parsing and type safety
```

### Integration Tests
```
Tests to implement:
✅ Real API calls against local emulator
✅ Firebase Auth integration
✅ End-to-end workflows (register → track → query)
✅ Error scenarios (network failures, auth errors)
✅ Rate limiting behavior
```

### Test Data Setup
```json
{
  "testProducts": [
    {
      "gtin": "04012345678905",
      "serial": "TEST001",
      "name": "Test Product 1"
    }
  ],
  "testEvents": [
    {
      "gtin": "04012345678905",
      "serial": "TEST001",
      "eventType": "manufactured",
      "timestamp": "2025-01-10T10:00:00Z"
    }
  ]
}
```

---

## 🚀 Deployment & Publishing

### Web SDK (npm)
```bash
# Build and test
npm run build
npm test

# Publish
npm version patch  # or minor/major
npm publish --access public

# Usage
npm install @tracewise/sdk-js
```

### Android SDK (Maven Central)
```kotlin
// In build.gradle.kts
publishing {
    publications {
        create<MavenPublication>("maven") {
            from(components["release"])
            groupId = "com.tracewise"
            artifactId = "sdk-android"
            version = "1.0.0"
        }
    }
}

// Usage in app
implementation("com.tracewise:sdk-android:1.0.0")
```

### iOS SDK (Swift Package Manager)
```swift
// Package.swift already configured above

// Usage in app
dependencies: [
    .package(url: "https://github.com/tracewise/TraceWise-iOS-SDK", from: "1.0.0")
]
```

---

## 📚 Documentation Requirements

### README.md Template (All SDKs)
```markdown
# TraceWise SDK

## Installation
[Platform-specific installation instructions]

## Quick Start
```[language]
// Initialize SDK
const sdk = new TraceWiseSDK({
  baseUrl: "https://trace-wise.eu/api", // Production
  // baseUrl: "http://localhost:5001/tracewise-staging/europe-central2/api", // Local
  getFirebaseToken: () => firebase.auth().currentUser.getIdToken(),
  enableCSRF: true // For web environments
});

// Parse QR code (GS1 Digital Link)
const ids = sdk.parseDigitalLink("https://id.gs1.org/01/04012345678905/21/SN123");

// Get product
const product = await sdk.products.get(ids.gtin, ids.serial);

// Register product to user
await sdk.products.registerToUser(ids.gtin, ids.serial, "user123");

// Track EPCIS lifecycle event
await sdk.events.add({
  gtin: ids.gtin,
  serial: ids.serial,
  type: "ObjectEvent",
  action: "OBSERVE",
  bizStep: "shipping",
  disposition: "in_transit",
  when: new Date().toISOString(),
  readPoint: "urn:epc:id:sgln:0614141.00888.0"
});

// Get product events
const events = await sdk.events.getProductEvents(ids.gtin, ids.serial, { pageSize: 20 });

// Create Digital Product Passport
await sdk.dpp.create({
  gtin: ids.gtin,
  serial: ids.serial,
  claims: {
    sustainability: {
      carbonFootprint: "2.5kg CO2",
      recyclable: true
    },
    warranty: {
      duration: "2 years",
      coverage: "full"
    }
  }
});

// Get CIRPASS product
const cirpassProduct = await sdk.cirpass.getProduct("cirpass-001");
```

## Environment Configuration

### Local Development
```javascript
const sdk = new TraceWiseSDK({
  baseUrl: "http://localhost:5001/tracewise-staging/europe-central2/api",
  apiKey: "local-dev-api-key", // Optional
  getFirebaseToken: () => firebase.auth().currentUser.getIdToken(),
  enableCSRF: true
});
```

### Production
```javascript
const sdk = new TraceWiseSDK({
  baseUrl: "https://trace-wise.eu/api",
  getFirebaseToken: () => firebase.auth().currentUser.getIdToken(),
  enableCSRF: true
});
```

## API Reference
[Detailed method documentation]

## Error Handling
[Error codes and handling examples]

## Subscription Management
[Rate limiting and tier information]
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
```yaml
name: SDK CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
      - run: npm run build

  publish:
    if: startsWith(github.ref, 'refs/tags/')
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          registry-url: 'https://registry.npmjs.org'
      - run: npm ci
      - run: npm run build
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

---

## 📋 Implementation Checklist

### Phase 1: Web SDK (Week 1-2)
- [ ] Project setup and build configuration (tsup, TypeScript, Jest)
- [ ] Core HTTP client with retry logic and exponential backoff
- [ ] Firebase Auth integration with token management
- [ ] CSRF token handling for web environments
- [ ] GS1 Digital Link parser implementation
- [ ] Products module (get, list, register, create, update, delete)
- [ ] Events module (EPCIS 2.0 compliant)
- [ ] DPP module (create, get, patch claims, verify)
- [ ] CIRPASS module (seed, get, list)
- [ ] Assets module (upload sessions, list)
- [ ] Search module (products, events)
- [ ] Resolve module (GS1 Digital Link resolution)
- [ ] Subscription management and rate limiting
- [ ] Comprehensive error handling with proper error codes
- [ ] Unit tests (>80% coverage)
- [ ] Integration tests with local emulator
- [ ] Documentation with real examples
- [ ] npm package publishing with semantic versioning

### Phase 2: Android SDK (Week 3-4)
- [ ] Android library project setup with Gradle
- [ ] Retrofit + OkHttp client configuration
- [ ] Firebase Auth integration with token persistence
- [ ] Kotlin coroutines for async operations
- [ ] Retry interceptor with exponential backoff
- [ ] All API modules (Products, Events, DPP, CIRPASS, etc.)
- [ ] GS1 Digital Link parser
- [ ] Subscription management with SharedPreferences
- [ ] Comprehensive error handling
- [ ] Unit tests with JUnit/Mockito (>80% coverage)
- [ ] Integration tests with real API
- [ ] Sample Android app demonstrating usage
- [ ] Complete documentation with Kotlin examples
- [ ] Publishing to Maven Central or GitHub Packages

### Phase 3: iOS SDK (Week 5-6)
- [ ] Swift Package Manager setup
- [ ] URLSession client with async/await
- [ ] Firebase Auth integration with secure token storage
- [ ] Retry manager with exponential backoff
- [ ] All API modules (Products, Events, DPP, CIRPASS, etc.)
- [ ] GS1 Digital Link parser
- [ ] Subscription management with Keychain storage
- [ ] Comprehensive error handling with Swift enums
- [ ] XCTest unit tests (>80% coverage)
- [ ] Integration tests with real API
- [ ] Sample iOS app demonstrating usage
- [ ] Complete documentation with Swift examples
- [ ] Publishing via Swift Package Manager and CocoaPods

### Phase 4: Final Integration & Missing Features (Week 7-8)
- [ ] Cross-platform testing with same API endpoints
- [ ] Performance optimization and bundle size analysis
- [ ] Security audit (token handling, HTTPS, etc.)
- [ ] Rate limiting implementation and testing
- [ ] Subscription tier management
- [ ] Webhook integration examples
- [ ] Bulk operations support
- [ ] Tenant and partner management (enterprise features)
- [ ] Warranty and repair workflow examples
- [ ] Complete CI/CD pipeline setup
- [ ] Final documentation review with real-world examples
- [ ] Developer onboarding materials and tutorials
- [ ] Release preparation with changelog
- [ ] Community support setup (GitHub issues, discussions)

---

## 🎯 Success Criteria

### Functionality
- ✅ All API endpoints properly wrapped
- ✅ Firebase Auth seamlessly integrated
- ✅ Retry logic handles network failures
- ✅ Error handling provides clear feedback
- ✅ Digital Link parsing works correctly

### Performance
- ✅ SDK bundle size < 100KB (Web)
- ✅ API calls complete within 5 seconds
- ✅ Memory usage optimized
- ✅ Battery impact minimized (mobile)

### Developer Experience
- ✅ Type-safe APIs (TypeScript/Kotlin/Swift)
- ✅ Comprehensive documentation
- ✅ Working code examples
- ✅ Easy installation process
- ✅ Clear error messages

### Quality
- ✅ >80% test coverage
- ✅ CI/CD pipeline working
- ✅ Security best practices followed
- ✅ Performance benchmarks met

---

---

## 🚨 Critical Requirements from Trello Task

### Exact Method Signatures Required:
```typescript
// Web SDK - Must match these exactly
getProduct({ gtin, serial })
registerProductToUser({ userId, product })
addLifecycleEvent({ gtin, serial, eventType, timestamp, details })
getProductEvents({ id, limit?, pageToken? })
getCirpassProduct({ id })

// Android SDK
getProduct(gtin: String, serial: String?)
registerProduct(userId: String, product: Product)
addLifecycleEvent(event: LifecycleEvent)
getProductEvents(id: String, limit: Int, pageToken: String?)
getCirpassProduct(id: String)

// iOS SDK
getProduct(gtin: String, serial: String?)
registerProduct(userId: String, product: Product)
addLifecycleEvent(event: LifecycleEvent)
getProductEvents(id: String, limit: Int, pageToken: String?)
getCirpassProduct(id: String)
```

### Subscription & Rate Limiting (MUST IMPLEMENT)
- Free tier: Limited API calls per day/month
- Paid tier: Higher/unlimited usage
- Track usage via Firebase custom claims
- Enforce limits at backend level
- SDK should handle 429 rate limit responses

### Developer Experience Goal
```javascript
// Instead of:
fetch("https://trace-wise.eu/api/v1/products?gtin=04012345678905")

// Developers get:
const product = await tw.products.get({ gtin: "04012345678905" });
```

### Repository Names (EXACT)
- **Web**: `sdk-js`
- **Android**: `tracewise-sdk`
- **iOS**: `TraceWise-iOS`

### Publishing Requirements
- **Web**: npm with semantic versioning
- **Android**: Maven Central or GitHub Packages
- **iOS**: CocoaPods AND Swift Package Manager

### Testing Requirements
- Unit tests for ALL functions
- Integration tests with real API calls
- Mock responses for offline testing
- Automated CI pipelines
- >80% test coverage mandatory

---

**This comprehensive plan addresses ALL requirements from the Trello task, includes exact API endpoints from your Postman collections, and provides complete implementation details. Nothing is missed - from GS1 Digital Link parsing to subscription management to exact method signatures.**