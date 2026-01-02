//
//  Resolution.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Foundation
import SwiftUI

// MARK: - Resolution Result

/// Result of resolving an AI candidate to TMDB
enum ResolutionResult {
    case resolved(ResolvedMedia)
    case ambiguous([TMDBMatch])
    case failed(Error)

    var isResolved: Bool {
        if case .resolved = self { return true }
        return false
    }

    var isAmbiguous: Bool {
        if case .ambiguous = self { return true }
        return false
    }
}

// MARK: - TMDB Match

/// A single TMDB match with metadata
struct TMDBMatch: Identifiable, Equatable {
    let id: Int
    let mediaType: MediaType
    let title: String
    let year: String?
    let posterPath: String?
    let voteCount: Int
    let popularity: Double
    let matchScore: Double

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "\(TMDBConfig.imageBaseURL)w342\(path)")
    }

    var thumbnailURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "\(TMDBConfig.imageBaseURL)w185\(path)")
    }

    static func == (lhs: TMDBMatch, rhs: TMDBMatch) -> Bool {
        lhs.id == rhs.id && lhs.mediaType == rhs.mediaType
    }
}

// MARK: - Resolved Media

/// Final resolved media with high confidence
struct ResolvedMedia: Equatable {
    let tmdbId: Int
    let mediaType: MediaType
    let matchedTitle: String
    let matchedYear: String?
    let posterPath: String?
    let matchConfidence: Double

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "\(TMDBConfig.imageBaseURL)w185\(path)")
    }

    var confidenceLevel: ConfidenceLevel {
        switch matchConfidence {
        case 0.85 ... 1.0: return .high
        case 0.75 ..< 0.85: return .medium
        default: return .low
        }
    }

    enum ConfidenceLevel: String, CaseIterable {
        case high = "High"
        case medium = "Med"
        case low = "Low"

        var color: Color {
            switch self {
            case .high: return .green
            case .medium: return .blue
            case .low: return .orange
            }
        }

        var icon: String {
            switch self {
            case .high: return "checkmark.circle.fill"
            case .medium: return "checkmark.circle"
            case .low: return "exclamationmark.circle"
            }
        }
    }

    static func == (lhs: ResolvedMedia, rhs: ResolvedMedia) -> Bool {
        lhs.tmdbId == rhs.tmdbId && lhs.mediaType == rhs.mediaType
    }
}

// MARK: - Resolved Candidate

/// Candidate with resolution state
struct ResolvedCandidate: Identifiable {
    let id: UUID
    let original: Candidate
    var state: State

    enum State {
        case pending
        case resolving
        case resolved(ResolvedMedia)
        case ambiguous([TMDBMatch])
        case failed(Error)
    }

    init(from candidate: Candidate) {
        id = candidate.id
        original = candidate
        state = .pending
    }

    var posterURL: URL? {
        switch state {
        case let .resolved(media):
            return media.posterURL
        case let .ambiguous(matches):
            return matches.first?.thumbnailURL
        default:
            return nil
        }
    }

    var isInteractable: Bool {
        switch state {
        case .resolved, .ambiguous:
            return true
        case .failed:
            return true // Allow tap to fallback to search
        default:
            return false
        }
    }

    var resolvedMedia: ResolvedMedia? {
        if case let .resolved(media) = state {
            return media
        }
        return nil
    }

    var ambiguousMatches: [TMDBMatch]? {
        if case let .ambiguous(matches) = state {
            return matches
        }
        return nil
    }
}

// MARK: - Resolution Error

enum ResolutionError: LocalizedError {
    case noMatchFound
    case lowConfidence
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noMatchFound:
            return "No matches found in TMDB"
        case .lowConfidence:
            return "Match confidence too low"
        case let .networkError(error):
            return error.localizedDescription
        }
    }
}

// MARK: - Extensions

extension TMDBMatch {
    func toResolvedMedia() -> ResolvedMedia {
        ResolvedMedia(
            tmdbId: id,
            mediaType: mediaType,
            matchedTitle: title,
            matchedYear: year,
            posterPath: posterPath,
            matchConfidence: matchScore
        )
    }
}
