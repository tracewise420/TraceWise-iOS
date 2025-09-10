import Foundation

public class DigitalLinkParser {
    
    // GS1 AIs: 01=GTIN (14 digits), 21=Serial, 10=Batch/Lot, 17=Expiry (YYMMDD)
    public static func parse(_ url: String) throws -> ProductIDs {
        let gtinPattern = "/01/(\\d{14})"
        let serialPattern = "/21/([^/?]+)"
        let batchPattern = "/10/([^/?]+)"
        let expiryPattern = "/17/(\\d{6})"
        
        guard let gtin = extractMatch(from: url, pattern: gtinPattern) else {
            throw TraceWiseError.invalidDigitalLink("GTIN not found in Digital Link")
        }
        
        let serial = extractMatch(from: url, pattern: serialPattern)
        let batch = extractMatch(from: url, pattern: batchPattern)
        let expiry = extractMatch(from: url, pattern: expiryPattern)
        
        return ProductIDs(
            gtin: gtin,
            serial: serial,
            batch: batch,
            expiry: expiry
        )
    }
    
    private static func extractMatch(from string: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let match = regex.firstMatch(in: string, options: [], range: range),
              match.numberOfRanges > 1 else { return nil }
        let matchRange = match.range(at: 1)
        guard let swiftRange = Range(matchRange, in: string) else { return nil }
        return String(string[swiftRange])
    }
}