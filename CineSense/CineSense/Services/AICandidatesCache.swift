//
//  AICandidatesCache.swift
//  CineSense
//
//  Created by Neel Joshi on 1/3/26.
//

import Foundation

/// In-memory cache for AI identify results (complete resolved candidates)
@MainActor
final class AICandidatesCache {
    static let shared = AICandidatesCache()

    private var cache: [String: CacheEntry] = [:]
    private let maxEntries = 50
    private var accessOrder: [String] = []

    private init() {}

    // MARK: - Public API

    /// Get cached AI results for a given image path + text hint
    func get(imagePath: String, textHint: String?) -> CachedAIResult? {
        let key = cacheKey(imagePath: imagePath, textHint: textHint)

        guard let entry = cache[key] else {
            return nil
        }

        // Update access order (LRU)
        updateAccessOrder(for: key)

        return entry.result
    }

    /// Set cached AI results for a given image path + text hint
    func set(imagePath: String, textHint: String?, response: AiIdentifyResponse, candidates: [ResolvedCandidate]) {
        let key = cacheKey(imagePath: imagePath, textHint: textHint)

        let result = CachedAIResult(
            response: response,
            candidates: candidates
        )

        cache[key] = CacheEntry(result: result, timestamp: Date())
        updateAccessOrder(for: key)

        // Evict oldest if needed
        evictIfNeeded()
    }

    /// Clear a specific cache entry (used for "New search")
    func clear(imagePath: String, textHint: String?) {
        let key = cacheKey(imagePath: imagePath, textHint: textHint)
        cache.removeValue(forKey: key)
        accessOrder.removeAll { $0 == key }
    }

    /// Clear all cached results
    func clearAll() {
        cache.removeAll()
        accessOrder.removeAll()
    }

    // MARK: - Private

    private func cacheKey(imagePath: String, textHint: String?) -> String {
        let normalizedPath = imagePath
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let normalizedHint = (textHint ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // Combine path and hint for unique key
        if normalizedHint.isEmpty {
            return normalizedPath
        } else {
            return "\(normalizedPath)_\(normalizedHint)"
        }
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
        let result: CachedAIResult
        let timestamp: Date
    }
}

// MARK: - Cached AI Result

/// Complete AI result with resolved candidates (including posters)
struct CachedAIResult {
    let response: AiIdentifyResponse
    let candidates: [ResolvedCandidate]
}
