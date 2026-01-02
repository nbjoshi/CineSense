//
//  SearchService.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation

final class SearchService {
    let httpClient = HTTPClient(
        baseURL: URL(string: "https://api.themoviedb.org/3")!,
        defaultHeaders: [
            "accept": "application/json",
            "Authorization": "Bearer \(TMDBConfig.readAccessToken)",
        ]
    )

    // MARK: - Search

    // Implement Pagination Later
    func multiSearch(query: String, page: Int = 1) async throws -> TMDBSearchMultiResponse {
        let req = APIRequest(
            path: "search/multi",
            query: [
                "query": query,
                "page": String(page),
                "language": "en-US",
            ]
        )
        return try await httpClient.send(req)
    }
}
