//
//  Media.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation

enum MediaType: String, Codable, Hashable {
    case movie
    case tv
}

/// Minimal media info for search results and lists
struct MediaSummary: Identifiable, Hashable {
    let id: Int
    let mediaType: MediaType
    let title: String
    let releaseDate: String?
    let posterPath: String?

    var year: String? {
        guard let releaseDate = releaseDate, !releaseDate.isEmpty else { return nil }
        return String(releaseDate.prefix(4))
    }

    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "\(TMDBConfig.imageBaseURL)w342\(posterPath)")
    }
}

/// Full media details
struct MediaDetail: Identifiable {
    let id: Int
    let mediaType: MediaType
    let title: String
    let releaseDate: String?
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let genres: [String]
    let runtime: Int? // minutes (movie only)
    let voteAverage: Double

    var year: String? {
        guard let releaseDate = releaseDate, !releaseDate.isEmpty else { return nil }
        return String(releaseDate.prefix(4))
    }

    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "\(TMDBConfig.imageBaseURL)w500\(posterPath)")
    }

    var backdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "\(TMDBConfig.imageBaseURL)w780\(backdropPath)")
    }
}

// MARK: - Decodable

extension MediaDetail: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case genres
        case runtime
        case voteAverage = "vote_average"
    }

    private struct Genre: Decodable {
        let id: Int
        let name: String
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        overview = try container.decode(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        voteAverage = try container.decode(Double.self, forKey: .voteAverage)

        // Handle movie vs TV differences
        if let movieTitle = try? container.decode(String.self, forKey: .title) {
            // This is a movie
            mediaType = .movie
            title = movieTitle
            releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        } else {
            // This is a TV show
            mediaType = .tv
            title = try container.decode(String.self, forKey: .name)
            releaseDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate)
        }

        // Parse genres from array of objects
        let genreObjects = try container.decode([Genre].self, forKey: .genres)
        genres = genreObjects.map { $0.name }
    }
}
