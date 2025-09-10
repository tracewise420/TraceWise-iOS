import XCTest
@testable import TraceWiseSDK

final class ErrorHandlingTests: XCTestCase {
    
    func testTraceWiseErrorCodes() {
        let errors: [TraceWiseError] = [
            .invalidURL,
            .invalidResponse,
            .networkError(URLError(.notConnectedToInternet)),
            .apiError(code: "TEST_ERROR", message: "Test message", statusCode: 400),
            .authenticationError("Auth failed"),
            .invalidDigitalLink("Invalid format"),
            .rateLimitExceeded(retryAfter: 60),
            .timeout,
            .unknown(NSError(domain: "test", code: -1))
        ]
        
        let expectedCodes = [
            "INVALID_URL",
            "INVALID_RESPONSE", 
            "NETWORK_ERROR",
            "TEST_ERROR",
            "AUTH_ERROR",
            "INVALID_DIGITAL_LINK",
            "RATE_LIMIT_EXCEEDED",
            "TIMEOUT",
            "UNKNOWN_ERROR"
        ]
        
        for (error, expectedCode) in zip(errors, expectedCodes) {
            XCTAssertEqual(error.code, expectedCode)
            XCTAssertNotNil(error.errorDescription)
        }
    }
    
    func testAPIErrorResponseDecoding() throws {
        let json = """
        {
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Invalid GTIN format",
                "correlationId": "abc-123"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIErrorResponse.self, from: data)
        
        XCTAssertEqual(response.error.code, "VALIDATION_ERROR")
        XCTAssertEqual(response.error.message, "Invalid GTIN format")
        XCTAssertEqual(response.error.correlationId, "abc-123")
    }
    
    func testRateLimitError() {
        let error = TraceWiseError.rateLimitExceeded(retryAfter: 120)
        
        XCTAssertEqual(error.code, "RATE_LIMIT_EXCEEDED")
        XCTAssertTrue(error.errorDescription?.contains("120") == true)
    }
}