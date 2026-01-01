//
//  SearchViewModel.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation
import Combine

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

    private let tmdbService: TMDBService
    private var searchTask: Task<Void, Never>?

    init(tmdbService: TMDBService = TMDBService()) {
        self.tmdbService = tmdbService
    }

    private func performSearch() async {
        guard !query.isEmpty else {
            state = .idle
            return
        }

        state = .loading

        do {
            let results = try await tmdbService.searchMulti(query: query)
            if results.isEmpty {
                state = .empty
            } else {
                state = .loaded(results)
            }
        } catch {
            state = .failed(error)
        }
    }
}
