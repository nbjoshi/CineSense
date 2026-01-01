//
//  SearchView.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.state {
                case .idle:
                    ContentUnavailableView(
                        "Search Movies & TV Shows",
                        systemImage: "magnifyingglass",
                        description: Text("Enter a title to search")
                    )

                case .loading:
                    ProgressView("Searching...")

                case .loaded(let results):
                    List(results) { media in
                        NavigationLink(value: media) {
                            MediaSearchRow(media: media)
                        }
                    }
                    .listStyle(.plain)

                case .empty:
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "film.slash",
                        description: Text("Try a different search term")
                    )

                case .failed(let error):
                    ContentUnavailableView(
                        "Search Failed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.localizedDescription)
                    )
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, prompt: "Movies & TV Shows")
            .navigationDestination(for: MediaSummary.self) { media in
                MediaDetailView(mediaId: media.id, mediaType: media.mediaType)
            }
        }
    }
}

// MARK: - Media Search Row

private struct MediaSearchRow: View {
    let media: MediaSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Poster
            AsyncImage(url: media.posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Title and metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(media.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let year = media.year {
                        Text(year)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    MediaTypeBadge(mediaType: media.mediaType)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Media Type Badge

private struct MediaTypeBadge: View {
    let mediaType: MediaType

    var body: some View {
        Text(mediaType == .movie ? "Movie" : "TV")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(mediaType == .movie ? Color.blue.opacity(0.2) : Color.purple.opacity(0.2))
            .foregroundColor(mediaType == .movie ? .blue : .purple)
            .clipShape(Capsule())
    }
}

#Preview {
    SearchView()
}
