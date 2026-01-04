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
    @Published var seasonDetails: SeasonDetails?
    private let mediaDetailService: MediaDetailService

    init(mediaDetailService: MediaDetailService = MediaDetailService()) {
        self.mediaDetailService = mediaDetailService
        self.seasonDetails = nil
    }

    func loadDetail(id: Int, mediaType: MediaType) async {
        state = .loading
        print("Id: \(id)")
        print("MediaType: \(mediaType)")
        
        do {
            let detail = try await mediaDetailService.getMediaDetail(id: id, mediaType: mediaType)
            state = .loaded(detail)
        } catch {
            print(error)
            state = .failed(error)
        }
    }
    
    func loadSeasonDetails(id: Int, season: Int) async {
        do {
            seasonDetails = try await mediaDetailService.getSeasonDetail(id: id, season: season)
        } catch {
            state = .failed(error)
        }
    }
}
