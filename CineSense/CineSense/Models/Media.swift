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
