import Foundation

struct CacheEntry<T> {
    let data: T
    let timestamp: Date
    let ttl: TimeInterval
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > ttl
    }
}

class RequestCache {
    private var cache: [String: Any] = [:]
    private let queue = DispatchQueue(label: "request.cache.queue", attributes: .concurrent)
    
    static let shared = RequestCache()
    
    private init() {}
    
    func put<T>(_ key: String, data: T, ttlMinutes: TimeInterval = 5) {
        let ttl = ttlMinutes * 60
        let entry = CacheEntry(data: data, timestamp: Date(), ttl: ttl)
        
        queue.async(flags: .barrier) {
            self.cache[key] = entry
        }
    }
    
    func get<T>(_ key: String, type: T.Type) -> T? {
        return queue.sync {
            guard let entry = cache[key] as? CacheEntry<T> else { return nil }
            
            if entry.isExpired {
                cache.removeValue(forKey: key)
                return nil
            }
            
            return entry.data
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
    
    func remove(_ key: String) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }
    
    func generateCacheKey(method: HTTPMethod, url: String, params: [String: Any]? = nil) -> String {
        let paramsString = params?.sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&") ?? ""
        return "\(method.rawValue):\(url):\(paramsString)".hashValue.description
    }
}