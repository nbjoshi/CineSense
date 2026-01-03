//
//  HomeView.swift
//  CineSense
//
//  Created by Claude Code on 1/2/26.
//

import SwiftUI

/// Spotify-style Home with horizontal rails
/// Per docs/architecture/navigation-and-ui.md: Full-bleed, no default nav titles
/// Per docs/features/home.md: NO search UI on Home (Search is separate tab)
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: DS.xl) {
                    // Header spacer for safe area
                    Color.clear
                        .frame(height: 1)
                        .padding(.top, DS.xs)
                    
                    // Now Playing Rail
                    RailSection(title: "Now Playing", state: viewModel.nowPlayingState, onTap: handleMediaTap)

                    // Recommended Rail
                    RailSection(
                        title: "Popular",
                        state: viewModel.popularState,
                        onTap: handleMediaTap
                    )

                    // Trending Rail
                    RailSection(
                        title: "Trending Now",
                        state: viewModel.trendingState,
                        onTap: handleMediaTap
                    )

                    // Popular Movies Rail
                    RailSection(
                        title: "Popular Movies",
                        state: viewModel.popularMoviesState,
                        onTap: handleMediaTap
                    )

                    // Popular TV Rail
                    RailSection(
                        title: "Popular TV Shows",
                        state: viewModel.popularTVState,
                        onTap: handleMediaTap
                    )

                    // Top Rated Rail
                    RailSection(
                        title: "Top Rated",
                        state: viewModel.topRatedState,
                        onTap: handleMediaTap
                    )

                    // Upcoming Movies Rail
                    RailSection(
                        title: "Coming Soon",
                        state: viewModel.upcomingState,
                        onTap: handleMediaTap
                    )

                    // On Air TV Rail
                    RailSection(
                        title: "Shows On the Air",
                        state: viewModel.onAirState,
                        onTap: handleMediaTap
                    )

                    // Bottom padding
                    Color.clear.frame(height: DS.lg)
                }
            }
            .csAppBackground()
            // Per docs/architecture/navigation-and-ui.md: No default navigation titles
            .navigationDestination(for: MediaSummary.self) { media in
                MediaDetailView(mediaId: media.id, mediaType: media.mediaType)
            }
            .task {
                if case .idle = viewModel.popularState {
                    await viewModel.loadAllRails()
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private func handleMediaTap(_ media: MediaSummary) {
        navigationPath.append(media)
    }
}

// MARK: - Rail Section

private struct RailSection: View {
    let title: String
    let state: RailState
    let onTap: (MediaSummary) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            // Section Header
            SectionHeaderView(title: title)

            // Rail Content (loading/loaded/error)
            railContent
        }
    }

    @ViewBuilder
    private var railContent: some View {
        switch state {
        case .idle:
            EmptyView()

        case .loading:
            RailSkeletonView()

        case let .loaded(media):
            MediaRailView(media: media, onTap: onTap)

        case .empty:
            Text("No content available")
                .font(.spSubhead)
                .foregroundStyle(DS.Colors.textSecondary)
                .padding(.horizontal, DS.md)

        case let .failed(error):
            VStack(alignment: .leading, spacing: DS.xs) {
                Text("Failed to load")
                    .font(.spSubhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Colors.danger)

                Text(error.localizedDescription)
                    .font(.spCaption)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .padding(.horizontal, DS.md)
        }
    }
}

#Preview {
    HomeView()
}
