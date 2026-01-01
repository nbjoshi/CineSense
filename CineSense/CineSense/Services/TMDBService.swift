//
//  TMDBService.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation

enum TMDBError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to decode response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
}

final class TMDBService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Search

    func searchMulti(query: String) async throws -> [MediaSummary] {
        guard !query.isEmpty else { return [] }

        var components = URLComponents(url: TMDBConfig.baseURL.appendingPathComponent("search/multi"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: TMDBConfig.apiKey),
            URLQueryItem(name: "query", value: query)
        ]

        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let searchResponse = try JSONDecoder().decode(TMDBSearchMultiResponse.self, from: data)
            // Filter out person results and convert to domain models
            return searchResponse.results
                .compactMap { $0.toMediaSummary() }
        } catch {
            throw TMDBError.decodingError(error)
        }
    }

    // MARK: - Movie Detail

    func getMovieDetail(id: Int) async throws -> MediaDetail {
        var components = URLComponents(url: TMDBConfig.baseURL.appendingPathComponent("movie/\(id)"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: TMDBConfig.apiKey)
        ]

        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let movieDetail = try JSONDecoder().decode(TMDBMovieDetail.self, from: data)
            return movieDetail.toMediaDetail()
        } catch {
            throw TMDBError.decodingError(error)
        }
    }

    // MARK: - TV Detail

    func getTVDetail(id: Int) async throws -> MediaDetail {
        var components = URLComponents(url: TMDBConfig.baseURL.appendingPathComponent("tv/\(id)"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: TMDBConfig.apiKey)
        ]

        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let tvDetail = try JSONDecoder().decode(TMDBTVDetail.self, from: data)
            return tvDetail.toMediaDetail()
        } catch {
            throw TMDBError.decodingError(error)
        }
    }

    // MARK: - Helper

    func getMediaDetail(id: Int, mediaType: MediaType) async throws -> MediaDetail {
        switch mediaType {
        case .movie:
            return try await getMovieDetail(id: id)
        case .tv:
            return try await getTVDetail(id: id)
        }
    }
}
