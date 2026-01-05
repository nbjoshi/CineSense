//
//  SupabaseViewModel.swift
//  CineSense
//
//  Created by Neel Joshi on 1/4/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class SupabaseViewModel {

    private let service: SupabaseService

    var playlists: [Playlist] = []
    var selectedPlaylist: Playlist?

    var playlistItems: [PlaylistItem] = []
    var playlistMembers: [PlaylistMember] = []

    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Init
    init(service: SupabaseService = SupabaseService()) {
        self.service = service
    }

    // MARK: - Helpers
    private func setError(_ error: Error) {
        // Keep it simple; you can improve by decoding PostgRESTError messages later
        errorMessage = error.localizedDescription
    }

    // MARK: - Reads

    /// Loads all playlists for current user (system + custom)
    func loadPlaylists() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            playlists = try await service.readPlaylists()
        } catch {
            setError(error)
        }
    }

    /// Loads the items for a playlist (movies/shows saved inside it)
    func loadPlaylistItems(playlistId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            playlistItems = try await service.readPlaylistItems(playlistId: playlistId)
        } catch {
            setError(error)
        }
    }

    /// Check which playlists contain a specific media
    func checkMediaInPlaylists(tmdbId: Int64, mediaType: MediaType) async -> Set<UUID> {
        do {
            return try await service.checkMediaInPlaylists(tmdbId: tmdbId, mediaType: mediaType)
        } catch {
            setError(error)
            return []
        }
    }

    /// Ensure system playlists exist for user
    /// NOTE: This is now a no-op as the "Liked" playlist is auto-created by database trigger
    func ensureSystemPlaylists(userId: UUID) async {
        do {
            try await service.ensureSystemPlaylists(userId: userId)
        } catch {
            // Silently ignore errors for system playlist creation
        }
    }

    /// Loads the members (who can view/edit) for a playlist
    func loadPlaylistMembers(playlistId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            playlistMembers = try await service.readPlaylistMembers(playlistId: playlistId)
        } catch {
            setError(error)
        }
    }

    // MARK: - Create

    /// Creates a playlist and optionally selects it.
    func createPlaylist(_ newPlaylist: NewPlaylist, selectAfterCreate: Bool = true) async {
        print("Create Playlist Called")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let created = try await service.createPlaylist(newPlaylist: newPlaylist)
            playlists.insert(created, at: 0)

            if selectAfterCreate {
                selectedPlaylist = created
            }
        } catch {
            setError(error)
            print(error)
        }
    }

    // MARK: - Update

    func updatePlaylist(
        playlistId: UUID,
        name: String? = nil,
        description: String? = nil,
        visibility: PlaylistVisibility? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let updated = try await service.updatePlaylist(
                playlistId: playlistId,
                name: name,
                description: description,
                visibility: visibility
            )

            // Update local cache
            if let idx = playlists.firstIndex(where: { $0.id == playlistId }) {
                playlists[idx] = updated
            }
            if selectedPlaylist?.id == playlistId {
                selectedPlaylist = updated
            }
        } catch {
            setError(error)
        }
    }

    // MARK: - Delete

    func deletePlaylist(_ playlistId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await service.deletePlaylist(playlistId: playlistId)

            playlists.removeAll { $0.id == playlistId }

            if selectedPlaylist?.id == playlistId {
                selectedPlaylist = nil
                playlistItems = []
                playlistMembers = []
            }
        } catch {
            setError(error)
        }
    }

    // MARK: - Playlist Items

    func addMediaToPlaylist(_ newItem: NewPlaylistItem, refreshAfter: Bool = true) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await service.addMediaToPlaylist(media: newItem)

            // If you don't want to re-fetch, you could append locally
            if refreshAfter {
                playlistItems = try await service.readPlaylistItems(playlistId: newItem.playlistId)
            }
        } catch {
            setError(error)
        }
    }

    func removeMediaFromPlaylist(tmdbId: Int, mediaType: MediaType, playlistId: UUID, refreshAfter: Bool = true) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await service.removeMediaFromPlaylist(
                tmdbId: tmdbId,
                mediaType: mediaType,
                playlistId: playlistId
            )

            if refreshAfter {
                playlistItems = try await service.readPlaylistItems(playlistId: playlistId)
            } else {
                // Local optimistic update
                playlistItems.removeAll { $0.playlistId == playlistId && $0.tmdbId == Int64(tmdbId) && $0.mediaType == mediaType }
            }
        } catch {
            setError(error)
        }
    }

    // MARK: - Selection convenience

    func selectPlaylist(_ playlist: Playlist) {
        selectedPlaylist = playlist
    }

    func clearSelection() {
        selectedPlaylist = nil
        playlistItems = []
        playlistMembers = []
    }
}
