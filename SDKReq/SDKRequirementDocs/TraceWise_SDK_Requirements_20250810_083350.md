
# TraceWise SDK Requirements (Web • Android • iOS)

## 1) Context
Developer-facing SDKs to integrate scanning, GS1 Digital Link parsing, and API calls. Must be lightweight, typed, and documented with examples.

## 2) Architecture
- **Core:** config, auth headers, HTTP client with retry/backoff, error types, Digital Link parser, API wrappers.
- **Web (TypeScript):** fetch API, ESM build, npm-ready.
- **Android (Kotlin):** OkHttp + Coroutines, Maven/JitPack-ready.
- **iOS (Swift):** URLSession + async/await, Swift Package Manager.

## 3) Public Surface (Web TS)
```ts
type ProductIDs = { gtin: string; serial?: string; batch?: string; expiry?: string };

export default class TracewiseSDK {
  constructor(cfg: { baseUrl: string; apiKey?: string; getToken?: () => Promise<string>; timeoutMs?: number });
  parseDigitalLink(url: string): ProductIDs;
  getProductData(gtin: string, serial?: string): Promise<any>;
  registerProductToUser(userId: string, product: any): Promise<void>;
  submitLifecycleEvent(event: { gtin: string; serial?: string; eventType: string; timestamp: string; details?: any }): Promise<void>;
}
```

### Digital Link Parser (GS1 AIs)
- `01` GTIN (14 digits), `21` Serial, `10` Batch/Lot, `17` Expiry (YYMMDD).

**Parser (TS)**
```ts
export function parseDigitalLink(url: string): ProductIDs {
  const gtin = url.match(/\/01\/(\d{14})/)?.[1];
  const serial = url.match(/\/21\/([^\/]+)/)?.[1];
  if (!gtin) throw new Error('Invalid GS1 Digital Link');
  return { gtin, serial };
}
```

**HTTP Calls (TS)**
```ts
class TracewiseSDK {
  constructor(private cfg: { baseUrl: string; apiKey?: string; getToken?: () => Promise<string> }){}
  private async headers() {
    const h: any = { 'Content-Type': 'application/json' };
    if (this.cfg.apiKey) h['x-api-key'] = this.cfg.apiKey;
    if (this.cfg.getToken) h['Authorization'] = 'Bearer ' + await this.cfg.getToken();
    return h;
  }
  async getProductData(gtin: string, serial?: string) {
    const u = new URL(this.cfg.baseUrl + '/product');
    u.searchParams.set('gtin', gtin); if (serial) u.searchParams.set('serial', serial);
    const r = await fetch(u.toString(), { headers: await this.headers() });
    if (!r.ok) throw new Error('HTTP ' + r.status);
    return r.json();
  }
  async registerProductToUser(userId: string, product: any) {
    const r = await fetch(this.cfg.baseUrl + '/user/register', { method: 'POST', headers: await this.headers(), body: JSON.stringify({ userId, product }) });
    if (!r.ok) throw new Error('HTTP ' + r.status);
  }
  async submitLifecycleEvent(ev: any) {
    const r = await fetch(this.cfg.baseUrl + '/lifecycle', { method: 'POST', headers: await this.headers(), body: JSON.stringify(ev) });
    if (!r.ok) throw new Error('HTTP ' + r.status);
  }
}
```

### Android / iOS Sketches
**Kotlin**
```kotlin
data class ProductIDs(val gtin: String, val serial: String? = null)

class TracewiseSdk(private val baseUrl: String, private val apiKey: String? = null) {
  private val client = OkHttpClient()

  fun parseDigitalLink(url: String): ProductIDs {
    val gtin = Regex("/01/(\d{14})").find(url)?.groupValues?.get(1)
      ?: throw IllegalArgumentException("Invalid GS1 Digital Link")
    val serial = Regex("/21/([^/]+)").find(url)?.groupValues?.get(1)
    return ProductIDs(gtin, serial)
  }
}
```

**Swift**
```swift
struct ProductIDs { let gtin: String; let serial: String? }
```

## 4) Examples (Web)
```ts
const ids = sdk.parseDigitalLink('https://id.gs1.org/01/09506000134352/21/SN12345');
const product = await sdk.getProductData(ids.gtin, ids.serial);
await sdk.registerProductToUser('user_123', { gtin: ids.gtin, serial: ids.serial, purchaseDate: '2025-08-10' });
await sdk.submitLifecycleEvent({
  gtin: ids.gtin, serial: ids.serial, eventType: 'repair_completed',
  timestamp: new Date().toISOString(), details: { shop: 'RepairCo' }
});
```


## API Standards & Conventions

- **Prod Base URL:** `https://europe-central2-<project>.cloudfunctions.net/api`
- **Local (Emulator):** `http://localhost:5001/<project>/europe-central2/api`
- **Versioning:** Reserve `/v1/...`. MVP uses `/api/...` (+ optional `X-API-Version: 1`).
- **Content-Type:** `application/json; charset=utf-8`.
- **Authentication:** `x-api-key: <key>` header for server-to-server; optional `Authorization: Bearer <firebase-id-token>` (when the app signs in users).
- **CORS:** Allow-list known origins only (landing, docs, demo app, partners).
- **HTTP Statuses:** 200/201 (success), 400 (validation), 401/403 (auth), 404 (not found), 409 (conflict), 422 (semantic validation), 429 (rate limit), 5xx (server).
- **Idempotency:** Support `Idempotency-Key` on POST `/lifecycle` to avoid duplicates on retry.
- **Rate Limits:** Per API key (MVP static); future headers `X-RateLimit-Remaining`, `Retry-After`.
- **Pagination (future):** `limit`, `cursor` query params; response contains `next_cursor`.
- **Errors (canonical shape):**
```json
{ "error": { "code": "VALIDATION_ERROR", "message": "gtin is required", "details": { "field": "gtin" } } }
```

## CIRPASS-style Examples (Simulated)

Public CIRPASS endpoints aren’t generally available. The MVP ships **CIRPASS-sim** endpoints that mirror expected payloads for testing.

### Example Product Passport JSON
```json
{
  "id": "cirpass:eu:demo:GTIN09506000134352:SN12345",
  "gtin": "09506000134352",
  "serial": "SN12345",
  "name": "EcoSmart Kettle 1.7L",
  "manufacturer": { "name": "Example Appliances GmbH", "country": "DE" },
  "materials": ["Stainless Steel", "PP", "Silicone"],
  "origin": "CN",
  "lifecycle": [
    { "eventType": "manufactured", "timestamp": "2025-05-11T10:22:00Z" },
    { "eventType": "ownership_transferred", "timestamp": "2025-07-19T14:10:00Z", "details": { "country": "RO" } }
  ],
  "warranty": { "ends": "2027-05-11" },
  "repairability": { "score": 7.6 }
}
```

### CIRPASS-sim Endpoints (MVP)
- `GET /api/cirpass-sim/product/:cirpassId`
- `POST /api/cirpass-sim/seed` with body `{ "products": [ ... ] }`

## 5) Packaging
- **Web:** ESM build + `.d.ts`; later `npm publish`.
- **Android:** `publishToMavenLocal`; JitPack (tagged releases).
- **iOS:** Swift Package; import in sample app to verify.

## 6) Tasks (SDK)
- [ ] Core config & headers
- [ ] Digital Link parser
- [ ] API wrappers (3 endpoints)
- [ ] Error handling & retries
- [ ] Unit tests + README + examples
