//
//  AddToPlaylistSheet.swift
//  CineSense
//
//  Created by Claude Code on 1/4/26.
//

import Auth
import SwiftUI

struct AddToPlaylistSheet: View {
    let tmdbId: Int
    let mediaType: MediaType

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionStore: SessionStore
    @State private var viewModel = SupabaseViewModel()

    @State private var playlistsContainingMedia: Set<UUID> = []
    @State private var newPlaylistName = ""
    @State private var newPlaylistVisibility: PlaylistVisibility = .private
    @State private var isCreatingPlaylist = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Create new playlist section
                createPlaylistSection
                    .padding(.horizontal)
                    .padding(.top)

                Divider()
                    .padding(.vertical, 12)

                // Existing playlists
                if viewModel.isLoading && viewModel.playlists.isEmpty {
                    ProgressView("Loading playlists...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.playlists.isEmpty {
                    ContentUnavailableView(
                        "No Playlists Yet",
                        systemImage: "list.bullet",
                        description: Text("Create your first playlist above")
                    )
                } else {
                    playlistsList
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Create Playlist Section

    private var createPlaylistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create New Playlist")
                .font(.headline)

            TextField("Playlist name", text: $newPlaylistName)
                .textFieldStyle(.roundedBorder)

            Picker("Visibility", selection: $newPlaylistVisibility) {
                Text("Private").tag(PlaylistVisibility.private)
                Text("Public").tag(PlaylistVisibility.public)
            }
            .pickerStyle(.segmented)

            Button {
                Task { await createPlaylist() }
            } label: {
                if isCreatingPlaylist {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Create")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty || isCreatingPlaylist)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Playlists List

    private var playlistsList: some View {
        List {
            // System playlists first
            let systemLists = viewModel.playlists.filter { $0.isSystemPlaylist }
            let customLists = viewModel.playlists.filter { !$0.isSystemPlaylist }

            if !systemLists.isEmpty {
                Section("System Lists") {
                    ForEach(systemLists) { playlist in
                        playlistRow(playlist)
                    }
                }
            }

            if !customLists.isEmpty {
                Section("My Playlists") {
                    ForEach(customLists) { playlist in
                        playlistRow(playlist)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func playlistRow(_ playlist: Playlist) -> some View {
        let isSelected = playlistsContainingMedia.contains(playlist.id)

        return HStack {
            Image(systemName: playlist.iconName)
                .foregroundColor(playlist.isSystemPlaylist ? .accentColor : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.displayName)
                    .font(.body)

                if playlist.visibility == .public {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                        Text("Public")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                Task {
                    await toggleMediaInPlaylist(playlist)
                }
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await toggleMediaInPlaylist(playlist)
            }
        }
    }

    // MARK: - Actions

    private func loadData() async {
        guard let userId = sessionStore.session?.user.id else { return }

        // Ensure system playlists exist (this is now a no-op)
        await viewModel.ensureSystemPlaylists(userId: UUID(uuidString: userId.uuidString)!)

        // Load all playlists
        await viewModel.loadPlaylists()

        // Check which playlists contain this media
        playlistsContainingMedia = await viewModel.checkMediaInPlaylists(
            tmdbId: Int64(tmdbId),
            mediaType: mediaType
        )
    }

    private func createPlaylist() async {
        guard let userId = sessionStore.session?.user.id else { return }
        guard !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isCreatingPlaylist = true
        defer { isCreatingPlaylist = false }

        let newPlaylist = NewPlaylist(
            ownerId: UUID(uuidString: userId.uuidString)!,
            name: newPlaylistName,
            description: nil,
            visibility: newPlaylistVisibility
        )

        await viewModel.createPlaylist(newPlaylist, selectAfterCreate: false)

        // Reset form
        newPlaylistName = ""
        newPlaylistVisibility = .private

        // Reload playlists to show the new one
        await viewModel.loadPlaylists()
    }

    private func toggleMediaInPlaylist(_ playlist: Playlist) async {
        guard let userId = sessionStore.session?.user.id else { return }

        let isCurrentlyInPlaylist = playlistsContainingMedia.contains(playlist.id)

        if isCurrentlyInPlaylist {
            // Remove from playlist
            await viewModel.removeMediaFromPlaylist(
                tmdbId: tmdbId,
                mediaType: mediaType,
                playlistId: playlist.id,
                refreshAfter: false
            )
            playlistsContainingMedia.remove(playlist.id)
        } else {
            // Add to playlist
            let newItem = NewPlaylistItem(
                playlistId: playlist.id,
                mediaType: mediaType,
                tmdbId: Int64(tmdbId),
                addedBy: UUID(uuidString: userId.uuidString)!,
                note: nil,
                sortOrder: nil
            )

            await viewModel.addMediaToPlaylist(newItem, refreshAfter: false)
            playlistsContainingMedia.insert(playlist.id)
        }
    }
}

#Preview {
    AddToPlaylistSheet(tmdbId: 550, mediaType: .movie)
        .environmentObject(SessionStore())
}
