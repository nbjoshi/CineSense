//
//  ListsTabView.swift
//  CineSense
//
//  Created by Claude Code on 1/4/26.
//

import Auth
import SwiftUI

struct ListsTabView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var viewModel = SupabaseViewModel()

    @State private var showingCreatePlaylist = false
    @State private var newPlaylistName = ""
    @State private var newPlaylistVisibility: PlaylistVisibility = .private

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.playlists.isEmpty {
                    ProgressView("Loading playlists...")
                } else if viewModel.playlists.isEmpty {
                    emptyState
                } else {
                    playlistsList
                }
            }
            .navigationTitle("Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePlaylist = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlaylist) {
                createPlaylistSheet
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Playlists Yet",
            systemImage: "list.bullet",
            description: Text("Create a playlist to organize your movies and shows")
        )
    }

    // MARK: - Playlists List

    private var playlistsList: some View {
        List {
            let systemLists = viewModel.playlists.filter { $0.isSystemPlaylist }
            let customLists = viewModel.playlists.filter { !$0.isSystemPlaylist }

            if !systemLists.isEmpty {
                Section("System Lists") {
                    ForEach(systemLists) { playlist in
                        NavigationLink(value: playlist) {
                            playlistRow(playlist)
                        }
                    }
                }
            }

            if !customLists.isEmpty {
                Section("My Playlists") {
                    ForEach(customLists) { playlist in
                        NavigationLink(value: playlist) {
                            playlistRow(playlist)
                        }
                    }
                    .onDelete { indexSet in
                        deleteCustomPlaylists(at: indexSet, from: customLists)
                    }
                }
            }
        }
        .navigationDestination(for: Playlist.self) { playlist in
            PlaylistDetailView(playlist: playlist)
        }
    }

    private func playlistRow(_ playlist: Playlist) -> some View {
        HStack(spacing: 12) {
            Image(systemName: playlist.iconName)
                .foregroundColor(playlist.isSystemPlaylist ? .accentColor : .secondary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.displayName)
                    .font(.body)

                if let description = playlist.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if playlist.visibility == .public {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                        Text("Public")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Create Playlist Sheet

    private var createPlaylistSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $newPlaylistName)
                }

                Section {
                    Picker("Visibility", selection: $newPlaylistVisibility) {
                        Text("Private").tag(PlaylistVisibility.private)
                        Text("Public").tag(PlaylistVisibility.public)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        resetCreateForm()
                        showingCreatePlaylist = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await createPlaylist()
                        }
                    }
                    .disabled(newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
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
    }

    private func createPlaylist() async {
        guard let userId = sessionStore.session?.user.id else { return }
        guard !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newPlaylist = NewPlaylist(
            ownerId: UUID(uuidString: userId.uuidString)!,
            name: newPlaylistName,
            description: nil,
            visibility: newPlaylistVisibility
        )

        await viewModel.createPlaylist(newPlaylist, selectAfterCreate: false)

        resetCreateForm()
        showingCreatePlaylist = false

        // Reload to show the new playlist
        await viewModel.loadPlaylists()
    }

    private func deleteCustomPlaylists(at offsets: IndexSet, from customLists: [Playlist]) {
        for index in offsets {
            let playlist = customLists[index]
            Task {
                await viewModel.deletePlaylist(playlist.id)
            }
        }
    }

    private func resetCreateForm() {
        newPlaylistName = ""
        newPlaylistVisibility = .private
    }
}

#Preview {
    ListsTabView()
        .environmentObject(SessionStore())
}
