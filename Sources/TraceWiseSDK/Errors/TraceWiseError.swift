import Foundation

public enum TraceWiseError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case apiError(code: String, message: String, statusCode: Int)
    case authenticationError(String)
    case invalidDigitalLink(String)
    case rateLimitExceeded(retryAfter: Int?)
    case timeout
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(_, let message, _):
            return message
        case .authenticationError(let message):
            return "Authentication error: \(message)"
        case .invalidDigitalLink(let message):
            return "Invalid Digital Link: \(message)"
        case .rateLimitExceeded(let retryAfter):
            return "Rate limit exceeded. Retry after \(retryAfter ?? 60) seconds"
        case .timeout:
            return "Request timeout"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    public var code: String {
        switch self {
        case .invalidURL:
            return "INVALID_URL"
        case .invalidResponse:
            return "INVALID_RESPONSE"
        case .networkError:
            return "NETWORK_ERROR"
        case .apiError(let code, _, _):
            return code
        case .authenticationError:
            return "AUTH_ERROR"
        case .invalidDigitalLink:
            return "INVALID_DIGITAL_LINK"
        case .rateLimitExceeded:
            return "RATE_LIMIT_EXCEEDED"
        case .timeout:
            return "TIMEOUT"
        case .unknown:
            return "UNKNOWN_ERROR"
        }
    }
}

struct APIErrorResponse: Codable {
    let error: APIErrorDetail
}

struct APIErrorDetail: Codable {
    let code: String
    let message: String
    let correlationId: String?
}