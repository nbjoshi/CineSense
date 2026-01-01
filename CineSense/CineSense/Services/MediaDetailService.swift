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
        var path: String
        switch mediaType {
        case .movie:
            path =  "movie/\(id)"
        case .tv:
            path =  "tv/\(id)"
        }

        let req = APIRequest(path: path)
        print(path)
        return try await httpClient.send(req)
    }
}
