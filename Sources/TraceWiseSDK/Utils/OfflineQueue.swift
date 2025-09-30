import Foundation

public class OfflineQueue {
    private let storage = UserDefaults.standard
    private let queue = DispatchQueue(label: "com.tracewise.offline.queue", qos: .utility)
    private let storageKey = "tracewise_offline_queue"
    
    public init() {}
    
    public func enqueue(request: APIRequest) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var requests = self.getStoredRequests()
            requests.append(request)
            self.saveRequests(requests)
        }
    }
    
    public func processQueue() async {
        let requests = await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                let requests = self?.getStoredRequests() ?? []
                continuation.resume(returning: requests)
            }
        }
        
        guard !requests.isEmpty else { return }
        
        for request in requests {
            do {
                // TODO: Replace with actual API client when available
                print("Processing offline request: \(request)")
                await removeRequest(request)
            } catch {
                // Keep failed requests in queue for retry
                continue
            }
        }
    }
    
    public func getQueueSize() -> Int {
        return queue.sync {
            return getStoredRequests().count
        }
    }
    
    private func getStoredRequests() -> [APIRequest] {
        guard let data = storage.data(forKey: storageKey),
              let requests = try? JSONDecoder().decode([APIRequest].self, from: data) else {
            return []
        }
        return requests
    }
    
    private func saveRequests(_ requests: [APIRequest]) {
        guard let data = try? JSONEncoder().encode(requests) else { return }
        storage.set(data, forKey: storageKey)
    }
    
    private func removeRequest(_ request: APIRequest) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                var requests = self.getStoredRequests()
                requests.removeAll { $0.id == request.id }
                self.saveRequests(requests)
                continuation.resume()
            }
        }
    }
}

public struct APIRequest: Codable {
    public let id: String
    public let method: String
    public let path: String
    public let body: Data?
    public let headers: [String: String]
    
    public init(method: String, path: String, body: Data? = nil, headers: [String: String] = [:]) {
        self.id = UUID().uuidString
        self.method = method
        self.path = path
        self.body = body
        self.headers = headers
    }
}