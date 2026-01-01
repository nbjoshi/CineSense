//
//  RecentSearch.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Foundation
import Combine

struct RecentSearch: Identifiable, Codable, Equatable {
    let id: UUID
    let query: String
    let timestamp: Date

    init(query: String) {
        self.id = UUID()
        self.query = query
        self.timestamp = Date()
    }
}

@MainActor
final class RecentSearchesStore: ObservableObject {
    private static let storageKey = "recentSearches"
    private static let maxRecentSearches = 10

    @Published private(set) var recentSearches: [RecentSearch] = []

    init() {
        loadSearches()
    }

    func addSearch(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        // Remove existing entry if present
        recentSearches.removeAll { $0.query.lowercased() == trimmedQuery.lowercased() }

        // Add new search at the beginning
        let newSearch = RecentSearch(query: trimmedQuery)
        recentSearches.insert(newSearch, at: 0)

        // Limit to max count
        if recentSearches.count > Self.maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(Self.maxRecentSearches))
        }

        saveSearches()
    }

    func removeSearch(_ search: RecentSearch) {
        recentSearches.removeAll { $0.id == search.id }
        saveSearches()
    }

    func clearAll() {
        recentSearches.removeAll()
        saveSearches()
    }

    private func loadSearches() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            recentSearches = []
            return
        }

        do {
            let decoded = try JSONDecoder().decode([RecentSearch].self, from: data)
            recentSearches = decoded
        } catch {
            print("Failed to decode recent searches: \(error)")
            recentSearches = []
        }
    }

    private func saveSearches() {
        do {
            let encoded = try JSONEncoder().encode(recentSearches)
            UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        } catch {
            print("Failed to encode recent searches: \(error)")
        }
    }
}
