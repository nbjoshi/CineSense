//
//  SupabaseService.swift
//  CineSense
//
//  Created by Neel Joshi on 1/4/26.
//

import Foundation
import Supabase

final class SupabaseService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    // Create a playlist
    func createPlaylist(newPlaylist: NewPlaylist) async throws -> Playlist {
        let session = try await client.auth.session

        return try await client
            .from("playlists")
            .insert(newPlaylist)
            .select()
            .single()
            .execute()
            .value
    }

    // Read members of a playlist
    func readPlaylistMembers(playlistId: UUID) async throws -> [PlaylistMember] {
        try await client
            .from("playlist_members")
            .select()
            .eq("playlist_id", value: playlistId.uuidString)
            .execute()
            .value
    }

    // Delete a playlist safely (delete items first if no cascade)
    func deletePlaylist(playlistId: UUID) async throws {
        _ = try await client
            .from("playlists")
            .delete()
            .eq("id", value: playlistId.uuidString)
            .execute()
    }

    // Add a movie or tv show to the playlist
    func addMediaToPlaylist(media: NewPlaylistItem) async throws {
        _ = try await client
            .from("playlist_items")
            .insert(media)
            .execute()
    }

    // Delete a movie or tv show from a playlist
    func removeMediaFromPlaylist(tmdbId: Int, mediaType: MediaType, playlistId: UUID) async throws {
        _ = try await client
            .from("playlist_items")
            .delete()
            .eq("playlist_id", value: playlistId.uuidString)
            .eq("media_type", value: mediaType.rawValue)
            .eq("tmdb_id", value: tmdbId)
            .execute()
    }

    func readPlaylistItems(playlistId: UUID) async throws -> [PlaylistItem] {
        try await client
            .from("playlist_items")
            .select()
            .eq("playlist_id", value: playlistId.uuidString)
            .order("sort_order", ascending: true)
            .order("created_at", ascending: true)
            .execute()
            .value
    }


    // Update playlist details
    func updatePlaylist(
            playlistId: UUID,
            name: String? = nil,
            description: String? = nil,
            visibility: PlaylistVisibility? = nil
    ) async throws -> Playlist {
        var update: [String: AnyJSON] = [:]
        if let name { update["name"] = .string(name) }
        if let description { update["description"] = .string(description) }
        if let visibility { update["visibility"] = .string(visibility.rawValue) }

        // If nothing to update, just return the current playlist
        if update.isEmpty {
            return try await client
                .from("playlists")
                .select()
                .eq("id", value: playlistId.uuidString)
                .single()
                .execute()
                .value
        }

        return try await client
            .from("playlists")
            .update(update)
            .eq("id", value: playlistId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    // Read all playlists for current user (system + custom)
    func readPlaylists() async throws -> [Playlist] {
        let playlists: [Playlist] = try await client
            .from("playlists")
            .select()
            .order("system_key", ascending: true, nullsFirst: false) // system playlists first
            .order("created_at", ascending: true)
            .execute()
            .value

        return playlists
    }

    // Check if media is in specific playlists (returns set of playlist IDs)
    func checkMediaInPlaylists(tmdbId: Int64, mediaType: MediaType) async throws -> Set<UUID> {
        let items: [PlaylistItem] = try await client
            .from("playlist_items")
            .select()
            .eq("media_type", value: mediaType.rawValue)
            .eq("tmdb_id", value: Int(tmdbId))
            .execute()
            .value

        return Set(items.map { $0.playlistId })
    }

    // Ensure system playlists exist for current user
    // NOTE: This is now handled by the database trigger on auth.users insert
    // The "Liked" playlist is automatically created for new users
    // This function is kept for backwards compatibility but does nothing
    func ensureSystemPlaylists(userId: UUID) async throws {
        // No-op: Liked playlist is auto-created by database trigger
        // Keeping this function to avoid breaking existing code that calls it
    }
}

