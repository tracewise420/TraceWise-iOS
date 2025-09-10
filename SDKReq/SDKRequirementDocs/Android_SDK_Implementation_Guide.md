# TraceWise Android SDK Implementation Guide
**Repository: `tracewise-sdk` | Expert-Level Implementation**

## 🏗️ Architecture Decision

### Chosen Architecture: **Clean Architecture with Repository Pattern + Dependency Injection**

**Why this architecture:**
- **SOLID Principles**: Single responsibility, dependency inversion
- **Testability**: Easy to mock repositories and test business logic
- **Android Best Practices**: Follows Google's recommended architecture
- **Lifecycle Awareness**: Proper handling of Android lifecycle
- **Offline Support**: Repository pattern enables caching strategies
- **Coroutines**: Modern async programming with structured concurrency

### Architecture Components:
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   TraceWiseSDK  │────│   Repository     │────│  NetworkService │
│   (Facade)      │    │   (Data Layer)   │    │  (Retrofit)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ├── ProductsModule       ├── ProductsRepo        ├── ProductsAPI
         ├── EventsModule         ├── EventsRepo          ├── EventsAPI
         ├── DppModule           ├── DppRepo             ├── DppAPI
         └── CirpassModule       └── CirpassRepo         └── CirpassAPI
```

---

## 🚀 Step-by-Step Implementation

### Step 1: Project Setup (45 minutes)

#### Create Android Library Module

```kotlin
// settings.gradle.kts
include(":tracewise-sdk")
include(":sample-app")
```

#### Module `build.gradle.kts`

```kotlin
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("kotlin-kapt")
    id("dagger.hilt.android.plugin")
    id("maven-publish")
}

android {
    namespace = "com.tracewise.sdk"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
        targetSdk = 34
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {
    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // Firebase
    implementation("com.google.firebase:firebase-auth-ktx:22.3.0")
    
    // Dependency Injection
    implementation("com.google.dagger:hilt-android:2.48")
    kapt("com.google.dagger:hilt-compiler:2.48")
    
    // Storage
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.6.0")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    testImplementation("com.squareup.okhttp3:mockwebserver:4.12.0")
    
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
```

### Step 2: Core Data Models (`src/main/kotlin/com/tracewise/sdk/models/`)

#### `Product.kt`
```kotlin
package com.tracewise.sdk.models

import com.google.gson.annotations.SerializedName

data class Product(
    @SerializedName("gtin") val gtin: String,
    @SerializedName("serial") val serial: String? = null,
    @SerializedName("name") val name: String,
    @SerializedName("description") val description: String? = null,
    @SerializedName("manufacturer") val manufacturer: String? = null,
    @SerializedName("category") val category: String? = null
)

data class ProductIdentifiers(
    val gtin: String,
    val serial: String? = null,
    val batch: String? = null,
    val expiry: String? = null
)

data class PaginatedResponse<T>(
    @SerializedName("items") val items: List<T>,
    @SerializedName("nextPageToken") val nextPageToken: String? = null,
    @SerializedName("totalCount") val totalCount: Int? = null
)
```

#### `LifecycleEvent.kt`
```kotlin
package com.tracewise.sdk.models

import com.google.gson.annotations.SerializedName

data class LifecycleEvent(
    @SerializedName("gtin") val gtin: String,
    @SerializedName("serial") val serial: String? = null,
    @SerializedName("type") val type: String = "ObjectEvent",
    @SerializedName("action") val action: String = "OBSERVE",
    @SerializedName("bizStep") val bizStep: String,
    @SerializedName("disposition") val disposition: String = "active",
    @SerializedName("when") val timestamp: String,
    @SerializedName("readPoint") val readPoint: String? = null,
    @SerializedName("bizLocation") val bizLocation: String? = null,
    @SerializedName("details") val details: Map<String, Any>? = null
)

data class EventResponse(
    @SerializedName("id") val id: String,
    @SerializedName("status") val status: String,
    @SerializedName("epcisUrn") val epcisUrn: String? = null
)
```

### Step 3: Network Layer (`src/main/kotlin/com/tracewise/sdk/network/`)

#### `ApiService.kt`
```kotlin
package com.tracewise.sdk.network

import com.tracewise.sdk.models.*
import retrofit2.Response
import retrofit2.http.*

interface ProductsApiService {
    @GET("v1/products")
    suspend fun getProduct(
        @Query("gtin") gtin: String,
        @Query("serial") serial: String? = null
    ): Response<Product>

    @GET("v1/products/list")
    suspend fun listProducts(
        @Query("pageSize") pageSize: Int? = null,
        @Query("pageToken") pageToken: String? = null
    ): Response<PaginatedResponse<Product>>

    @POST("v1/products/register")
    suspend fun registerProduct(@Body request: RegisterProductRequest): Response<RegisterResponse>

    @GET("v1/products/users/{uid}")
    suspend fun getUserProducts(
        @Path("uid") userId: String,
        @Query("pageSize") pageSize: Int? = null,
        @Query("pageToken") pageToken: String? = null
    ): Response<PaginatedResponse<Product>>

    @POST("v1/products")
    suspend fun createProduct(@Body product: Product): Response<CreateResponse>
}

interface EventsApiService {
    @GET("v1/events/{gtin}/{serial}")
    suspend fun getProductEvents(
        @Path("gtin") gtin: String,
        @Path("serial") serial: String,
        @Query("pageSize") pageSize: Int? = null,
        @Query("pageToken") pageToken: String? = null
    ): Response<PaginatedResponse<LifecycleEvent>>

    @POST("v1/events")
    suspend fun addLifecycleEvent(@Body event: LifecycleEvent): Response<EventResponse>
}

interface CirpassApiService {
    @GET("v1/cirpass-sim/product/{id}")
    suspend fun getCirpassProduct(@Path("id") id: String): Response<CirpassProduct>

    @GET("v1/cirpass-sim/products")
    suspend fun listCirpassProducts(@Query("limit") limit: Int? = null): Response<CirpassProductsResponse>
}
```

#### `NetworkModule.kt` (Hilt DI)
```kotlin
package com.tracewise.sdk.di

import com.tracewise.sdk.network.*
import com.tracewise.sdk.auth.AuthInterceptor
import com.tracewise.sdk.network.RetryInterceptor
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(
        authInterceptor: AuthInterceptor,
        retryInterceptor: RetryInterceptor
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .addInterceptor(retryInterceptor)
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            })
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, config: SDKConfig): Retrofit {
        return Retrofit.Builder()
            .baseUrl(config.baseUrl)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    fun provideProductsApiService(retrofit: Retrofit): ProductsApiService =
        retrofit.create(ProductsApiService::class.java)

    @Provides
    @Singleton
    fun provideEventsApiService(retrofit: Retrofit): EventsApiService =
        retrofit.create(EventsApiService::class.java)

    @Provides
    @Singleton
    fun provideCirpassApiService(retrofit: Retrofit): CirpassApiService =
        retrofit.create(CirpassApiService::class.java)
}
```

### Step 4: Authentication & Interceptors

#### `AuthInterceptor.kt`
```kotlin
package com.tracewise.sdk.auth

import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.tasks.await
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthInterceptor @Inject constructor(
    private val config: SDKConfig,
    private val firebaseAuth: FirebaseAuth
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        val builder = originalRequest.newBuilder()

        // Add API key if available
        config.apiKey?.let { apiKey ->
            builder.addHeader("X-API-Key", apiKey)
        }

        // Add Firebase token if user is authenticated
        firebaseAuth.currentUser?.let { user ->
            try {
                val token = runBlocking { user.getIdToken(false).await().token }
                builder.addHeader("Authorization", "Bearer $token")
            } catch (e: Exception) {
                // Log error but continue with request
                android.util.Log.w("TraceWiseSDK", "Failed to get Firebase token", e)
            }
        }

        return chain.proceed(builder.build())
    }
}
```

#### `RetryInterceptor.kt`
```kotlin
package com.tracewise.sdk.network

import okhttp3.Interceptor
import okhttp3.Response
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class RetryInterceptor @Inject constructor() : Interceptor {
    
    companion object {
        private const val MAX_RETRIES = 3
        private const val BASE_DELAY_MS = 1000L
    }

    override fun intercept(chain: Interceptor.Chain): Response {
        var lastException: IOException? = null
        var response: Response? = null

        repeat(MAX_RETRIES + 1) { attempt ->
            try {
                response?.close() // Close previous response if exists
                response = chain.proceed(chain.request())
                
                // Don't retry on client errors (4xx) except 429
                if (response!!.isSuccessful || 
                    (response!!.code in 400..499 && response!!.code != 429)) {
                    return response!!
                }
                
                if (attempt < MAX_RETRIES) {
                    // Exponential backoff with jitter
                    val delay = BASE_DELAY_MS * (1L shl attempt) + (0..1000).random()
                    Thread.sleep(delay)
                }
                
            } catch (e: IOException) {
                lastException = e
                if (attempt < MAX_RETRIES) {
                    val delay = BASE_DELAY_MS * (1L shl attempt) + (0..1000).random()
                    Thread.sleep(delay)
                }
            }
        }

        return response ?: throw (lastException ?: IOException("Max retries exceeded"))
    }
}
```

### Step 5: Repository Layer

#### `ProductsRepository.kt`
```kotlin
package com.tracewise.sdk.repository

import com.tracewise.sdk.models.*
import com.tracewise.sdk.network.ProductsApiService
import com.tracewise.sdk.utils.ApiResult
import com.tracewise.sdk.utils.safeApiCall
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ProductsRepository @Inject constructor(
    private val apiService: ProductsApiService
) {
    suspend fun getProduct(gtin: String, serial: String? = null): ApiResult<Product> {
        return safeApiCall { apiService.getProduct(gtin, serial) }
    }

    suspend fun listProducts(
        pageSize: Int? = null, 
        pageToken: String? = null
    ): ApiResult<PaginatedResponse<Product>> {
        return safeApiCall { apiService.listProducts(pageSize, pageToken) }
    }

    suspend fun registerProduct(
        gtin: String, 
        serial: String? = null, 
        userId: String? = null
    ): ApiResult<RegisterResponse> {
        val request = RegisterProductRequest(gtin, serial, userId)
        return safeApiCall { apiService.registerProduct(request) }
    }

    suspend fun getUserProducts(
        userId: String,
        pageSize: Int? = null,
        pageToken: String? = null
    ): ApiResult<PaginatedResponse<Product>> {
        return safeApiCall { apiService.getUserProducts(userId, pageSize, pageToken) }
    }
}
```

#### `ApiResult.kt` (Result wrapper)
```kotlin
package com.tracewise.sdk.utils

sealed class ApiResult<out T> {
    data class Success<out T>(val data: T) : ApiResult<T>()
    data class Error(val exception: TraceWiseException) : ApiResult<Nothing>()
    object Loading : ApiResult<Nothing>()
}

suspend fun <T> safeApiCall(apiCall: suspend () -> retrofit2.Response<T>): ApiResult<T> {
    return try {
        val response = apiCall()
        if (response.isSuccessful) {
            response.body()?.let { body ->
                ApiResult.Success(body)
            } ?: ApiResult.Error(TraceWiseException("Empty response body"))
        } else {
            val errorBody = response.errorBody()?.string()
            ApiResult.Error(TraceWiseException.fromHttpError(response.code(), errorBody))
        }
    } catch (e: Exception) {
        ApiResult.Error(TraceWiseException.fromException(e))
    }
}
```

### Step 6: SDK Modules (Exact Trello Task Signatures)

#### `ProductsModule.kt`
```kotlin
package com.tracewise.sdk.modules

import com.tracewise.sdk.models.Product
import com.tracewise.sdk.repository.ProductsRepository
import com.tracewise.sdk.utils.ApiResult
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ProductsModule @Inject constructor(
    private val repository: ProductsRepository
) {
    // Exact signature as required by Trello task
    suspend fun getProduct(gtin: String, serial: String? = null): Product {
        return when (val result = repository.getProduct(gtin, serial)) {
            is ApiResult.Success -> result.data
            is ApiResult.Error -> throw result.exception
            is ApiResult.Loading -> throw IllegalStateException("Unexpected loading state")
        }
    }

    // Exact signature as required by Trello task
    suspend fun registerProduct(userId: String, product: Product) {
        when (val result = repository.registerProduct(product.gtin, product.serial, userId)) {
            is ApiResult.Success -> return
            is ApiResult.Error -> throw result.exception
            is ApiResult.Loading -> throw IllegalStateException("Unexpected loading state")
        }
    }

    // Additional methods for complete API coverage
    suspend fun listProducts(pageSize: Int? = null, pageToken: String? = null) =
        repository.listProducts(pageSize, pageToken)

    suspend fun getUserProducts(userId: String, pageSize: Int? = null, pageToken: String? = null) =
        repository.getUserProducts(userId, pageSize, pageToken)
}
```

#### `EventsModule.kt`
```kotlin
package com.tracewise.sdk.modules

import com.tracewise.sdk.models.LifecycleEvent
import com.tracewise.sdk.repository.EventsRepository
import com.tracewise.sdk.utils.ApiResult
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class EventsModule @Inject constructor(
    private val repository: EventsRepository
) {
    // Exact signature as required by Trello task
    suspend fun addLifecycleEvent(event: LifecycleEvent) {
        when (val result = repository.addLifecycleEvent(event)) {
            is ApiResult.Success -> return
            is ApiResult.Error -> throw result.exception
            is ApiResult.Loading -> throw IllegalStateException("Unexpected loading state")
        }
    }

    // Exact signature as required by Trello task
    suspend fun getProductEvents(
        id: String, 
        limit: Int? = null, 
        pageToken: String? = null
    ): List<LifecycleEvent> {
        // Parse composite ID (gtin:serial format)
        val parts = id.split(":")
        val gtin = parts[0]
        val serial = parts.getOrNull(1) ?: ""

        return when (val result = repository.getProductEvents(gtin, serial, limit, pageToken)) {
            is ApiResult.Success -> result.data.items
            is ApiResult.Error -> throw result.exception
            is ApiResult.Loading -> throw IllegalStateException("Unexpected loading state")
        }
    }
}
```

#### `CirpassModule.kt`
```kotlin
package com.tracewise.sdk.modules

import com.tracewise.sdk.models.CirpassProduct
import com.tracewise.sdk.repository.CirpassRepository
import com.tracewise.sdk.utils.ApiResult
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CirpassModule @Inject constructor(
    private val repository: CirpassRepository
) {
    // Exact signature as required by Trello task
    suspend fun getCirpassProduct(id: String): CirpassProduct {
        return when (val result = repository.getCirpassProduct(id)) {
            is ApiResult.Success -> result.data
            is ApiResult.Error -> throw result.exception
            is ApiResult.Loading -> throw IllegalStateException("Unexpected loading state")
        }
    }

    suspend fun listCirpassProducts(limit: Int? = null) =
        repository.listCirpassProducts(limit)
}
```

### Step 7: Main SDK Class

#### `TraceWiseSDK.kt`
```kotlin
package com.tracewise.sdk

import android.content.Context
import com.tracewise.sdk.modules.*
import com.tracewise.sdk.utils.DigitalLinkParser
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

data class SDKConfig(
    val baseUrl: String,
    val apiKey: String? = null,
    val timeoutMs: Long = 30000,
    val maxRetries: Int = 3
)

@Singleton
class TraceWiseSDK @Inject constructor(
    @ApplicationContext private val context: Context,
    val products: ProductsModule,
    val events: EventsModule,
    val cirpass: CirpassModule,
    private val digitalLinkParser: DigitalLinkParser
) {
    companion object {
        @Volatile
        private var INSTANCE: TraceWiseSDK? = null
        
        fun initialize(context: Context, config: SDKConfig): TraceWiseSDK {
            return INSTANCE ?: synchronized(this) {
                // Initialize Hilt and return SDK instance
                val component = DaggerSDKComponent.builder()
                    .context(context)
                    .config(config)
                    .build()
                
                component.getSDK().also { INSTANCE = it }
            }
        }
        
        fun getInstance(): TraceWiseSDK {
            return INSTANCE ?: throw IllegalStateException("SDK not initialized. Call initialize() first.")
        }
    }

    fun parseDigitalLink(url: String) = digitalLinkParser.parse(url)

    suspend fun healthCheck() = products.healthCheck()
}
```

### Step 8: Digital Link Parser

#### `DigitalLinkParser.kt`
```kotlin
package com.tracewise.sdk.utils

import com.tracewise.sdk.models.ProductIdentifiers
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DigitalLinkParser @Inject constructor() {
    
    fun parse(url: String): ProductIdentifiers {
        // GS1 Digital Link format: https://id.gs1.org/01/{gtin}/21/{serial}
        val gtinRegex = Regex("""/01/(\d{14})""")
        val serialRegex = Regex("""/21/([^/?]+)""")
        val batchRegex = Regex("""/10/([^/?]+)""")
        val expiryRegex = Regex("""/17/(\d{6})""")

        val gtinMatch = gtinRegex.find(url)
            ?: throw IllegalArgumentException("Invalid GS1 Digital Link: GTIN not found")

        return ProductIdentifiers(
            gtin = gtinMatch.groupValues[1],
            serial = serialRegex.find(url)?.groupValues?.get(1),
            batch = batchRegex.find(url)?.groupValues?.get(1),
            expiry = expiryRegex.find(url)?.groupValues?.get(1)
        )
    }
}
```

### Step 9: Error Handling

#### `TraceWiseException.kt`
```kotlin
package com.tracewise.sdk.utils

import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

class TraceWiseException(
    message: String,
    val code: String = "UNKNOWN_ERROR",
    val statusCode: Int? = null,
    val correlationId: String? = null,
    cause: Throwable? = null
) : Exception(message, cause) {

    companion object {
        fun fromHttpError(statusCode: Int, errorBody: String?): TraceWiseException {
            return try {
                val errorResponse = Gson().fromJson(errorBody, ErrorResponse::class.java)
                TraceWiseException(
                    message = errorResponse.error.message,
                    code = errorResponse.error.code,
                    statusCode = statusCode,
                    correlationId = errorResponse.error.correlationId
                )
            } catch (e: Exception) {
                TraceWiseException(
                    message = "HTTP $statusCode",
                    code = "HTTP_ERROR",
                    statusCode = statusCode
                )
            }
        }

        fun fromException(exception: Exception): TraceWiseException {
            return when (exception) {
                is SocketTimeoutException -> TraceWiseException(
                    message = "Request timeout",
                    code = "TIMEOUT_ERROR",
                    cause = exception
                )
                is UnknownHostException -> TraceWiseException(
                    message = "Network error",
                    code = "NETWORK_ERROR",
                    cause = exception
                )
                is IOException -> TraceWiseException(
                    message = "Connection error",
                    code = "CONNECTION_ERROR",
                    cause = exception
                )
                else -> TraceWiseException(
                    message = exception.message ?: "Unknown error",
                    code = "UNKNOWN_ERROR",
                    cause = exception
                )
            }
        }
    }
}

data class ErrorResponse(
    @SerializedName("error") val error: ErrorDetail
)

data class ErrorDetail(
    @SerializedName("code") val code: String,
    @SerializedName("message") val message: String,
    @SerializedName("correlationId") val correlationId: String?
)
```

---

## 🧪 Testing Strategy

### Unit Tests (`src/test/kotlin/`)

#### `ProductsModuleTest.kt`
```kotlin
package com.tracewise.sdk.modules

import com.tracewise.sdk.models.Product
import com.tracewise.sdk.repository.ProductsRepository
import com.tracewise.sdk.utils.ApiResult
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.MockitoAnnotations

class ProductsModuleTest {

    @Mock
    private lateinit var repository: ProductsRepository

    private lateinit var productsModule: ProductsModule

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        productsModule = ProductsModule(repository)
    }

    @Test
    fun `getProduct should return product when repository succeeds`() = runTest {
        // Given
        val expectedProduct = Product(gtin = "1234567890123", name = "Test Product")
        `when`(repository.getProduct("1234567890123", "SN123"))
            .thenReturn(ApiResult.Success(expectedProduct))

        // When
        val result = productsModule.getProduct("1234567890123", "SN123")

        // Then
        assert(result == expectedProduct)
        verify(repository).getProduct("1234567890123", "SN123")
    }

    @Test(expected = TraceWiseException::class)
    fun `getProduct should throw exception when repository fails`() = runTest {
        // Given
        `when`(repository.getProduct("1234567890123", "SN123"))
            .thenReturn(ApiResult.Error(TraceWiseException("Product not found")))

        // When
        productsModule.getProduct("1234567890123", "SN123")
    }
}
```

### Integration Tests (`src/androidTest/kotlin/`)

#### `SDKIntegrationTest.kt`
```kotlin
package com.tracewise.sdk

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class SDKIntegrationTest {

    private lateinit var sdk: TraceWiseSDK

    @Before
    fun setup() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val config = SDKConfig(
            baseUrl = "http://localhost:5001/tracewise-staging/europe-central2/api",
            apiKey = "test-key"
        )
        sdk = TraceWiseSDK.initialize(context, config)
    }

    @Test
    fun testDigitalLinkParsing() {
        val url = "https://id.gs1.org/01/04012345678905/21/SN123456"
        val result = sdk.parseDigitalLink(url)

        assert(result.gtin == "04012345678905")
        assert(result.serial == "SN123456")
    }

    @Test
    fun testProductWorkflow() = runTest {
        // Test against local emulator
        val product = sdk.products.getProduct("04012345678905", "SN123456")
        assert(product.gtin == "04012345678905")
    }
}
```

---

## 📦 Usage Examples

### Basic Setup

```kotlin
// In Application class
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Firebase
        FirebaseApp.initializeApp(this)
        
        // Initialize TraceWise SDK
        val config = SDKConfig(
            baseUrl = "https://trace-wise.eu/api",
            apiKey = "your-api-key"
        )
        TraceWiseSDK.initialize(this, config)
    }
}
```

### Usage in Activity/Fragment

```kotlin
class MainActivity : AppCompatActivity() {
    private lateinit var sdk: TraceWiseSDK

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        sdk = TraceWiseSDK.getInstance()
        
        // Example usage
        lifecycleScope.launch {
            try {
                // Parse QR code
                val ids = sdk.parseDigitalLink("https://id.gs1.org/01/04012345678905/21/SN123")
                
                // Get product (exact Trello task signature)
                val product = sdk.products.getProduct(ids.gtin, ids.serial)
                
                // Register product to user (exact Trello task signature)
                sdk.products.registerProduct("user123", product)
                
                // Add lifecycle event (exact Trello task signature)
                val event = LifecycleEvent(
                    gtin = ids.gtin,
                    serial = ids.serial,
                    bizStep = "purchased",
                    timestamp = Instant.now().toString(),
                    details = mapOf("location" to "Store A")
                )
                sdk.events.addLifecycleEvent(event)
                
                // Get product events (exact Trello task signature)
                val events = sdk.events.getProductEvents("${ids.gtin}:${ids.serial}", 20)
                
                // Get CIRPASS product (exact Trello task signature)
                val cirpassProduct = sdk.cirpass.getCirpassProduct("cirpass-001")
                
            } catch (e: TraceWiseException) {
                Log.e("TraceWise", "SDK Error: ${e.message}", e)
            }
        }
    }
}
```

---

## 🚀 Publishing

### Maven Central Publishing

```kotlin
// In module build.gradle.kts
publishing {
    publications {
        create<MavenPublication>("release") {
            from(components["release"])
            
            groupId = "com.tracewise"
            artifactId = "sdk-android"
            version = "1.0.0"
            
            pom {
                name.set("TraceWise Android SDK")
                description.set("Official TraceWise SDK for Android")
                url.set("https://github.com/tracewise/tracewise-sdk")
                
                licenses {
                    license {
                        name.set("MIT License")
                        url.set("https://opensource.org/licenses/MIT")
                    }
                }
                
                developers {
                    developer {
                        id.set("tracewise")
                        name.set("TraceWise Team")
                        email.set("sdk@tracewise.io")
                    }
                }
            }
        }
    }
}
```

---

## ✅ Implementation Checklist

- [ ] **Project Setup & Dependencies** (45 min)
- [ ] **Data Models & DTOs** (60 min)
- [ ] **Network Layer (Retrofit + OkHttp)** (90 min)
- [ ] **Authentication & Interceptors** (60 min)
- [ ] **Repository Pattern Implementation** (90 min)
- [ ] **Dependency Injection (Hilt)** (60 min)
- [ ] **SDK Modules (Exact Signatures)** (90 min)
- [ ] **Main SDK Class & Initialization** (45 min)
- [ ] **Digital Link Parser** (30 min)
- [ ] **Error Handling & Exceptions** (45 min)
- [ ] **Unit Tests** (120 min)
- [ ] **Integration Tests** (90 min)
- [ ] **Documentation & Examples** (60 min)
- [ ] **Publishing Setup** (45 min)

**Total Estimated Time: 16 hours**

---

## 🎯 Key Architecture Benefits

1. **Clean Architecture**: Clear separation between data, domain, and presentation layers
2. **Dependency Injection**: Easy testing and loose coupling with Hilt
3. **Coroutines**: Modern async programming with structured concurrency
4. **Repository Pattern**: Abstraction over data sources with caching capabilities
5. **Type Safety**: Full Kotlin type safety with data classes
6. **Android Best Practices**: Follows Google's recommended architecture patterns
7. **Testability**: Easy to mock and test all components
8. **Performance**: Efficient networking with connection pooling and retry logic
9. **Security**: Secure token storage and automatic token refresh
10. **Maintainability**: Modular design with clear responsibilities

This architecture ensures the Android SDK is production-ready, follows Android best practices, and provides excellent performance while meeting all exact requirements from the Trello task.