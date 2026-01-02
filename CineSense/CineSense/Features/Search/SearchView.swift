//
//  SearchView.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import PhotosUI
import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var aiViewModel = AiViewModel()
    @State private var showAiSearch = false
    @State private var isSearchPresented = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.state {
                case .idle:
                    if isSearchFocused && !viewModel.recentSearches.isEmpty {
                        RecentSearchesList(viewModel: viewModel, showAiSearch: $showAiSearch)
                    } else {
                        IdleView(showAiSearch: $showAiSearch)
                    }

                case .loading:
                    ProgressView("Searching...")

                case let .loaded(results):
                    List(results) { media in
                        NavigationLink(value: media) {
                            MediaSearchRow(media: media)
                        }
                    }
                    .listStyle(.plain)

                case .empty:
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass.circle",
                        description: Text("Try a different search term")
                    )

                case let .failed(error):
                    ContentUnavailableView(
                        "Search Failed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.localizedDescription)
                    )
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, isPresented: $isSearchPresented, prompt: "Movies & TV Shows")
            .navigationDestination(for: MediaSummary.self) { media in
                MediaDetailView(mediaId: media.id, mediaType: media.mediaType)
            }
            .onChange(of: isSearchPresented) { _, newValue in
                isSearchFocused = newValue
            }
            .sheet(isPresented: $showAiSearch) {
                AiSearchSheet(viewModel: aiViewModel)
            }
        }
    }
}

// MARK: - Idle View

private struct IdleView: View {
    @Binding var showAiSearch: Bool

    var body: some View {
        VStack(spacing: 24) {
            ContentUnavailableView(
                "Search Movies & TV Shows",
                systemImage: "magnifyingglass",
                description: Text("Enter a title to search")
            )

            Button {
                showAiSearch = true
            } label: {
                Label("AI Search from Screenshot", systemImage: "sparkles.rectangle.stack")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
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

// MARK: - Recent Searches List

private struct RecentSearchesList: View {
    @ObservedObject var viewModel: SearchViewModel
    @Binding var showAiSearch: Bool

    var body: some View {
        List {
            Section {
                Button {
                    showAiSearch = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("AI Search from Screenshot")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                ForEach(viewModel.recentSearches) { search in
                    Button {
                        viewModel.selectRecentSearch(search)
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.secondary)
                            Text(search.displayText)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteRecentSearch(viewModel.recentSearches[index])
                    }
                }
            } header: {
                HStack {
                    Text("Recent Searches")
                    Spacer()
                    if !viewModel.recentSearches.isEmpty {
                        Button("Clear All") {
                            viewModel.clearAllRecentSearches()
                        }
                        .font(.caption)
                        .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - AI Search Sheet

private struct AiSearchSheet: View {
    @ObservedObject var viewModel: AiViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                switch viewModel.state {
                case .idle:
                    AiSearchIdleView(viewModel: viewModel)

                case .uploadingImage:
                    ProgressView("Uploading image...")

                case .identifying:
                    ProgressView("Identifying with AI...")

                case let .loaded(response):
                    AiResultsView(response: response, onClose: { dismiss() })

                case let .failed(error):
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "Identification Failed",
                            systemImage: "exclamationmark.triangle",
                            description: Text(error.localizedDescription)
                        )

                        Button("Try Again") {
                            viewModel.retry()
                        }
                        .buttonStyle(.bordered)
                    }

                case .selectingImage:
                    EmptyView()
                }
            }
            .navigationTitle("AI Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onDisappear {
                viewModel.reset()
            }
        }
    }
}

// MARK: - AI Search Idle View

private struct AiSearchIdleView: View {
    @ObservedObject var viewModel: AiViewModel
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("Select a Screenshot")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Choose an image from a movie or TV show to identify it using AI")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                TextField("Optional: Add a hint", text: $viewModel.textHint)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Choose Image", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .onChange(of: photoItem) { _, newItem in
                    Task {
                        await viewModel.selectPhoto(newItem)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - AI Results View

private struct AiResultsView: View {
    let response: AiIdentifyResponse
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analysis")
                        .font(.headline)
                    Text(response.querySummary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Candidates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Matches")
                        .font(.headline)

                    ForEach(response.candidates) { candidate in
                        NavigationLink(value: MediaSummary(
                            id: 0,
                            mediaType: candidate.type,
                            title: candidate.title,
                            releaseDate: candidate.year,
                            posterPath: nil
                        )) {
                            AiCandidateRow(candidate: candidate)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            onClose()
                        })
                    }
                }

                // Metadata
                if let provider = response.provider, let model = response.model {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Powered by \(provider) (\(model))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let latency = response.latencyMs {
                            Text("Processed in \(latency)ms")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
    }
}

// MARK: - AI Candidate Row

private struct AiCandidateRow: View {
    let candidate: Candidate

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Poster placeholder (candidates from AI don't have poster paths yet)
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.title3)

                            Text("\(Int(candidate.confidence * 100))%")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(candidate.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(candidate.year)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    MediaTypeBadge(mediaType: candidate.type)
                }

                Text(candidate.rationale)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SearchView()
}
