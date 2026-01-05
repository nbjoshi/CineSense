//
//  PlaylistDetailView.swift
//  CineSense
//
//  Created by Claude Code on 1/4/26.
//

import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist

    @State private var viewModel = SupabaseViewModel()
    private let mediaDetailService = MediaDetailService()

    @State private var mediaDetails: [String: MediaSummary] = [:] // Key: "\(mediaType)_\(tmdbId)"

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.playlistItems.isEmpty {
                ProgressView("Loading items...")
            } else if viewModel.playlistItems.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
        .navigationTitle(playlist.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPlaylistItems()
        }
        .refreshable {
            await loadPlaylistItems()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Items",
            systemImage: "film",
            description: Text("Add movies and shows to this playlist")
        )
    }

    // MARK: - Items List

    private var itemsList: some View {
        List {
            ForEach(viewModel.playlistItems) { item in
                if let mediaSummary = mediaDetails[itemKey(item)] {
                    NavigationLink(value: mediaSummary) {
                        PlaylistItemRow(item: item, mediaSummary: mediaSummary)
                    }
                } else {
                    PlaylistItemRow(item: item, mediaSummary: nil)
                        .task {
                            await loadMediaDetail(for: item)
                        }
                }
            }
            .onDelete { indexSet in
                deleteItems(at: indexSet)
            }
        }
        .navigationDestination(for: MediaSummary.self) { summary in
            MediaDetailView(mediaId: summary.id, mediaType: summary.mediaType)
        }
    }

    // MARK: - Actions

    private func loadPlaylistItems() async {
        await viewModel.loadPlaylistItems(playlistId: playlist.id)

        // Load TMDB metadata for all items
        for item in viewModel.playlistItems {
            await loadMediaDetail(for: item)
        }
    }

    private func loadMediaDetail(for item: PlaylistItem) async {
        let key = itemKey(item)

        // Skip if already loaded
        guard mediaDetails[key] == nil else { return }

        do {
            let detail = try await mediaDetailService.getMediaDetail(id: Int(item.tmdbId), mediaType: item.mediaType)
            mediaDetails[key] = detail.toMediaSummary()
        } catch {
            // Create a placeholder with just the ID
            mediaDetails[key] = MediaSummary(
                id: Int(item.tmdbId),
                mediaType: item.mediaType,
                title: "Unknown",
                releaseDate: nil,
                posterPath: nil
            )
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = viewModel.playlistItems[index]
            Task {
                await viewModel.removeMediaFromPlaylist(
                    tmdbId: Int(item.tmdbId),
                    mediaType: item.mediaType,
                    playlistId: playlist.id,
                    refreshAfter: true
                )
            }
        }
    }

    private func itemKey(_ item: PlaylistItem) -> String {
        "\(item.mediaType.rawValue)_\(item.tmdbId)"
    }
}

// MARK: - Playlist Item Row

private struct PlaylistItemRow: View {
    let item: PlaylistItem
    let mediaSummary: MediaSummary?

    var body: some View {
        HStack(spacing: 12) {
            // Poster
            if let posterURL = mediaSummary?.posterURL {
                AsyncImage(url: posterURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        if mediaSummary == nil {
                            ProgressView()
                        }
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(mediaSummary?.title ?? "Loading...")
                    .font(.body)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let year = mediaSummary?.year {
                        Text(year)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    MediaTypeBadge(mediaType: item.mediaType)
                }

                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        PlaylistDetailView(
            playlist: Playlist(
                id: UUID(),
                ownerId: UUID(),
                name: "My Favorites",
                description: "Best movies",
                visibility: .private,
                systemKey: nil,
                imagePath: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}
