import Foundation

class IdempotencyManager {
    private var requestCache: [String: Any] = [:]
    private let queue = DispatchQueue(label: "idempotency.queue", attributes: .concurrent)
    
    static let shared = IdempotencyManager()
    
    private init() {}
    
    func generateIdempotencyKey() -> String {
        return "\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString)"
    }
    
    func executeIdempotent<T>(key: String, operation: () throws -> T) throws -> T {
        return try queue.sync {
            if let cachedResult = requestCache[key] as? T {
                return cachedResult
            }
            
            let result = try operation()
            requestCache[key] = result
            return result
        }
    }
    
    func clearCache() {
        queue.async(flags: .barrier) {
            self.requestCache.removeAll()
        }
    }
    
    func removeKey(_ key: String) {
        queue.async(flags: .barrier) {
            self.requestCache.removeValue(forKey: key)
        }
    }
}