import Foundation

final class CacheService {

    static let shared = CacheService()

    private let workbenchKeyPrefix = "cached_workbench_items_"
    private let conversationsKey = "cached_conversations"
    private let maxCachedItems = 20

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Workbench (Folder-aware)

    private func key(for folderId: String?) -> String {
        return workbenchKeyPrefix + (folderId ?? "root")
    }

    func cacheWorkbenchItems(_ items: [WorkbenchItem], for folderId: String?) {
        let limited = Array(items.prefix(maxCachedItems))

        if let data = try? encoder.encode(limited) {
            UserDefaults.standard.set(data, forKey: key(for: folderId))
        }
    }

    func loadCachedWorkbenchItems(for folderId: String?) -> [WorkbenchItem] {
        guard let data = UserDefaults.standard.data(forKey: key(for: folderId)),
              let items = try? decoder.decode([WorkbenchItem].self, from: data) else {
            return []
        }
        return items
    }

    func clearWorkbenchCache() {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(workbenchKeyPrefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Conversations

    func cacheConversations(_ conversations: [Conversation]) {
        let limited = Array(conversations.prefix(maxCachedItems))

        if let data = try? encoder.encode(limited) {
            UserDefaults.standard.set(data, forKey: conversationsKey)
        }
    }

    func loadCachedConversations() -> [Conversation] {
        guard let data = UserDefaults.standard.data(forKey: conversationsKey),
              let items = try? decoder.decode([Conversation].self, from: data) else {
            return []
        }
        return items
    }

    // MARK: - Clear All

    func clearAll() {
        clearWorkbenchCache()
        UserDefaults.standard.removeObject(forKey: conversationsKey)
    }
}
