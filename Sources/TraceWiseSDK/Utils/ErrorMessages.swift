import Foundation

public struct ErrorMessages {
    // Validation Errors
    public static let invalidGTIN = "Invalid GTIN format. Must be 8, 12, 13, or 14 digits."
    public static let invalidSerial = "Invalid serial number format."
    public static let invalidUserID = "Invalid user ID format."
    public static let invalidURL = "Invalid URL format."
    public static let emptyProductID = "Product ID cannot be empty."
    
    // Network Errors
    public static let networkError = "Network connection failed. Please check your internet connection."
    public static let requestTimeout = "Request timed out. Please try again."
    public static let serverError = "Server error occurred. Please try again later."
    
    // Authentication Errors
    public static let invalidAPIKey = "Invalid API key provided."
    public static let authenticationFailed = "Authentication failed. Please check your credentials."
    public static let insufficientPermissions = "Insufficient permissions for this operation."
    
    // Resource Errors
    public static let productNotFound = "Product not found with the provided identifiers."
    public static let eventNotFound = "Event not found."
    public static let userNotFound = "User not found."
    
    // Rate Limiting
    public static let rateLimitExceeded = "Rate limit exceeded. Please try again later."
    public static let quotaExceeded = "API quota exceeded for your subscription tier."
    
    // Offline Queue
    public static let offlineQueueFull = "Offline queue is full. Some requests may be lost."
    public static let offlineProcessingFailed = "Failed to process offline requests."
    
    // General
    public static let unknownError = "An unknown error occurred. Please try again."
    public static let operationCancelled = "Operation was cancelled."
    public static let invalidResponse = "Invalid response received from server."
}