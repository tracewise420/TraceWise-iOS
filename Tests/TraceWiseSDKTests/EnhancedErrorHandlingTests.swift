import XCTest
@testable import TraceWiseSDK

final class EnhancedErrorHandlingTests: XCTestCase {
    
    func testTraceWiseErrorCodes() {
        let rateLimitError = TraceWiseError.rateLimitExceeded(retryAfter: 60)
        XCTAssertEqual(rateLimitError.code, "RATE_LIMIT_EXCEEDED")
        
        let apiError = TraceWiseError.apiError(code: "INVALID_GTIN", message: "Invalid GTIN format", statusCode: 400)
        XCTAssertEqual(apiError.code, "INVALID_GTIN")
        
        let authError = TraceWiseError.authenticationError("Invalid API key")
        XCTAssertEqual(authError.code, "AUTH_ERROR")
    }
    
    func testErrorDescriptions() {
        let rateLimitError = TraceWiseError.rateLimitExceeded(retryAfter: 60)
        XCTAssertEqual(rateLimitError.errorDescription, "Rate limit exceeded. Retry after 60 seconds")
        
        let apiError = TraceWiseError.apiError(code: "INVALID_GTIN", message: "Invalid GTIN format", statusCode: 400)
        XCTAssertEqual(apiError.errorDescription, "Invalid GTIN format")
        
        let networkError = TraceWiseError.networkError(URLError(.notConnectedToInternet))
        XCTAssertTrue(networkError.errorDescription?.contains("Network error") == true)
    }
    
    func testErrorRecovery() {
        // Test that errors provide actionable information
        let rateLimitError = TraceWiseError.rateLimitExceeded(retryAfter: 60)
        
        switch rateLimitError {
        case .rateLimitExceeded(let retryAfter):
            XCTAssertEqual(retryAfter, 60)
        default:
            XCTFail("Expected rate limit error")
        }
    }
    
    func testAPIErrorResponse() {
        let apiErrorResponse = APIErrorResponse(
            error: APIErrorDetail(
                code: "VALIDATION_ERROR",
                message: "Invalid request parameters"
            )
        )
        
        XCTAssertEqual(apiErrorResponse.error.code, "VALIDATION_ERROR")
        XCTAssertEqual(apiErrorResponse.error.message, "Invalid request parameters")
    }
}