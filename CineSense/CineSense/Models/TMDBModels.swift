//
//  TMDBModels.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation

// MARK: - Search Multi Response

struct TMDBSearchMultiResponse: Decodable {
    let results: [TMDBSearchResult]
}

struct TMDBSearchResult: Decodable {
    let id: Int
    let mediaType: String
    let title: String?
    let name: String?
    let releaseDate: String?
    let firstAirDate: String?
    let posterPath: String?
    let voteCount: Int?
    let popularity: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case mediaType = "media_type"
        case title
        case name
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case posterPath = "poster_path"
        case voteCount = "vote_count"
        case popularity
    }

    func toMediaSummary() -> MediaSummary? {
        guard let type = MediaType(rawValue: mediaType) else { return nil }
        let displayTitle = type == .movie ? title : name
        guard let displayTitle = displayTitle else { return nil }

        let date = type == .movie ? releaseDate : firstAirDate

        return MediaSummary(
            id: id,
            mediaType: type,
            title: displayTitle,
            releaseDate: date,
            posterPath: posterPath
        )
    }
}

// MARK: - Movie Detail Response

struct TMDBMovieDetail: Decodable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: String?
    let posterPath: String?
    let backdropPath: String?
    let genres: [TMDBGenre]
    let runtime: Int?
    let voteAverage: Double

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case genres
        case runtime
        case voteAverage = "vote_average"
    }

    func toMediaDetail() -> MediaDetail {
        MediaDetail(
            id: id,
            mediaType: .movie,
            title: title,
            releaseDate: releaseDate,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            genres: genres.map(\.name),
            runtime: runtime,
            voteAverage: voteAverage
        )
    }
}

// MARK: - TV Detail Response

struct TMDBTVDetail: Decodable {
    let id: Int
    let name: String
    let overview: String
    let firstAirDate: String?
    let posterPath: String?
    let backdropPath: String?
    let genres: [TMDBGenre]
    let voteAverage: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case firstAirDate = "first_air_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case genres
        case voteAverage = "vote_average"
    }

    func toMediaDetail() -> MediaDetail {
        MediaDetail(
            id: id,
            mediaType: .tv,
            title: name,
            releaseDate: firstAirDate,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            genres: genres.map(\.name),
            runtime: nil,
            voteAverage: voteAverage
        )
    }
}

// MARK: - Shared Types

struct TMDBGenre: Decodable {
    let id: Int
    let name: String
}
