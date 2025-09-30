import Foundation

public struct Webhook: Codable {
    public let id: String?
    public let url: String
    public let events: [WebhookEvent]
    public let secret: String?
    public let active: Bool
    public let headers: [String: String]?
    public let retryPolicy: RetryPolicy?
    public let createdAt: String?
    public let updatedAt: String?
    
    public init(url: String, events: [WebhookEvent], secret: String? = nil, active: Bool = true, headers: [String: String]? = nil, retryPolicy: RetryPolicy? = nil) {
        self.id = nil
        self.url = url
        self.events = events
        self.secret = secret
        self.active = active
        self.headers = headers
        self.retryPolicy = retryPolicy
        self.createdAt = nil
        self.updatedAt = nil
    }
}

public struct WebhookEvent: Codable {
    public let type: WebhookEventType
    
    public init(type: WebhookEventType) {
        self.type = type
    }
}

public enum WebhookEventType: String, Codable {
    case productCreated = "product.created"
    case productUpdated = "product.updated"
    case productDeleted = "product.deleted"
    case eventCreated = "event.created"
    case eventUpdated = "event.updated"
    case eventDeleted = "event.deleted"
    case dppCreated = "dpp.created"
    case dppUpdated = "dpp.updated"
    case cirpassCreated = "cirpass.created"
    case cirpassUpdated = "cirpass.updated"
}

public struct RetryPolicy: Codable {
    public let maxRetries: Int
    public let backoffMultiplier: Double
    public let initialDelay: Int
    
    public init(maxRetries: Int, backoffMultiplier: Double, initialDelay: Int) {
        self.maxRetries = maxRetries
        self.backoffMultiplier = backoffMultiplier
        self.initialDelay = initialDelay
    }
}

public struct WebhookDelivery: Codable {
    public let id: String
    public let webhookId: String
    public let event: WebhookEvent
    public let status: WebhookDeliveryStatus
    public let attempts: Int
    public let lastAttempt: String?
    public let nextAttempt: String?
    public let response: WebhookResponse?
}

public enum WebhookDeliveryStatus: String, Codable {
    case pending
    case delivered
    case failed
    case retrying
}

public struct WebhookResponse: Codable {
    public let statusCode: Int
    public let body: String
    public let headers: [String: String]
}

public struct WebhookTestResult: Codable {
    public let success: Bool
    public let error: String?
}