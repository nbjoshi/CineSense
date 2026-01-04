//
//  MediaResolutionService.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Foundation

final class MediaResolutionService {
    private let httpClient = HTTPClient(
        baseURL: URL(string: "https://api.themoviedb.org/3")!,
        defaultHeaders: [
            "accept": "application/json",
            "Authorization": "Bearer \(TMDBConfig.readAccessToken)",
        ]
    )

    // MARK: - Public API

    /// Resolves a single candidate to TMDB using intelligent matching
    func resolve(
        title: String,
        type: MediaType,
        year: String
    ) async -> ResolutionResult {
        do {
            let matches = try await searchTMDB(title: title, type: type, year: year)

            guard !matches.isEmpty else {
                return .failed(ResolutionError.noMatchFound)
            }

            // Score and rank
            let scoredMatches = scoreMatches(matches, targetTitle: title, targetYear: year, mediaType: type)

            guard let topMatch = scoredMatches.first else {
                return .failed(ResolutionError.noMatchFound)
            }

            // Apply acceptance rules
            let topScore = topMatch.matchScore
            let secondScore = scoredMatches.count > 1 ? scoredMatches[1].matchScore : 0.0

            // Rule 1: High confidence (>= 0.80)
            if topScore >= 0.80 {
                return .resolved(topMatch.toResolvedMedia())
            }

            // Rule 2: Good score with clear margin
            if topScore >= 0.72 && (topScore - secondScore) >= 0.15 {
                return .resolved(topMatch.toResolvedMedia())
            }

            // Rule 3: Ambiguous - show picker
            if topScore >= 0.60 && scoredMatches.count >= 2 {
                let top3 = Array(scoredMatches.prefix(3))
                return .ambiguous(top3)
            }

            // Rule 4: Failed
            return .failed(ResolutionError.lowConfidence)

        } catch {
            return .failed(ResolutionError.networkError(error))
        }
    }

    // MARK: - TMDB Search

    private func searchTMDB(
        title: String,
        type: MediaType,
        year: String
    ) async throws -> [SpecificSearchResult] {
        let path = type == .movie ? "search/movie" : "search/tv"
        let yearKey = type == .movie ? "primary_release_year" : "first_air_date_year"

        let request = APIRequest(
            path: path,
            query: [
                "query": title,
                yearKey: year,
                "language": "en-US",
                "page": "1",
                "include_adult": "false",
            ]
        )

        struct Response: Decodable {
            let results: [SpecificSearchResult]
        }

        let response: Response = try await httpClient.send(request)
        return response.results
    }

    // MARK: - Search Result Types

    private struct SpecificSearchResult: Decodable {
        let id: Int
        let title: String?
        let name: String?
        let releaseDate: String?
        let firstAirDate: String?
        let posterPath: String?
        let voteCount: Int?
        let popularity: Double?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case name
            case releaseDate = "release_date"
            case firstAirDate = "first_air_date"
            case posterPath = "poster_path"
            case voteCount = "vote_count"
            case popularity
        }
    }

    // MARK: - Scoring Algorithm

    private func scoreMatches(
        _ matches: [SpecificSearchResult],
        targetTitle: String,
        targetYear: String,
        mediaType: MediaType
    ) -> [TMDBMatch] {
        // Find max vote count for normalization
        let maxVotes = matches.compactMap { $0.voteCount }.max() ?? 1

        return matches
            .map { result in
                let titleScore = self.calculateTitleSimilarity(
                    result: result.title ?? result.name ?? "",
                    target: targetTitle
                )

                let yearScore = self.calculateYearScore(
                    resultDate: result.releaseDate ?? result.firstAirDate,
                    targetYear: targetYear
                )

                let popularityScore = Double(result.voteCount ?? 0) / Double(maxVotes)

                // Weighted scoring: Title 50%, Year 35%, Popularity 15%
                let finalScore = (titleScore * 0.50) +
                    (yearScore * 0.35) +
                    (popularityScore * 0.15)

                return TMDBMatch(
                    id: result.id,
                    mediaType: mediaType,
                    title: result.title ?? result.name ?? "",
                    year: extractYear(from: result.releaseDate ?? result.firstAirDate),
                    posterPath: result.posterPath,
                    voteCount: result.voteCount ?? 0,
                    popularity: result.popularity ?? 0.0,
                    matchScore: finalScore
                )
            }
            .sorted { $0.matchScore > $1.matchScore }
    }

    // MARK: - Title Similarity

    private func calculateTitleSimilarity(result: String, target: String) -> Double {
        let r = normalize(result)
        let t = normalize(target)

        // Exact match
        if r == t { return 1.0 }

        // Contains match
        if r.contains(t) || t.contains(r) { return 0.90 }

        // Levenshtein distance
        let distance = levenshteinDistance(r, t)
        let maxLen = max(r.count, t.count)
        guard maxLen > 0 else { return 0.0 }

        let similarity = 1.0 - (Double(distance) / Double(maxLen))
        return max(similarity, 0.0)
    }

    // MARK: - Year Scoring

    private func calculateYearScore(resultDate: String?, targetYear: String) -> Double {
        guard let resultDate = resultDate,
              let resultYearString = extractYear(from: resultDate),
              let resultYear = Int(resultYearString),
              let targetYearInt = Int(targetYear)
        else {
            return 0.0
        }

        let diff = abs(resultYear - targetYearInt)
        switch diff {
        case 0: return 1.0 // Exact match
        case 1: return 0.80 // Off by 1 year
        case 2: return 0.50 // Off by 2 years
        default: return 0.0 // Too far off
        }
    }

    // MARK: - Utilities

    private func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "^(the|a|an)\\s+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)
        var dist = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)

        for i in 0 ... s1.count {
            dist[i][0] = i
        }
        for j in 0 ... s2.count {
            dist[0][j] = j
        }

        for i in 1 ... s1.count {
            for j in 1 ... s2.count {
                let cost = s1[i - 1] == s2[j - 1] ? 0 : 1
                dist[i][j] = Swift.min(
                    dist[i - 1][j] + 1, // deletion
                    dist[i][j - 1] + 1, // insertion
                    dist[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return dist[s1.count][s2.count]
    }

    private func extractYear(from dateString: String?) -> String? {
        guard let dateString = dateString, dateString.count >= 4 else { return nil }
        return String(dateString.prefix(4))
    }
}
