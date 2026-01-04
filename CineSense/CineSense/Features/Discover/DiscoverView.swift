//
//  DiscoverView.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import PhotosUI
import SwiftData
import SwiftUI

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DiscoverViewModel

    @State private var showAIPicker = false
    @State private var showAmbiguityPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var aiTextHint = ""
    @State private var ambiguousMatches: [TMDBMatch] = []
    @State private var navigationPath = NavigationPath()
    @FocusState private var isSearchFocused: Bool

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: DiscoverViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(
                    query: $viewModel.searchQuery,
                    isSearchFocused: $isSearchFocused,
                    onAITap: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()

                        // ✅ Check cache before showing picker
                        // If we have cached AI results from a previous search, restore them
                        // Otherwise, show the photo picker for a new AI search
                        if viewModel.hasCachedAIResults {
                            print("🔍 AI Button: Cache exists, restoring cached results")
                            viewModel.restoreCachedAIResults()
                        } else {
                            print("🔍 AI Button: No cache, showing picker")
                            showAIPicker = true
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                // Content
                contentView
            }
            .background(Color(.systemGroupedBackground))
            // Per docs/architecture/navigation-and-ui.md:
            // No default navigation titles; use custom in-view headers
            .navigationDestination(for: MediaSummary.self) { media in
                MediaDetailView(mediaId: media.id, mediaType: media.mediaType)
            }
            .sheet(isPresented: $showAIPicker, onDismiss: {
                // Reset picker state when dismissed
                selectedPhoto = nil
                aiTextHint = ""
            }) {
                AIPhotoPickerSheet(
                    selectedPhoto: $selectedPhoto,
                    textHint: $aiTextHint,
                    onSubmit: { data, contentType in
                        Task {
                            await viewModel.performAISearch(
                                imageData: data,
                                contentType: contentType,
                                textHint: aiTextHint.isEmpty ? nil : aiTextHint
                            )
                            // Dismiss sheet after starting AI search
                            showAIPicker = false
                        }
                    }
                )
            }
            .sheet(isPresented: $showAmbiguityPicker) {
                AmbiguityPickerSheet(
                    matches: ambiguousMatches,
                    onSelect: { match in
                        viewModel.handlePickerSelection(match: match)
                        navigationPath.append(MediaSummary(
                            id: match.id,
                            mediaType: match.mediaType,
                            title: match.title,
                            releaseDate: match.year,
                            posterPath: match.posterPath
                        ))
                    },
                    onCancel: {
                        if let first = ambiguousMatches.first {
                            viewModel.handlePickerCancelled(candidateTitle: first.title)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        // Show recent searches when search bar is focused and query is empty
        if isSearchFocused && viewModel.searchQuery.isEmpty {
            RecentSearchesView(viewModel: viewModel, navigationPath: $navigationPath)
        } else {
            // Show normal content based on state
            switch viewModel.state {
            case .idle:
                // Load home content if idle
                Color.clear.task {
                    if case .idle = viewModel.state {
                        await viewModel.loadHomeContent()
                    }
                }

            case .homeLoading:
                LoadingView(message: "Loading...")

            case let .home(content):
                HomeContentView(content: content, navigationPath: $navigationPath)

            case .textSearchLoading:
                LoadingView(message: "Searching...")

            case let .textSearchResults(results):
                SearchResultsList(results: results, onResultTap: { media in
                    // Save to recent searches when tapping a search result
                    viewModel.recentSearchRepo.addMediaSearch(
                        mediaId: media.id,
                        mediaType: media.mediaType,
                        title: media.title
                    )
                })

            case .aiIdentifying:
                AIIdentifyingView()

            case let .aiSuggestions(response, candidates):
                AISuggestionsView(
                    response: response,
                    candidates: candidates,
                    isCached: viewModel.isShowingCachedResults,
                    onCandidateTap: { candidate in
                        handleCandidateTap(candidate)
                    },
                    onNewSearch: {
                        viewModel.clearAICache()
                        showAIPicker = true
                    }
                )

            case .empty:
                EmptyStateView(
                    icon: "magnifyingglass.circle",
                    title: "No Results",
                    message: "Try a different search term"
                )

            case let .failed(error):
                ErrorStateView(
                    error: error,
                    onRetry: {
                        Task {
                            await viewModel.performTextSearch()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Candidate Tap Handler

    private func handleCandidateTap(_ candidate: ResolvedCandidate) {
        let action = viewModel.handleCandidateTap(candidate)

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        switch action {
        case let .navigateToDetail(id, type):
            navigationPath.append(MediaSummary(
                id: id,
                mediaType: type,
                title: candidate.original.title,
                releaseDate: candidate.original.year,
                posterPath: candidate.resolvedMedia?.posterPath
            ))

        case let .showPicker(matches):
            ambiguousMatches = matches
            showAmbiguityPicker = true

        case let .fallbackToSearch(title):
            viewModel.searchQuery = title

        case .none:
            break
        }
    }
}

// MARK: - Search Bar

private struct SearchBar: View {
    @Binding var query: String
    var isSearchFocused: FocusState<Bool>.Binding
    let onAITap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .imageScale(.medium)

                TextField("Search movies & TV shows", text: $query)
                    .textFieldStyle(.plain)
                    .focused(isSearchFocused)
                    .submitLabel(.search)

                if !query.isEmpty {
                    Button {
                        query = ""
                        isSearchFocused.wrappedValue = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .imageScale(.medium)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // AI Search Button
            Button(action: onAITap) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "sparkles")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)
                .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
            }
            .accessibilityLabel("AI Search")
        }
        .animation(.spring(response: 0.3), value: query.isEmpty)
    }
}

// MARK: - Home Content View

private struct HomeContentView: View {
    let content: DiscoverViewModel.HomeContent
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Trending Section
                MediaCarouselSection(
                    title: "Trending Now",
                    icon: "flame.fill",
                    media: content.trending,
                    navigationPath: $navigationPath
                )

                // Popular Movies
                MediaCarouselSection(
                    title: "Popular Movies",
                    icon: "film.fill",
                    media: content.popularMovies,
                    navigationPath: $navigationPath
                )

                // Popular TV Shows
                MediaCarouselSection(
                    title: "Popular TV Shows",
                    icon: "tv.fill",
                    media: content.popularTV,
                    navigationPath: $navigationPath
                )
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Media Carousel Section

private struct MediaCarouselSection: View {
    let title: String
    let icon: String
    let media: [MediaSummary]
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Label(title, systemImage: icon)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 20)

            // Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(media.prefix(20)) { item in
                        Button {
                            navigationPath.append(item)
                        } label: {
                            MediaPosterCard(media: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Recent Searches View

private struct RecentSearchesView: View {
    @ObservedObject var viewModel: DiscoverViewModel
    @Binding var navigationPath: NavigationPath

    var body: some View {
        let searches = viewModel.recentSearchRepo.recentSearches

        Group {
            if searches.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No Recent Searches",
                    message: "Your search history will appear here"
                )
            } else {
                List {
                    Section {
                        ForEach(searches) { search in
                            Button {
                                handleRecentSearchTap(search)
                            } label: {
                                RecentSearchRow(search: search)
                            }
                            .listRowBackground(Color(.systemBackground))
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.recentSearchRepo.delete(searches[index])
                            }
                        }
                    } header: {
                        HStack {
                            Text("Recent Searches")
                            Spacer()
                            Button("Clear All") {
                                viewModel.recentSearchRepo.clearAll()
                            }
                            .font(.caption)
                            .textCase(nil)
                            .foregroundStyle(.blue)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func handleRecentSearchTap(_ search: RecentSearch) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        let action = viewModel.handleRecentSearchTap(search)

        switch action {
        case let .navigateToDetail(id, type):
            navigationPath.append(MediaSummary(
                id: id,
                mediaType: type,
                title: search.mediaTitle ?? "",
                releaseDate: nil,
                posterPath: nil
            ))

        case .performTextSearch:
            // Query is already set in viewModel
            break

        case .none:
            break
        }
    }
}

private struct RecentSearchRow: View {
    let search: RecentSearch

    var body: some View {
        HStack(spacing: 12) {
            // Icon based on search type
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)

                Image(systemName: search.isMediaSearch ? "film.fill" : "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .imageScale(.medium)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(search.displayText)
                    .font(.body)
                    .foregroundStyle(.primary)

                if search.isMediaSearch, let mediaType = search.mediaType {
                    MediaTypeBadge(mediaType: MediaType(rawValue: mediaType) ?? .movie)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Search Results List

private struct SearchResultsList: View {
    let results: [MediaSummary]
    let onResultTap: (MediaSummary) -> Void

    var body: some View {
        List(results) { media in
            NavigationLink(value: media) {
                MediaSearchRow(media: media)
            }
            .listRowBackground(Color(.systemBackground))
            .simultaneousGesture(TapGesture().onEnded {
                onResultTap(media)
            })
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

private struct MediaSearchRow: View {
    let media: MediaSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: media.posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(media.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let year = media.year {
                        Text(year)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    MediaTypeBadge(mediaType: media.mediaType)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AI Identifying View

private struct AIIdentifyingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)

                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Identifying with AI")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Analyzing your image...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - AI Suggestions View

private struct AISuggestionsView: View {
    let response: AiIdentifyResponse
    let candidates: [ResolvedCandidate]
    let isCached: Bool
    let onCandidateTap: (ResolvedCandidate) -> Void
    let onNewSearch: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Header with Summary
                AIAnalysisHeader(
                    summary: response.querySummary,
                    candidatesCount: candidates.count,
                    isCached: isCached
                )
                .padding(.horizontal, 20)

                // New Search Button
                Button {
                    onNewSearch()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.white)
                        Text("New AI Search")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 20)

                // Candidates
                LazyVStack(spacing: 16) {
                    ForEach(candidates) { candidate in
                        AICandidateCard(candidate: candidate) {
                            onCandidateTap(candidate)
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Metadata Footer
                if let provider = response.provider, let model = response.model {
                    AIMetadataFooter(
                        provider: provider,
                        model: model,
                        latency: response.latencyMs
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .padding(.top, 20)
        }
    }
}

private struct AIAnalysisHeader: View {
    let summary: String
    let candidatesCount: Int
    let isCached: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("AI Suggestions", systemImage: "sparkles")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                if isCached {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                        Text("Cached")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                }

                Text("\(candidatesCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }
}

private struct AIMetadataFooter: View {
    let provider: String
    let model: String
    let latency: Int?

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                    .font(.caption2)
                Text(provider)
                    .font(.caption2)
            }

            Text("•")
                .font(.caption2)

            Text(model)
                .font(.caption2)

            Spacer()

            if let latency = latency {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(latency)ms")
                        .font(.caption2)
                }
            }
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.blue)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View

private struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .symbolEffect(.bounce, value: true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Error State View

private struct ErrorStateView: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
                .symbolEffect(.bounce, value: true)

            VStack(spacing: 8) {
                Text("Something Went Wrong")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onRetry) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - AI Photo Picker Sheet

private struct AIPhotoPickerSheet: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var textHint: String
    let onSubmit: (Data, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let image = selectedImage {
                        // Preview Mode
                        previewSection(image: image)
                    } else {
                        // Selection Mode
                        selectionSection
                    }
                }
                .padding(.vertical, 24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                await loadPhoto(newItem)
            }
        }
    }

    // MARK: - Selection Section

    @ViewBuilder
    private var selectionSection: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Title & Description
            VStack(spacing: 8) {
                Text("Upload a screenshot from a movie or TV show")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Hint Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional but highly recommended)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)

                TextField("Add a description of the image to improve accuracy...", text: $textHint)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)
            }

            // Action Buttons
            VStack(spacing: 12) {
                // Camera Button
                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .purple.opacity(0.3), radius: 12, y: 6)
                }
                .padding(.horizontal, 20)

                // Photo Library Button
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .foregroundStyle(.purple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private func previewSection(image: UIImage) -> some View {
        VStack(spacing: 24) {
            // Image Preview - Spotify-style cover look
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill() // ✅ Fill the container like Spotify
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
            }
            .frame(height: 400)

            // Hint Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional but highly recommended)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)

                TextField("Add a description of the image to improve accuracy...", text: $textHint)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)
            }

            // Action Buttons
            VStack(spacing: 12) {
                // Submit Button
                Button {
                    submitImage(image)
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Label("Identify with AI", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .purple.opacity(0.3), radius: 12, y: 6)
                .disabled(isSubmitting)
                .padding(.horizontal, 20)

                // Change Photo Button
                Button {
                    selectedImage = nil
                    selectedPhoto = nil
                } label: {
                    Text("Change Photo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else {
            return
        }

        selectedImage = image
    }

    private func submitImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        isSubmitting = true

        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSubmit(data, "image/jpeg")
            // Note: Parent view handles dismissal via state observation
        }
    }
}

// MARK: - Camera Picker

private struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Previews

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecentSearch.self, configurations: config)

    return DiscoverView(modelContext: container.mainContext)
}
