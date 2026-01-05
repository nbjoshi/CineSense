//
//  RecentSearchRepository.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class RecentSearchRepository: ObservableObject {
    private let modelContext: ModelContext
    private let maxRecentSearches = 20

    @Published private(set) var recentSearches: [RecentSearch] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSearches()
    }

    // MARK: - Fetch

    func loadSearches() {
        let descriptor = FetchDescriptor<RecentSearch>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        recentSearches = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Add

    func addTextSearch(_ query: String) {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        // Remove existing text search with same query (case-insensitive)
        let existing = recentSearches.filter {
            $0.query?.lowercased() == normalized.lowercased()
        }
        existing.forEach { modelContext.delete($0) }

        // Add new search
        let search = RecentSearch(query: normalized)
        modelContext.insert(search)

        trimToMax()
        save()
        loadSearches()
    }

    func addMediaSearch(mediaId: Int, mediaType: MediaType, title: String) {
        // Remove existing media search with same ID + type
        let existing = recentSearches.filter {
            $0.mediaId == mediaId && $0.mediaType == mediaType.rawValue
        }
        existing.forEach { modelContext.delete($0) }

        // Add new search
        let search = RecentSearch(mediaId: mediaId, mediaType: mediaType, title: title)
        modelContext.insert(search)

        trimToMax()
        save()
        loadSearches()
    }

    // MARK: - Delete

    func delete(_ search: RecentSearch) {
        modelContext.delete(search)
        save()
        loadSearches()
    }

    func clearAll() {
        // Fetch all from context to ensure we get everything
        let descriptor = FetchDescriptor<RecentSearch>()
        guard let all = try? modelContext.fetch(descriptor) else { return }

        all.forEach { modelContext.delete($0) }
        save()
        loadSearches()
    }

    // MARK: - Private

    private func trimToMax() {
        let descriptor = FetchDescriptor<RecentSearch>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        guard let all = try? modelContext.fetch(descriptor) else { return }

        if all.count > maxRecentSearches {
            let toDelete = all.suffix(all.count - maxRecentSearches)
            toDelete.forEach { modelContext.delete($0) }
        }
    }

    private func save() {
        try? modelContext.save()
    }
}
