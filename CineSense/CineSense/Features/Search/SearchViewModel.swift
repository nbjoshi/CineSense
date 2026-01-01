//
//  SearchViewModel.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded([MediaSummary])
        case empty
        case failed(Error)
    }

    @Published var state: State = .idle
    @Published var query: String = "" {
        didSet {
            searchTask?.cancel()
            if query.isEmpty {
                state = .idle
            } else {
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 400_000_000) // 400ms debounce
                    if !Task.isCancelled {
                        await performSearch()
                    }
                }
            }
        }
    }

    private let searchService: SearchService
    private let recentSearchesStore: RecentSearchesStore
    private var searchTask: Task<Void, Never>?

    var recentSearches: [RecentSearch] {
        recentSearchesStore.recentSearches
    }

    init(searchService: SearchService = SearchService(), recentSearchesStore: RecentSearchesStore? = nil) {
        self.searchService = searchService
        self.recentSearchesStore = recentSearchesStore ?? RecentSearchesStore()
    }

    func selectRecentSearch(_ search: RecentSearch) {
        query = search.query
    }

    func deleteRecentSearch(_ search: RecentSearch) {
        recentSearchesStore.removeSearch(search)
    }

    func clearAllRecentSearches() {
        recentSearchesStore.clearAll()
    }

    private func performSearch() async {
        guard !query.isEmpty else {
            state = .idle
            return
        }

        state = .loading

        do {
            let response = try await searchService.multiSearch(query: query, page: 1)
            let mediaSummaries = response.results.compactMap { $0.toMediaSummary() }
            if mediaSummaries.isEmpty {
                state = .empty
            } else {
                state = .loaded(mediaSummaries)
                // Save successful search to recent searches
                recentSearchesStore.addSearch(query)
            }
        } catch {
            state = .failed(error)
        }
    }
}
