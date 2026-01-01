//
//  MediaDetailViewModel.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation
import Combine

@MainActor
final class MediaDetailViewModel: ObservableObject {
    enum State {
        case loading
        case loaded(MediaDetail)
        case failed(Error)
    }

    @Published var state: State = .loading

    private let tmdbService: TMDBService

    init(tmdbService: TMDBService = TMDBService()) {
        self.tmdbService = tmdbService
    }

    func loadDetail(id: Int, mediaType: MediaType) async {
        state = .loading

        do {
            let detail = try await tmdbService.getMediaDetail(id: id, mediaType: mediaType)
            state = .loaded(detail)
        } catch {
            state = .failed(error)
        }
    }
}
