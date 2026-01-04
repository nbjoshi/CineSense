//
//  MediaDetailService.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Foundation
import System

final class MediaDetailService {
    let httpClient = HTTPClient(
        baseURL: URL(string: "https://api.themoviedb.org/3")!,
        defaultHeaders: [
            "accept": "application/json",
            "Authorization": "Bearer \(TMDBConfig.readAccessToken)",
        ]
    )

    func getMediaDetail(id: Int, mediaType: MediaType) async throws -> MediaDetail {
        let path = (mediaType == .movie) ? "movie/\(id)" : "tv/\(id)"
        let req = APIRequest(path: path)

        return try await httpClient.send(req)
    }
    
    func getSeasonDetail(id: Int, season: Int) async throws -> SeasonDetails {
        let req = APIRequest(path: "/tv/\(id)/season/\(season)")
        return try await httpClient.send(req)
    }
}
