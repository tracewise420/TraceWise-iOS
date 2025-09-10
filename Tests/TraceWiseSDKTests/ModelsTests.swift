import XCTest
@testable import TraceWiseSDK

final class ModelsTests: XCTestCase {
    
    func testProductCodable() throws {
        let product = Product(
            gtin: "04012345678905",
            serial: "SN123",
            name: "Test Product",
            description: "Test Description",
            manufacturer: "Test Manufacturer",
            category: "Test Category"
        )
        
        let data = try JSONEncoder().encode(product)
        let decoded = try JSONDecoder().decode(Product.self, from: data)
        
        XCTAssertEqual(product, decoded)
    }
    
    func testLifecycleEventCodable() throws {
        let event = LifecycleEvent(
            gtin: "04012345678905",
            serial: "SN123",
            bizStep: "shipping",
            timestamp: "2025-01-10T10:00:00Z",
            details: ["location": "Warehouse A"]
        )
        
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(LifecycleEvent.self, from: data)
        
        XCTAssertEqual(event, decoded)
    }
    
    func testAnyCodableEquality() {
        let int1 = AnyCodable(42)
        let int2 = AnyCodable(42)
        let int3 = AnyCodable(43)
        
        XCTAssertEqual(int1, int2)
        XCTAssertNotEqual(int1, int3)
        
        let string1 = AnyCodable("test")
        let string2 = AnyCodable("test")
        let string3 = AnyCodable("different")
        
        XCTAssertEqual(string1, string2)
        XCTAssertNotEqual(string1, string3)
    }
    
    func testPaginatedResponse() throws {
        let products = [
            Product(gtin: "1", name: "Product 1"),
            Product(gtin: "2", name: "Product 2")
        ]
        
        let response = PaginatedResponse(
            items: products,
            nextPageToken: "token123",
            totalCount: 100
        )
        
        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(PaginatedResponse<Product>.self, from: data)
        
        XCTAssertEqual(response.items.count, decoded.items.count)
        XCTAssertEqual(response.nextPageToken, decoded.nextPageToken)
        XCTAssertEqual(response.totalCount, decoded.totalCount)
    }
    
    func testSubscriptionInfo() throws {
        let subscriptionInfo = SubscriptionInfo(
            tier: "free",
            limits: SubscriptionInfo.Limits(
                productsPerMonth: 100,
                eventsPerMonth: 500,
                apiCallsPerMinute: 10
            ),
            usage: SubscriptionInfo.Usage(
                productsThisMonth: 25,
                eventsThisMonth: 150,
                apiCallsThisMinute: 3
            )
        )
        
        let data = try JSONEncoder().encode(subscriptionInfo)
        let decoded = try JSONDecoder().decode(SubscriptionInfo.self, from: data)
        
        XCTAssertEqual(subscriptionInfo.tier, decoded.tier)
        XCTAssertEqual(subscriptionInfo.limits.productsPerMonth, decoded.limits.productsPerMonth)
        XCTAssertEqual(subscriptionInfo.usage.productsThisMonth, decoded.usage.productsThisMonth)
    }
}