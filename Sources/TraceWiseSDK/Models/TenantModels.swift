import Foundation

public struct Tenant: Codable {
    public let id: String?
    public let name: String
    public let domain: String
    public let settings: TenantSettings
    public let status: TenantStatus
    public let createdAt: String?
    public let updatedAt: String?
    
    public init(name: String, domain: String, settings: TenantSettings, status: TenantStatus = .active) {
        self.id = nil
        self.name = name
        self.domain = domain
        self.settings = settings
        self.status = status
        self.createdAt = nil
        self.updatedAt = nil
    }
}

public enum TenantStatus: String, Codable {
    case active
    case inactive
    case suspended
}

public struct TenantSettings: Codable {
    public let maxUsers: Int
    public let maxProducts: Int
    public let features: [String]
    public let customBranding: CustomBranding?
    public let webhookSettings: WebhookSettings?
    
    public init(maxUsers: Int, maxProducts: Int, features: [String], customBranding: CustomBranding? = nil, webhookSettings: WebhookSettings? = nil) {
        self.maxUsers = maxUsers
        self.maxProducts = maxProducts
        self.features = features
        self.customBranding = customBranding
        self.webhookSettings = webhookSettings
    }
}

public struct CustomBranding: Codable {
    public let logo: String?
    public let primaryColor: String?
    public let secondaryColor: String?
    
    public init(logo: String? = nil, primaryColor: String? = nil, secondaryColor: String? = nil) {
        self.logo = logo
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
}

public struct WebhookSettings: Codable {
    public let maxWebhooks: Int
    public let allowedEvents: [String]
    
    public init(maxWebhooks: Int, allowedEvents: [String]) {
        self.maxWebhooks = maxWebhooks
        self.allowedEvents = allowedEvents
    }
}

public struct TenantUser: Codable {
    public let id: String?
    public let tenantId: String
    public let email: String
    public let role: TenantUserRole
    public let permissions: [String]
    public let status: TenantUserStatus
    public let createdAt: String?
    public let lastLogin: String?
    
    public init(tenantId: String, email: String, role: TenantUserRole, permissions: [String], status: TenantUserStatus = .active) {
        self.id = nil
        self.tenantId = tenantId
        self.email = email
        self.role = role
        self.permissions = permissions
        self.status = status
        self.createdAt = nil
        self.lastLogin = nil
    }
}

public enum TenantUserRole: String, Codable {
    case admin
    case user
    case viewer
}

public enum TenantUserStatus: String, Codable {
    case active
    case inactive
    case pending
}

public struct TenantInvitation: Codable {
    public let id: String?
    public let tenantId: String
    public let email: String
    public let role: TenantUserRole
    public let invitedBy: String
    public let expiresAt: String
    public let status: TenantInvitationStatus
    public let createdAt: String?
    
    public init(tenantId: String, email: String, role: TenantUserRole, invitedBy: String, expiresAt: String) {
        self.id = nil
        self.tenantId = tenantId
        self.email = email
        self.role = role
        self.invitedBy = invitedBy
        self.expiresAt = expiresAt
        self.status = .pending
        self.createdAt = nil
    }
}

public enum TenantInvitationStatus: String, Codable {
    case pending
    case accepted
    case expired
    case revoked
}