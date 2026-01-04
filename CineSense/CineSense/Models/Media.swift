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

struct Season: Identifiable, Codable, Hashable {
    let episodeCount: Int
    let id: Int
    let seasonNumber: Int
    let posterPath: String
    let overview: String
    
    enum CodingKeys: String, CodingKey {
        case episodeCount = "episode_count"
        case seasonNumber = "season_number"
        case id
        case posterPath = "poster_path"
        case overview = "overview"
    }
}

struct SeasonDetails: Codable, Identifiable {
    let id: Int
    let episodes: [Episode]
}

struct Episode: Codable, Identifiable {
    let airDate: String
    let episodeNumber: Int
    let id: Int
    let name: String
    let overview: String
    let runtime: Int
    let seasonNumber: Int
    let stillPath: String?
    
    enum CodingKeys: String, CodingKey {
        case airDate = "air_date"
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case id
        case name
        case overview
        case runtime
        case stillPath = "still_path"
    }
}

/// Full media details
struct MediaDetail: Identifiable, Decodable {
    let id: Int
    var mediaType: MediaType
    let title: String
    let releaseDate: String?
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let genres: [String]
    let runtime: Int? // minutes (movie only)
    let voteAverage: Double
    
    // TV-only (auto-decodes from top-level fields)
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let seasons: [Season]?
    
    enum CodingKeys: String, CodingKey {
            case id
            case overview
            case posterPath = "poster_path"
            case backdropPath = "backdrop_path"
            case runtime
            case voteAverage = "vote_average"
            case numberOfSeasons = "number_of_seasons"
            case numberOfEpisodes = "number_of_episodes"
            case seasons
            // plus whatever you use for title/releaseDate/genres (see note below)
            case title, name
            case releaseDate = "release_date"
            case firstAirDate = "first_air_date"
            case genres
        }
    
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

    func toMediaSummary() -> MediaSummary {
        MediaSummary(
            id: id,
            mediaType: mediaType,
            title: title,
            releaseDate: releaseDate,
            posterPath: posterPath
        )
    }
}

// MARK: - Decodable

extension MediaDetail {
    private struct Genre: Decodable {
        let id: Int
        let name: String
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)

        // List endpoints don't include overview; detail endpoints do
        overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""

        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0.0

        // ✅ Assign TV-only fields (will be nil for movies)
        numberOfSeasons = try container.decodeIfPresent(Int.self, forKey: .numberOfSeasons)
        numberOfEpisodes = try container.decodeIfPresent(Int.self, forKey: .numberOfEpisodes)
        seasons = try container.decodeIfPresent([Season].self, forKey: .seasons)

        // Handle movie vs TV differences
        if let movieTitle = try? container.decode(String.self, forKey: .title) {
        // This is a movie
        mediaType = .movie
        title = movieTitle
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate) } else {
        // This is a TV show
        mediaType = .tv
        title = try container.decode(String.self, forKey: .name)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate) }

        let genreObjects = try container.decodeIfPresent([Genre].self, forKey: .genres) ?? []
        genres = genreObjects.map { $0.name }
    }
}

struct Results: Decodable {
    let page: Int
    let results: [MediaDetail]
}
