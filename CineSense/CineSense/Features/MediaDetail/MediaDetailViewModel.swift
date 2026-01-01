//
//  MediaDetailViewModel.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Combine
import Foundation

@MainActor
final class MediaDetailViewModel: ObservableObject {
    enum State {
        case loading
        case loaded(MediaDetail)
        case failed(Error)
    }

    @Published var state: State = .loading

    private let mediaDetailService: MediaDetailService

    init(mediaDetailService: MediaDetailService = MediaDetailService()) {
        self.mediaDetailService = mediaDetailService
    }

    func loadDetail(id: Int, mediaType: MediaType) async {
        state = .loading

        do {
            let detail = try await mediaDetailService.getMediaDetail(id: id, mediaType: mediaType)
            print(detail)
            state = .loaded(detail)
        } catch {
            state = .failed(error)
        }
    }
}
