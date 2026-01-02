//
//  RecentSearch.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Foundation
import SwiftData

@Model
final class RecentSearch {
    @Attribute(.unique) var id: UUID
    var timestamp: Date

    // For text-based searches
    var query: String?

    // For media-based searches
    var mediaId: Int?
    var mediaType: String? // "movie" or "tv"
    var mediaTitle: String?

    init(query: String) {
        id = UUID()
        timestamp = Date()
        self.query = query
    }

    init(mediaId: Int, mediaType: MediaType, title: String) {
        id = UUID()
        timestamp = Date()
        self.mediaId = mediaId
        self.mediaType = mediaType.rawValue
        mediaTitle = title
    }

    var displayText: String {
        mediaTitle ?? query ?? "Unknown"
    }

    var isMediaSearch: Bool {
        mediaId != nil
    }
}
