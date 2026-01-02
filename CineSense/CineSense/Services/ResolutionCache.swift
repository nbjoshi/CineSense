//
//  ResolutionCache.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Foundation

/// In-memory cache for resolved candidates to avoid redundant API calls
@MainActor
final class ResolutionCache {
    static let shared = ResolutionCache()

    private var cache: [String: CacheEntry] = [:]
    private let maxEntries = 100
    private var accessOrder: [String] = []

    private init() {}

    // MARK: - Public API

    func get(title: String, type: MediaType, year: String) -> ResolutionResult? {
        let key = cacheKey(title: title, type: type, year: year)

        guard let entry = cache[key] else {
            return nil
        }

        // Update access order (LRU)
        updateAccessOrder(for: key)

        return entry.result
    }

    func set(title: String, type: MediaType, year: String, result: ResolutionResult) {
        let key = cacheKey(title: title, type: type, year: year)

        cache[key] = CacheEntry(result: result, timestamp: Date())
        updateAccessOrder(for: key)

        // Evict oldest if needed
        evictIfNeeded()
    }

    func clear() {
        cache.removeAll()
        accessOrder.removeAll()
    }

    // MARK: - Private

    private func cacheKey(title: String, type: MediaType, year: String) -> String {
        let normalized = title
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "^(the|a|an)\\s+", with: "", options: .regularExpression)

        return "\(type.rawValue)_\(normalized)_\(year)"
    }

    private func updateAccessOrder(for key: String) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }

    private func evictIfNeeded() {
        guard cache.count > maxEntries else { return }

        // Remove oldest accessed entries
        let toRemove = accessOrder.count - maxEntries
        guard toRemove > 0 else { return }

        let keysToRemove = accessOrder.prefix(toRemove)
        keysToRemove.forEach { cache.removeValue(forKey: $0) }
        accessOrder.removeFirst(toRemove)
    }

    // MARK: - Cache Entry

    private struct CacheEntry {
        let result: ResolutionResult
        let timestamp: Date
    }
}
