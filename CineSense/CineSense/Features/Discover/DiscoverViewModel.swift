//
//  DiscoverViewModel.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class DiscoverViewModel: ObservableObject {
    enum State {
        case idle
        case homeLoading
        case home(HomeContent)
        case textSearchLoading
        case textSearchResults([MediaSummary])
        case aiIdentifying
        case aiSuggestions(AiIdentifyResponse, [ResolvedCandidate])
        case empty
        case failed(Error)
    }

    struct HomeContent {
        let trending: [MediaSummary]
        let popularMovies: [MediaSummary]
        let popularTV: [MediaSummary]
    }

    @Published var state: State = .idle
    @Published var searchQuery: String = "" {
        didSet {
            searchTask?.cancel()
            if searchQuery.isEmpty {
                // Don't change state if we're showing AI results or home content
                if case .textSearchLoading = state {
                    state = .idle
                } else if case .textSearchResults = state {
                    state = .idle
                } else if case .empty = state {
                    state = .idle
                }
            } else {
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 400_000_000) // 400ms debounce
                    if !Task.isCancelled {
                        await performTextSearch()
                    }
                }
            }
        }
    }

    private let searchService: SearchService
    private let aiService: AIService
    private let resolutionService: MediaResolutionService
    private let discoverService: DiscoverService
    let recentSearchRepo: RecentSearchRepository
    private let resolutionCache = ResolutionCache.shared
    private let aiCandidatesCache = AICandidatesCache.shared

    private var searchTask: Task<Void, Never>?

    // Track current AI search context for cache key
    private var lastImagePath: String?
    private var lastTextHint: String?

    init(
        searchService: SearchService = SearchService(),
        aiService: AIService = AIService(),
        resolutionService: MediaResolutionService = MediaResolutionService(),
        discoverService: DiscoverService = DiscoverService(),
        modelContext: ModelContext
    ) {
        self.searchService = searchService
        self.aiService = aiService
        self.resolutionService = resolutionService
        self.discoverService = discoverService
        recentSearchRepo = RecentSearchRepository(modelContext: modelContext)
    }

    // MARK: - Home Content

    func loadHomeContent() async {
        state = .homeLoading

        do {
            async let trending = discoverService.getTrendingAll()
            async let popularMovies = discoverService.getPopularMovies()
            async let popularTV = discoverService.getPopularTV()

            let content = try HomeContent(
                trending: await trending,
                popularMovies: await popularMovies,
                popularTV: await popularTV
            )

            state = .home(content)
        } catch {
            state = .failed(error)
        }
    }

    // MARK: - Text Search

    func performTextSearch() async {
        guard !searchQuery.isEmpty else {
            state = .idle
            return
        }

        state = .textSearchLoading

        do {
            let response = try await searchService.multiSearch(query: searchQuery, page: 1)
            let results = response.results.compactMap { $0.toMediaSummary() }

            if results.isEmpty {
                state = .empty
            } else {
                state = .textSearchResults(results)
                recentSearchRepo.addTextSearch(searchQuery)
            }
        } catch {
            state = .failed(error)
        }
    }

    // MARK: - AI Search

    func performAISearch(imageData: Data, contentType: String, textHint: String?) async {
        state = .aiIdentifying

        do {
            // Upload image
            let uploadResult = try await aiService.uploadImageToSignedURL(
                imageData: imageData,
                contentType: contentType
            )

            // Store context for cache key
            lastImagePath = uploadResult.path
            lastTextHint = textHint
            print("🔍 PerformAI: Stored path=\(uploadResult.path), hint=\(textHint ?? "nil")")

            // Check cache first (in case same image was uploaded again)
            if let cached = aiCandidatesCache.get(imagePath: uploadResult.path, textHint: textHint) {
                print("✅ PerformAI: Found cached results, skipping AI call")
                state = .aiSuggestions(cached.response, cached.candidates)
                return
            }
            print("🔍 PerformAI: No cache, proceeding with AI identify")

            // Identify
            let response = try await aiService.identifyImage(
                imagePath: uploadResult.path,
                textHint: textHint
            )

            // Create candidates and show immediately (max 5)
            var candidates = response.candidates.prefix(5).map { ResolvedCandidate(from: $0) }

            // Update state to show skeleton loading
            for index in candidates.indices {
                candidates[index].state = .resolving
            }
            state = .aiSuggestions(response, candidates)

            // Resolve in parallel
            await resolveAllCandidates(&candidates)
            state = .aiSuggestions(response, candidates)

            // Cache the fully resolved results
            print("💾 PerformAI: Caching results for path=\(uploadResult.path), hint=\(textHint ?? "nil")")
            aiCandidatesCache.set(
                imagePath: uploadResult.path,
                textHint: textHint,
                response: response,
                candidates: candidates
            )
            print("✅ PerformAI: Results cached successfully")

        } catch {
            state = .failed(error)
        }
    }

    func restoreCachedAIResults() {
        guard let imagePath = lastImagePath else {
            print("⚠️ RestoreCache: No lastImagePath found")
            return
        }

        if let cached = aiCandidatesCache.get(imagePath: imagePath, textHint: lastTextHint) {
            print("✅ RestoreCache: Found cached results for path: \(imagePath)")
            // Force state update even if already showing AI suggestions
            // This ensures the view refreshes
            state = .aiSuggestions(cached.response, cached.candidates)
        } else {
            print("⚠️ RestoreCache: No cache entry found for path: \(imagePath), hint: \(lastTextHint ?? "nil")")
        }
    }

    func clearAICache() {
        guard let imagePath = lastImagePath else { return }

        // Clear from cache
        aiCandidatesCache.clear(imagePath: imagePath, textHint: lastTextHint)

        // Reset context
        lastImagePath = nil
        lastTextHint = nil
    }

    var hasCachedAIResults: Bool {
        guard let imagePath = lastImagePath else {
            print("🔍 HasCache: No lastImagePath, returning false")
            return false
        }
        let hasCache = aiCandidatesCache.get(imagePath: imagePath, textHint: lastTextHint) != nil
        print("🔍 HasCache: Path=\(imagePath), Hint=\(lastTextHint ?? "nil"), Result=\(hasCache)")
        return hasCache
    }

    var isShowingCachedResults: Bool {
        if case .aiSuggestions = state {
            return hasCachedAIResults
        }
        return false
    }

    private func resolveAllCandidates(_ candidates: inout [ResolvedCandidate]) async {
        await withTaskGroup(of: (UUID, ResolutionResult).self) { group in
            for candidate in candidates {
                // Check cache first
                if let cached = resolutionCache.get(
                    title: candidate.original.title,
                    type: candidate.original.type,
                    year: candidate.original.year
                ) {
                    updateCandidate(&candidates, id: candidate.id, result: cached)
                    continue
                }

                // Resolve via API
                group.addTask {
                    let result = await self.resolutionService.resolve(
                        title: candidate.original.title,
                        type: candidate.original.type,
                        year: candidate.original.year
                    )
                    return (candidate.id, result)
                }
            }

            // Collect results
            for await (candidateId, result) in group {
                // Cache result
                if let candidate = candidates.first(where: { $0.id == candidateId }) {
                    resolutionCache.set(
                        title: candidate.original.title,
                        type: candidate.original.type,
                        year: candidate.original.year,
                        result: result
                    )
                }

                updateCandidate(&candidates, id: candidateId, result: result)

                // Update UI incrementally
                if case let .aiSuggestions(response, _) = state {
                    state = .aiSuggestions(response, candidates)
                }
            }
        }
    }

    private func updateCandidate(_ candidates: inout [ResolvedCandidate], id: UUID, result: ResolutionResult) {
        guard let index = candidates.firstIndex(where: { $0.id == id }) else { return }

        switch result {
        case let .resolved(media):
            candidates[index].state = .resolved(media)
        case let .ambiguous(matches):
            candidates[index].state = .ambiguous(matches)
        case let .failed(error):
            candidates[index].state = .failed(error)
        }
    }

    // MARK: - Navigation Handling

    func handleCandidateTap(_ candidate: ResolvedCandidate) -> CandidateTapAction {
        switch candidate.state {
        case let .resolved(media):
            // Save to recent searches
            recentSearchRepo.addMediaSearch(
                mediaId: media.tmdbId,
                mediaType: media.mediaType,
                title: media.matchedTitle
            )
            return .navigateToDetail(media.tmdbId, media.mediaType)

        case let .ambiguous(matches):
            return .showPicker(matches)

        case .failed:
            return .fallbackToSearch(candidate.original.title)

        default:
            return .none
        }
    }

    func handlePickerSelection(match: TMDBMatch) {
        // Save to recent searches
        recentSearchRepo.addMediaSearch(
            mediaId: match.id,
            mediaType: match.mediaType,
            title: match.title
        )
    }

    func handlePickerCancelled(candidateTitle: String) {
        // Fallback to text search (title only for better TMDB results)
        searchQuery = candidateTitle
    }

    func handleRecentSearchTap(_ search: RecentSearch) -> RecentSearchAction {
        if let mediaId = search.mediaId,
           let mediaTypeString = search.mediaType,
           let mediaType = MediaType(rawValue: mediaTypeString)
        {
            // Media-based search
            return .navigateToDetail(mediaId, mediaType)
        } else if let query = search.query {
            // Text-based search
            searchQuery = query
            return .performTextSearch
        }
        return .none
    }

    func reset() {
        searchTask?.cancel()
        searchQuery = ""
        state = .idle
    }
}

// MARK: - Action Types

enum CandidateTapAction {
    case none
    case navigateToDetail(Int, MediaType)
    case showPicker([TMDBMatch])
    case fallbackToSearch(String)
}

enum RecentSearchAction {
    case none
    case navigateToDetail(Int, MediaType)
    case performTextSearch
}
