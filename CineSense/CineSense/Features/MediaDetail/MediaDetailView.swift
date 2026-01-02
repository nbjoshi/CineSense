//
//  MediaDetailView.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import SwiftUI

struct MediaDetailView: View {
    let mediaId: Int
    let mediaType: MediaType

    @StateObject private var viewModel = MediaDetailViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading...")

            case let .loaded(detail):
                DetailContent(detail: detail)

            case let .failed(error):
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            }
        }
        .task {
            await viewModel.loadDetail(id: mediaId, mediaType: mediaType)
        }
    }
}

// MARK: - Detail Content

private struct DetailContent: View {
    let detail: MediaDetail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Backdrop or Poster Header
                if let backdropURL = detail.backdropURL {
                    AsyncImage(url: backdropURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay {
                                ProgressView()
                            }
                    }
                    .frame(height: 200)
                    .clipped()
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Title and Year
                    VStack(alignment: .leading, spacing: 4) {
                        Text(detail.title)
                            .font(.title)
                            .fontWeight(.bold)

                        HStack(spacing: 8) {
                            if let year = detail.year {
                                Text(year)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            MediaTypeBadge(mediaType: detail.mediaType)

                            if let runtime = detail.runtime {
                                Text("\(runtime) min")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Action Buttons
                    HStack(spacing: 12) {
                        ActionButton(icon: "plus", label: "Watchlist")
                        ActionButton(icon: "heart", label: "Favorite")
                        ActionButton(icon: "square.and.arrow.up", label: "Share")
                    }

                    // Genres
                    if !detail.genres.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(detail.genres, id: \.self) { genre in
                                    Text(genre)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Rating
                    if detail.voteAverage > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", detail.voteAverage))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("/ 10")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Overview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.headline)

                        Text(detail.overview.isEmpty ? "No overview available." : detail.overview)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let label: String

    var body: some View {
        Button {
            // TODO: Implement action
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MediaDetailView(mediaId: 550, mediaType: .movie)
    }
}
