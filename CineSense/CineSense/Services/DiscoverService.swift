//
//  DiscoverService.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Foundation

final class DiscoverService {
    private let httpClient = HTTPClient(
        baseURL: URL(string: "https://api.themoviedb.org/3")!,
        defaultHeaders: [
            "accept": "application/json",
            "Authorization": "Bearer \(TMDBConfig.readAccessToken)",
        ]
    )
    // MARK: - Filter Endpoints (Do later)
    // Filtering by movies: https://api.themoviedb.org/3/discover/movie
    // Filtering by shows: https://api.themoviedb.org/3/discover/tv
    
    // MARK: - Now Playing Endpoints
    // https://api.themoviedb.org/3/movie/now_playing
    // Implemenet pagination later
    func getNowPlaying(page: Int = 1) async throws -> Results {
        let req = APIRequest(path: "/movie/now_playing", query: ["page": "\(page)"])
        return try await httpClient.send(req)
    }
    
    // MARK: - Popular Endpoints
    // https://api.themoviedb.org/3/movie/popular
    // https://api.themoviedb.org/3/tv/popular
    func getPopular(mediaType: String) async throws -> Results {
        let req = APIRequest(path: "/\(mediaType)/popular")
        return try await httpClient.send(req)
    }
    
    // MARK: - Top Rated
    // https://api.themoviedb.org/3/movie/top_rated
    // https://api.themoviedb.org/3/tv/top_rated
    func getTopRatedMovies() async throws -> [MediaSummary] {
        let req = APIRequest(path: "/movie/top_rated")
        let response: Results = try await httpClient.send(req)
        return response.results.map { $0.toMediaSummary() }
    }

    func getTopRatedTV() async throws -> [MediaSummary] {
        let req = APIRequest(path: "/tv/top_rated")
        let response: Results = try await httpClient.send(req)
        return response.results.map { $0.toMediaSummary() }
    }

    // MARK: - Upcoming
    // https://api.themoviedb.org/3/movie/upcoming
    func getUpcomingMovies() async throws -> [MediaSummary] {
        let req = APIRequest(path: "/movie/upcoming")
        let response: Results = try await httpClient.send(req)
        return response.results.map { $0.toMediaSummary() }
    }
    
    // MARK: - Trending
    // https://api.themoviedb.org/3/trending/all/{time_window}
    func getTrendingAll(timeWindow: String = "week") async throws -> [MediaSummary] {
        let req = APIRequest(path: "/trending/all/\(timeWindow)")
        let response: Results = try await httpClient.send(req)
        return response.results.map { $0.toMediaSummary() }
    }

    // MARK: - Specific Media Type Popular
    func getPopularMovies() async throws -> [MediaSummary] {
        let req = APIRequest(path: "/movie/popular")
        let response: Results = try await httpClient.send(req)
        return response.results.map { $0.toMediaSummary() }
    }

    func getPopularTV() async throws -> [MediaSummary] {
        let req = APIRequest(path: "/tv/popular")
        let response: Results = try await httpClient.send(req)
        return response.results.map { $0.toMediaSummary() }
    }

    // MARK: - Airing Today / On the Air
    // https://api.themoviedb.org/3/tv/airing_today
    // https://api.themoviedb.org/3/tv/on_the_air
    func getAiringToday() async throws -> [MediaSummary] {
        let req = APIRequest(path: "/tv/airing_today")
        let response: Results = try await httpClient.send(req)
        return response.results.map { $0.toMediaSummary() }
    }

    func getOnTheAir() async throws -> [MediaSummary] {
        let req = APIRequest(path: "/tv/on_the_air")
        let response: Results = try await httpClient.send(req)
        return response.results.map { $0.toMediaSummary() }
    }
}
