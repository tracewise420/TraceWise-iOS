import Foundation
import CryptoKit

struct RequestSigner {
    static func signRequest(
        method: String,
        url: String,
        body: String?,
        timestamp: String,
        apiKey: String
    ) -> String {
        let payload = "\(method)|\(url)|\(body ?? "")|\(timestamp)"
        return hmacSHA256(data: payload, key: apiKey)
    }
    
    private static func hmacSHA256(data: String, key: String) -> String {
        let keyData = Data(key.utf8)
        let dataData = Data(data.utf8)
        let signature = HMAC<SHA256>.authenticationCode(for: dataData, using: SymmetricKey(data: keyData))
        return Data(signature).map { String(format: "%02x", $0) }.joined()
    }
    
    static func generateTimestamp() -> String {
        return String(Int(Date().timeIntervalSince1970 * 1000))
    }
}