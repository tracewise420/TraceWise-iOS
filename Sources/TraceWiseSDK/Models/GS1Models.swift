import Foundation

// MARK: - GS1 Digital Link Models

public struct ResolveDigitalLinkRequest: Codable {
    public let url: String
    
    public init(url: String) {
        self.url = url
    }
}

public struct ResolveDigitalLinkResponse: Codable {
    public let gtin: String
    public let serial: String?
    public let product: Product?
    public let dppData: [String: AnyCodable]?
    public let redirectUrl: String?
    public let source: String
    public let validation: ValidationResult
    
    public init(gtin: String, serial: String? = nil, product: Product? = nil, dppData: [String: AnyCodable]? = nil, redirectUrl: String? = nil, source: String, validation: ValidationResult) {
        self.gtin = gtin
        self.serial = serial
        self.product = product
        self.dppData = dppData
        self.redirectUrl = redirectUrl
        self.source = source
        self.validation = validation
    }
}

public struct EnhancedProductResponse: Codable {
    public let product: Product?
    public let validation: ValidationResult
    public let dataSource: String
    
    public init(product: Product? = nil, validation: ValidationResult, dataSource: String) {
        self.product = product
        self.validation = validation
        self.dataSource = dataSource
    }
}

public struct QRCodeResponse: Codable {
    public let digitalLinkUrl: String
    public let gtin: String
    public let serial: String?
    public let qrCodeData: String
    public let validation: ValidationResult
    
    public init(digitalLinkUrl: String, gtin: String, serial: String? = nil, qrCodeData: String, validation: ValidationResult) {
        self.digitalLinkUrl = digitalLinkUrl
        self.gtin = gtin
        self.serial = serial
        self.qrCodeData = qrCodeData
        self.validation = validation
    }
}

public struct ValidationResult: Codable {
    public let isValid: Bool
    public let source: String
    public let errorMessage: String?
    
    public init(isValid: Bool, source: String, errorMessage: String? = nil) {
        self.isValid = isValid
        self.source = source
        self.errorMessage = errorMessage
    }
}

// MARK: - GTIN Validation Utility

public struct GTINValidator {
    public static func isValid(_ gtin: String) -> Bool {
        // Remove any non-digits
        let digits = gtin.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        
        // Check length (8, 12, 13, or 14 digits)
        guard [8, 12, 13, 14].contains(digits.count) else { return false }
        
        // Calculate check digit
        let numbers = digits.compactMap { Int(String($0)) }
        guard numbers.count == digits.count else { return false }
        
        let checkDigit = numbers.last!
        let calculationNumbers = Array(numbers.dropLast())
        
        var sum = 0
        for (index, number) in calculationNumbers.enumerated() {
            let multiplier = (calculationNumbers.count - index) % 2 == 0 ? 1 : 3
            sum += number * multiplier
        }
        
        let calculatedCheck = (10 - (sum % 10)) % 10
        return calculatedCheck == checkDigit
    }
}

// MARK: - GS1 Digital Link Parser Extension

extension DigitalLinkParser {
    public static func parseGS1DigitalLink(_ url: String) throws -> ProductIDs {
        guard let urlComponents = URLComponents(string: url) else {
            throw TraceWiseError.invalidDigitalLink("Invalid URL format")
        }
        
        let pathSegments = urlComponents.path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        var gtin = ""
        var serial: String?
        
        // Parse GS1 Digital Link format: /01/{gtin}/21/{serial}
        var i = 0
        while i < pathSegments.count - 1 {
            let key = pathSegments[i]
            let value = pathSegments[i + 1]
            
            switch key {
            case "01": // GTIN
                gtin = value
            case "21": // Serial Number
                serial = value
            default:
                break
            }
            i += 2
        }
        
        guard !gtin.isEmpty else {
            throw TraceWiseError.invalidDigitalLink("GTIN not found in URL")
        }
        
        guard GTINValidator.isValid(gtin) else {
            throw TraceWiseError.invalidDigitalLink("Invalid GTIN: \(gtin)")
        }
        
        return ProductIDs(gtin: gtin, serial: serial)
    }
}