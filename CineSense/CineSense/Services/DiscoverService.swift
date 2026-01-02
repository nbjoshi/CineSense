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

    // MARK: - Trending

    func getTrendingAll(timeWindow: TimeWindow = .day) async throws -> [MediaSummary] {
        let request = APIRequest(
            path: "trending/all/\(timeWindow.rawValue)",
            query: ["language": "en-US"]
        )

        let response: TMDBSearchMultiResponse = try await httpClient.send(request)
        return response.results.compactMap { $0.toMediaSummary() }
    }

    func getTrendingMovies(timeWindow: TimeWindow = .day) async throws -> [MediaSummary] {
        let request = APIRequest(
            path: "trending/movie/\(timeWindow.rawValue)",
            query: ["language": "en-US"]
        )

        let response: TMDBSearchMultiResponse = try await httpClient.send(request)
        return response.results.compactMap { $0.toMediaSummary() }
    }

    func getTrendingTV(timeWindow: TimeWindow = .day) async throws -> [MediaSummary] {
        let request = APIRequest(
            path: "trending/tv/\(timeWindow.rawValue)",
            query: ["language": "en-US"]
        )

        let response: TMDBSearchMultiResponse = try await httpClient.send(request)
        return response.results.compactMap { $0.toMediaSummary() }
    }

    // MARK: - Popular

    func getPopularMovies() async throws -> [MediaSummary] {
        let request = APIRequest(
            path: "movie/popular",
            query: ["language": "en-US", "page": "1"]
        )

        let response: TMDBSearchMultiResponse = try await httpClient.send(request)
        return response.results.compactMap { $0.toMediaSummary() }
    }

    func getPopularTV() async throws -> [MediaSummary] {
        let request = APIRequest(
            path: "tv/popular",
            query: ["language": "en-US", "page": "1"]
        )

        let response: TMDBSearchMultiResponse = try await httpClient.send(request)
        return response.results.compactMap { $0.toMediaSummary() }
    }

    // MARK: - Time Window

    enum TimeWindow: String {
        case day
        case week
    }
}
