# TraceWise Web SDK Implementation Guide
**Repository: `sdk-js` | Expert-Level Implementation**

## 🏗️ Architecture Decision

### Chosen Architecture: **Modular Service Layer with Dependency Injection**

**Why this architecture:**
- **Separation of Concerns**: Each module handles specific domain logic
- **Testability**: Easy to mock dependencies and test in isolation
- **Extensibility**: New modules can be added without affecting existing code
- **Tree-shaking**: Only used modules are bundled in final build
- **Type Safety**: Full TypeScript support with strict typing

### Architecture Components:
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   TraceWiseSDK  │────│   HTTPClient     │────│  RetryManager   │
│   (Facade)      │    │  (Transport)     │    │  (Resilience)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │
         ├── ProductsModule
         ├── EventsModule  
         ├── DppModule
         ├── CirpassModule
         └── AuthModule
```

---

## 🚀 Step-by-Step Implementation

### Step 1: Project Setup (30 minutes)

```bash
# Create project
mkdir tracewise-sdk-js && cd tracewise-sdk-js
npm init -y

# Install dependencies
npm install firebase
npm install -D typescript @types/node tsup jest @types/jest eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin

# Create project structure
mkdir -p src/{modules,utils,types} tests/{unit,integration}
```

### Step 2: Core Configuration (`src/types/index.ts`)

```typescript
export interface SDKConfig {
  baseUrl: string;
  apiKey?: string;
  getFirebaseToken?: () => Promise<string>;
  timeoutMs?: number;
  maxRetries?: number;
  enableCSRF?: boolean;
}

export interface ProductIdentifiers {
  gtin: string;
  serial?: string;
  batch?: string;
  expiry?: string;
}

// Exact method signatures as required by Trello task
export interface ProductParams {
  gtin: string;
  serial?: string;
}

export interface RegisterProductParams {
  userId: string;
  product: Product;
}

export interface LifecycleEventParams {
  gtin: string;
  serial?: string;
  eventType: string;
  timestamp: string;
  details?: Record<string, any>;
}

export interface EventsQueryParams {
  id: string;
  limit?: number;
  pageToken?: string;
}

export interface CirpassQueryParams {
  id: string;
}
```

### Step 3: HTTP Client with Retry Logic (`src/client/HTTPClient.ts`)

```typescript
import { SDKConfig } from '../types';
import { retryWithBackoff } from '../utils/retry';
import { TraceWiseError } from '../errors';

export class HTTPClient {
  private csrfToken?: string;

  constructor(private config: SDKConfig) {}

  private async getHeaders(): Promise<Record<string, string>> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    if (this.config.apiKey) {
      headers['X-API-Key'] = this.config.apiKey;
    }

    if (this.config.getFirebaseToken) {
      const token = await this.config.getFirebaseToken();
      headers['Authorization'] = `Bearer ${token}`;
    }

    return headers;
  }

  private async ensureCSRFToken(): Promise<void> {
    if (!this.config.enableCSRF || this.csrfToken) return;
    
    try {
      const response = await fetch(`${this.config.baseUrl}/v1/csrf-token`, {
        headers: await this.getHeaders()
      });
      const data = await response.json();
      this.csrfToken = data.csrfToken;
    } catch (error) {
      console.warn('Failed to fetch CSRF token:', error);
    }
  }

  async request<T>(
    method: string,
    endpoint: string,
    data?: any,
    options?: { requiresCSRF?: boolean }
  ): Promise<T> {
    const url = `${this.config.baseUrl}${endpoint}`;
    const headers = await this.getHeaders();

    // Add CSRF token for POST/PUT/DELETE requests
    if (options?.requiresCSRF && ['POST', 'PUT', 'DELETE'].includes(method.toUpperCase())) {
      await this.ensureCSRFToken();
      if (this.csrfToken) {
        headers['X-CSRF-Token'] = this.csrfToken;
      }
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

### Step 4: Retry Utility (`src/utils/retry.ts`)

```typescript
export async function retryWithBackoff<T>(
  operation: () => Promise<T>,
  maxRetries: number,
  baseDelay: number = 1000
): Promise<T> {
  let lastError: Error;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error as Error;
      
      // Don't retry on client errors (4xx) except 429
      if (error instanceof TraceWiseError && 
          error.statusCode >= 400 && 
          error.statusCode < 500 && 
          error.statusCode !== 429) {
        throw error;
      }

      if (attempt === maxRetries) break;

      // Exponential backoff with jitter
      const delay = baseDelay * Math.pow(2, attempt) + Math.random() * 1000;
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw lastError!;
}
```

### Step 5: Products Module (`src/modules/ProductsModule.ts`)

```typescript
import { HTTPClient } from '../client/HTTPClient';
import { ProductParams, RegisterProductParams } from '../types';

export class ProductsModule {
  constructor(private client: HTTPClient) {}

  // Exact signature as required by Trello task
  async getProduct(params: ProductParams): Promise<any> {
    const queryParams = new URLSearchParams({ gtin: params.gtin });
    if (params.serial) queryParams.set('serial', params.serial);
    
    return this.client.request('GET', `/v1/products?${queryParams}`);
  }

  // Exact signature as required by Trello task
  async registerProductToUser(params: RegisterProductParams): Promise<void> {
    return this.client.request('POST', '/v1/products/register', {
      userId: params.userId,
      product: params.product
    }, { requiresCSRF: true });
  }

  // Additional methods for complete API coverage
  async listProducts(pagination?: { pageSize?: number; pageToken?: string }) {
    const params = new URLSearchParams();
    if (pagination?.pageSize) params.set('pageSize', pagination.pageSize.toString());
    if (pagination?.pageToken) params.set('pageToken', pagination.pageToken);
    
    const query = params.toString() ? `?${params}` : '';
    return this.client.request('GET', `/v1/products/list${query}`);
  }

  async getUserProducts(userId: string, pagination?: { pageSize?: number; pageToken?: string }) {
    const params = new URLSearchParams();
    if (pagination?.pageSize) params.set('pageSize', pagination.pageSize.toString());
    if (pagination?.pageToken) params.set('pageToken', pagination.pageToken);
    
    const query = params.toString() ? `?${params}` : '';
    return this.client.request('GET', `/v1/products/users/${userId}${query}`);
  }
}
```

### Step 6: Events Module (`src/modules/EventsModule.ts`)

```typescript
import { HTTPClient } from '../client/HTTPClient';
import { LifecycleEventParams, EventsQueryParams } from '../types';

export class EventsModule {
  constructor(private client: HTTPClient) {}

  // Exact signature as required by Trello task
  async addLifecycleEvent(params: LifecycleEventParams): Promise<any> {
    // Convert to EPCIS 2.0 format
    const epcisEvent = {
      gtin: params.gtin,
      serial: params.serial,
      type: 'ObjectEvent',
      action: 'OBSERVE',
      bizStep: params.eventType,
      disposition: 'active',
      when: params.timestamp,
      ...params.details
    };

    return this.client.request('POST', '/v1/events', epcisEvent, { requiresCSRF: true });
  }

  // Exact signature as required by Trello task
  async getProductEvents(params: EventsQueryParams): Promise<any> {
    // Note: API expects gtin/serial in path, but Trello task requires 'id'
    // This is a design decision - we'll treat 'id' as composite "gtin:serial"
    const [gtin, serial] = params.id.split(':');
    
    const queryParams = new URLSearchParams();
    if (params.limit) queryParams.set('pageSize', params.limit.toString());
    if (params.pageToken) queryParams.set('pageToken', params.pageToken);
    
    const query = queryParams.toString() ? `?${query}` : '';
    return this.client.request('GET', `/v1/events/${gtin}/${serial || ''}${query}`);
  }
}
```

### Step 7: CIRPASS Module (`src/modules/CirpassModule.ts`)

```typescript
import { HTTPClient } from '../client/HTTPClient';
import { CirpassQueryParams } from '../types';

export class CirpassModule {
  constructor(private client: HTTPClient) {}

  // Exact signature as required by Trello task
  async getCirpassProduct(params: CirpassQueryParams): Promise<any> {
    return this.client.request('GET', `/v1/cirpass-sim/product/${params.id}`);
  }

  async seedProducts(products: any[]): Promise<any> {
    return this.client.request('POST', '/v1/cirpass-sim/seed', { products }, { requiresCSRF: true });
  }

  async listProducts(limit?: number): Promise<any> {
    const params = limit ? `?limit=${limit}` : '';
    return this.client.request('GET', `/v1/cirpass-sim/products${params}`);
  }
}
```

### Step 8: GS1 Digital Link Parser (`src/utils/digital-link.ts`)

```typescript
import { ProductIdentifiers } from '../types';

export function parseDigitalLink(url: string): ProductIdentifiers {
  // GS1 Digital Link format: https://id.gs1.org/01/{gtin}/21/{serial}
  const gtinMatch = url.match(/\/01\/(\d{14})/);
  const serialMatch = url.match(/\/21\/([^\/\?]+)/);
  const batchMatch = url.match(/\/10\/([^\/\?]+)/);
  const expiryMatch = url.match(/\/17\/(\d{6})/);

  if (!gtinMatch) {
    throw new Error('Invalid GS1 Digital Link: GTIN not found');
  }

  return {
    gtin: gtinMatch[1],
    serial: serialMatch?.[1],
    batch: batchMatch?.[1],
    expiry: expiryMatch?.[1]
  };
}
```

### Step 9: Main SDK Class (`src/index.ts`)

```typescript
import { HTTPClient } from './client/HTTPClient';
import { SDKConfig } from './types';
import { ProductsModule } from './modules/ProductsModule';
import { EventsModule } from './modules/EventsModule';
import { CirpassModule } from './modules/CirpassModule';
import { parseDigitalLink } from './utils/digital-link';

export class TraceWiseSDK {
  private client: HTTPClient;
  
  public readonly products: ProductsModule;
  public readonly events: EventsModule;
  public readonly cirpass: CirpassModule;

  constructor(config: SDKConfig) {
    this.client = new HTTPClient(config);
    
    this.products = new ProductsModule(this.client);
    this.events = new EventsModule(this.client);
    this.cirpass = new CirpassModule(this.client);
  }

  parseDigitalLink = parseDigitalLink;

  // Health check method
  async healthCheck(): Promise<any> {
    return this.client.request('GET', '/v1/health');
  }
}

export default TraceWiseSDK;
export * from './types';
export * from './errors';
```

### Step 10: Build Configuration (`tsup.config.ts`)

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
  external: ['firebase'],
  target: 'es2020',
  outDir: 'dist'
});
```

### Step 11: Package Configuration (`package.json`)

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

## 🧪 Testing Strategy

### Unit Tests (`tests/unit/products.test.ts`)

```typescript
import { ProductsModule } from '../../src/modules/ProductsModule';
import { HTTPClient } from '../../src/client/HTTPClient';

jest.mock('../../src/client/HTTPClient');

describe('ProductsModule', () => {
  let productsModule: ProductsModule;
  let mockClient: jest.Mocked<HTTPClient>;

  beforeEach(() => {
    mockClient = new HTTPClient({} as any) as jest.Mocked<HTTPClient>;
    productsModule = new ProductsModule(mockClient);
  });

  describe('getProduct', () => {
    it('should call client with correct parameters', async () => {
      const mockProduct = { gtin: '1234567890123', name: 'Test Product' };
      mockClient.request.mockResolvedValue(mockProduct);

      const result = await productsModule.getProduct({ 
        gtin: '1234567890123', 
        serial: 'SN123' 
      });

      expect(mockClient.request).toHaveBeenCalledWith(
        'GET', 
        '/v1/products?gtin=1234567890123&serial=SN123'
      );
      expect(result).toEqual(mockProduct);
    });
  });

  describe('registerProductToUser', () => {
    it('should register product with CSRF protection', async () => {
      mockClient.request.mockResolvedValue({ status: 'registered' });

      await productsModule.registerProductToUser({
        userId: 'user123',
        product: { gtin: '1234567890123', name: 'Test Product' }
      });

      expect(mockClient.request).toHaveBeenCalledWith(
        'POST',
        '/v1/products/register',
        {
          userId: 'user123',
          product: { gtin: '1234567890123', name: 'Test Product' }
        },
        { requiresCSRF: true }
      );
    });
  });
});
```

### Integration Tests (`tests/integration/sdk.test.ts`)

```typescript
import TraceWiseSDK from '../../src';

describe('TraceWise SDK Integration', () => {
  let sdk: TraceWiseSDK;

  beforeEach(() => {
    sdk = new TraceWiseSDK({
      baseUrl: 'http://localhost:5001/tracewise-staging/europe-central2/api',
      apiKey: 'test-key',
      enableCSRF: true
    });
  });

  it('should parse GS1 Digital Link correctly', () => {
    const url = 'https://id.gs1.org/01/04012345678905/21/SN123456';
    const result = sdk.parseDigitalLink(url);

    expect(result).toEqual({
      gtin: '04012345678905',
      serial: 'SN123456'
    });
  });

  it('should perform end-to-end product workflow', async () => {
    // This would test against local emulator
    const product = await sdk.products.getProduct({ 
      gtin: '04012345678905', 
      serial: 'SN123456' 
    });
    
    expect(product).toBeDefined();
    expect(product.gtin).toBe('04012345678905');
  });
});
```

---

## 📦 Usage Examples

### Basic Usage

```typescript
import TraceWiseSDK from '@tracewise/sdk-js';
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

// Initialize SDK
const sdk = new TraceWiseSDK({
  baseUrl: 'https://trace-wise.eu/api',
  getFirebaseToken: () => auth.currentUser?.getIdToken() || Promise.resolve(''),
  enableCSRF: true
});

// Parse QR code
const ids = sdk.parseDigitalLink('https://id.gs1.org/01/04012345678905/21/SN123');

// Get product (exact Trello task signature)
const product = await sdk.products.getProduct({ 
  gtin: ids.gtin, 
  serial: ids.serial 
});

// Register product to user (exact Trello task signature)
await sdk.products.registerProductToUser({ 
  userId: 'user123', 
  product: product 
});

// Add lifecycle event (exact Trello task signature)
await sdk.events.addLifecycleEvent({
  gtin: ids.gtin,
  serial: ids.serial,
  eventType: 'purchased',
  timestamp: new Date().toISOString(),
  details: { location: 'Store A' }
});

// Get product events (exact Trello task signature)
const events = await sdk.events.getProductEvents({
  id: `${ids.gtin}:${ids.serial}`,
  limit: 20
});

// Get CIRPASS product (exact Trello task signature)
const cirpassProduct = await sdk.cirpass.getCirpassProduct({ 
  id: 'cirpass-001' 
});
```

---

## 🚀 Deployment

### Build and Test

```bash
npm run build
npm test
npm run lint
```

### Publishing to npm

```bash
npm version patch  # or minor/major
npm publish --access public
```

### CI/CD Pipeline (`.github/workflows/ci.yml`)

```yaml
name: CI/CD

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
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build

  publish:
    if: startsWith(github.ref, 'refs/tags/')
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
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

## ✅ Implementation Checklist

- [ ] **Project Setup** (30 min)
- [ ] **Core Types & Interfaces** (45 min)
- [ ] **HTTP Client with Retry Logic** (60 min)
- [ ] **CSRF Token Handling** (30 min)
- [ ] **Products Module** (45 min)
- [ ] **Events Module** (45 min)
- [ ] **CIRPASS Module** (30 min)
- [ ] **GS1 Digital Link Parser** (30 min)
- [ ] **Main SDK Class** (30 min)
- [ ] **Error Handling** (30 min)
- [ ] **Unit Tests** (120 min)
- [ ] **Integration Tests** (60 min)
- [ ] **Build Configuration** (30 min)
- [ ] **Documentation** (60 min)
- [ ] **CI/CD Pipeline** (45 min)

**Total Estimated Time: 12 hours**

---

## 🎯 Key Architecture Benefits

1. **Modular Design**: Each module is independent and testable
2. **Type Safety**: Full TypeScript support with strict typing
3. **Resilience**: Built-in retry logic with exponential backoff
4. **Security**: CSRF protection for web environments
5. **Performance**: Tree-shaking support for minimal bundle size
6. **Developer Experience**: Exact method signatures as required
7. **Maintainability**: Clear separation of concerns
8. **Extensibility**: Easy to add new modules and features

This architecture ensures the Web SDK is production-ready, maintainable, and provides an excellent developer experience while meeting all the exact requirements from the Trello task.