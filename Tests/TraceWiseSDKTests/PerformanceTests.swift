import XCTest
@testable import TraceWiseSDK

final class PerformanceTests: XCTestCase {
    
    func testDigitalLinkParsingPerformance() {
        let url = "https://id.gs1.org/01/09506000134352/21/SN12345"
        
        measure {
            for _ in 0..<1000 {
                _ = try? DigitalLinkParser.parse(url)
            }
        }
    }
    
    func testPerformanceMonitorOverhead() {
        let monitor = PerformanceMonitor.shared
        
        measure {
            for _ in 0..<10000 {
                monitor.trackAPICall(
                    endpoint: "/v1/products",
                    duration: 0.1,
                    success: true,
                    cached: false,
                    retries: 0
                )
            }
        }
    }
    
    func testMemoryUsageUnderLoad() {
        let monitor = PerformanceMonitor.shared
        monitor.reset()
        
        // Add many metrics to test memory management
        for i in 0..<2000 {
            monitor.trackAPICall(
                endpoint: "/v1/products/\(i)",
                duration: Double.random(in: 0.05...0.2),
                success: Int.random(in: 0...10) > 1, // 90% success rate
                cached: Int.random(in: 0...10) < 3, // 30% cache rate
                retries: Int.random(in: 0...3)
            )
        }
        
        let metrics = monitor.getMetrics()
        
        // Should maintain reasonable memory usage
        XCTAssertLessThanOrEqual(metrics.totalRequests, 2000)
        XCTAssertGreaterThan(metrics.totalRequests, 0)
        XCTAssertGreaterThanOrEqual(metrics.successRate, 80.0)
        XCTAssertLessThanOrEqual(metrics.successRate, 100.0)
    }
    
    func testConcurrentPerformanceTracking() {
        let monitor = PerformanceMonitor.shared
        monitor.reset()
        
        let expectation = XCTestExpectation(description: "Concurrent tracking")
        let dispatchGroup = DispatchGroup()
        let iterations = 100
        let concurrentQueues = 10
        
        for queueId in 0..<concurrentQueues {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                for _ in 0..<iterations {
                    monitor.trackAPICall(
                        endpoint: "/v1/test/\(queueId)",
                        duration: Double.random(in: 0.01...0.1),
                        success: true
                    )
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        let metrics = monitor.getMetrics()
        XCTAssertEqual(metrics.totalRequests, Int64(concurrentQueues * iterations))
    }
    
    func testModelInitializationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = Product(
                    gtin: "1234567890123",
                    serial: "SN123",
                    name: "Test Product",
                    description: "Test Description"
                )
            }
        }
    }
    
    func testSDKInitializationPerformance() {
        measure {
            for _ in 0..<100 {
                let config = SDKConfig(
                    baseURL: "https://api.test.com",
                    apiKey: "test-key"
                )
                _ = TraceWiseSDK(config: config)
            }
        }
    }
    
    func testAnyCodablePerformance() {
        let testData: [String: AnyCodable] = [
            "string": AnyCodable("test"),
            "number": AnyCodable(42),
            "boolean": AnyCodable(true),
            "array": AnyCodable([1, 2, 3]),
            "object": AnyCodable(["key": "value"])
        ]
        
        measure {
            for _ in 0..<1000 {
                _ = testData["string"]
                _ = testData["number"]
                _ = testData["boolean"]
                _ = testData["array"]
                _ = testData["object"]
            }
        }
    }
}