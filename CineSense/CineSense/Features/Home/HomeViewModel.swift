//
//  HomeViewModel.swift
//  CineSense
//
//  Created by Claude Code on 1/2/26.
//

import Combine
import Foundation

/// Per-rail loadable state
enum RailState {
    case idle
    case loading
    case loaded([MediaSummary])
    case empty
    case failed(Error)
}

/// HomeViewModel: fetches data for all rails using parallel TaskGroup
/// Per docs/architecture/mvvm.md: ViewModels handle state; Services handle IO
@MainActor
final class HomeViewModel: ObservableObject {
    // Per-rail states for granular loading/error handling
    @Published var nowPlayingState: RailState = .idle
    @Published var popularState: RailState = .idle
    @Published var trendingState: RailState = .idle
    @Published var popularMoviesState: RailState = .idle
    @Published var popularTVState: RailState = .idle
    @Published var topRatedState: RailState = .idle
    @Published var upcomingState: RailState = .idle
    @Published var onAirState: RailState = .idle

    private let discoverService: DiscoverService

    init(discoverService: DiscoverService = DiscoverService()) {
        self.discoverService = discoverService
    }

    /// Load all rails in parallel using TaskGroup
    /// Per docs/features/home.md: progressive rendering, loads quickly
    func loadAllRails() async {
        // Set all to loading
        nowPlayingState = .loading
        popularState = .loading
        trendingState = .loading
        popularMoviesState = .loading
        popularTVState = .loading
        topRatedState = .loading
        upcomingState = .loading
        onAirState = .loading

        await withTaskGroup(of: Void.self) { group in
            // Recommended (using popular as proxy for now)
            group.addTask { await self.loadNowPlaying() }
            
            group.addTask { await self.loadPopular() }

            // Trending
            group.addTask { await self.loadTrending() }

            // Popular Movies
            group.addTask { await self.loadPopularMovies() }

            // Popular TV
            group.addTask { await self.loadPopularTV() }

            // Top Rated (combined movies + TV)
            group.addTask { await self.loadTopRated() }

            // Upcoming Movies
            group.addTask { await self.loadUpcoming() }

            // On Air TV
            group.addTask { await self.loadOnAir() }
        }
    }

    // MARK: - Individual Rail Loaders
    
    private func loadNowPlaying() async {
        do {
            let results = try await discoverService.getNowPlaying()
            let media = results.results.map { $0.toMediaSummary() }
            nowPlayingState = media.isEmpty ? .empty : .loaded(media)
        } catch {
            nowPlayingState = .failed(error)
        }
    }

    private func loadPopular() async {
        do {
            // Proxy: use popular for now
            let results = try await discoverService.getPopular(mediaType: "movie")
            let media = results.results.map { $0.toMediaSummary() }
            popularState = media.isEmpty ? .empty : .loaded(media)
        } catch {
            popularState = .failed(error)
        }
    }

    private func loadTrending() async {
        do {
            let media = try await discoverService.getTrendingAll()
            trendingState = media.isEmpty ? .empty : .loaded(media)
        } catch {
            trendingState = .failed(error)
        }
    }

    private func loadPopularMovies() async {
        do {
            let media = try await discoverService.getPopularMovies()
            popularMoviesState = media.isEmpty ? .empty : .loaded(media)
        } catch {
            popularMoviesState = .failed(error)
        }
    }

    private func loadPopularTV() async {
        do {
            let media = try await discoverService.getPopularTV()
            popularTVState = media.isEmpty ? .empty : .loaded(media)
        } catch {
            popularTVState = .failed(error)
        }
    }

    private func loadTopRated() async {
        do {
            // Combine top rated movies + TV
            async let movies = discoverService.getTopRatedMovies()
            async let tv = discoverService.getTopRatedTV()

            let allMedia = try await movies + tv
            topRatedState = allMedia.isEmpty ? .empty : .loaded(allMedia)
        } catch {
            topRatedState = .failed(error)
        }
    }

    private func loadUpcoming() async {
        do {
            let media = try await discoverService.getUpcomingMovies()
            upcomingState = media.isEmpty ? .empty : .loaded(media)
        } catch {
            upcomingState = .failed(error)
        }
    }

    private func loadOnAir() async {
        do {
            let media = try await discoverService.getOnTheAir()
            onAirState = media.isEmpty ? .empty : .loaded(media)
        } catch {
            onAirState = .failed(error)
        }
    }

    /// Refresh all rails
    func refresh() async {
        await loadAllRails()
    }
}
