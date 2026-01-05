//
//  Playlist.swift
//  CineSense
//
//  Created by Neel Joshi on 1/4/26.
//

import Foundation

// MARK: - Visibility Enum
enum PlaylistVisibility: String, Codable {
    case `public`
    case `private`
}

// MARK: - System Key Enum
enum SystemKey: String, Codable, CaseIterable {
    case liked
}

// MARK: - List Role Enum
enum ListRole: String, Codable {
    case owner
    case editor
    case viewer
}

// MARK: - Playlist (DB: playlists)
struct Playlist: Codable, Identifiable, Hashable {
    let id: UUID
    let ownerId: UUID
    let name: String
    let description: String?
    let visibility: PlaylistVisibility
    let systemKey: SystemKey?
    let imagePath: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case description
        case visibility
        case systemKey = "system_key"
        case imagePath = "image_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isSystemPlaylist: Bool {
        systemKey != nil
    }

    var isPublic: Bool {
        visibility == .public
    }

    var displayName: String {
        if let systemKey = systemKey {
            switch systemKey {
            case .liked: return "Liked"
            }
        }
        return name
    }

    var iconName: String {
        if let systemKey = systemKey {
            switch systemKey {
            case .liked: return "heart.fill"
            }
        }
        return "list.bullet"
    }
}

struct NewPlaylist: Encodable {
    let ownerId: UUID
    let name: String
    let description: String?
    let visibility: PlaylistVisibility
    let systemKey: SystemKey?

    enum CodingKeys: String, CodingKey {
        case ownerId = "owner_id"
        case name
        case description
        case visibility
        case systemKey = "system_key"
    }

    init(ownerId: UUID, name: String, description: String? = nil, visibility: PlaylistVisibility = .private, systemKey: SystemKey? = nil) {
        self.ownerId = ownerId
        self.name = name
        self.description = description
        self.visibility = visibility
        self.systemKey = systemKey
    }
}

// Who has access to the playlists (DB: playlist_members)
struct PlaylistMember: Codable {
    let playlistId: UUID
    let userId: UUID
    let role: ListRole
    let addedBy: UUID?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case playlistId = "playlist_id"
        case userId = "user_id"
        case role
        case addedBy = "added_by"
        case createdAt = "created_at"
    }
}

// DB: playlist_items
struct PlaylistItem: Codable, Identifiable {
    let id: UUID
    let playlistId: UUID
    let mediaType: MediaType
    let tmdbId: Int64
    let addedBy: UUID?
    let note: String?
    let sortOrder: Int?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case playlistId = "playlist_id"
        case mediaType = "media_type"
        case tmdbId = "tmdb_id"
        case addedBy = "added_by"
        case note
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}

struct NewPlaylistItem: Encodable {
    let playlistId: UUID
    let mediaType: MediaType
    let tmdbId: Int64
    let addedBy: UUID? // Auto-set by trigger, but can be provided
    let note: String?
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case playlistId = "playlist_id"
        case mediaType = "media_type"
        case tmdbId = "tmdb_id"
        case addedBy = "added_by"
        case note
        case sortOrder = "sort_order"
    }
}
