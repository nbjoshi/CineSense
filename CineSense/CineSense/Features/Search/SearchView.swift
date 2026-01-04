//
//  SearchView.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import AVFoundation

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            SearchViewContent(modelContext: modelContext)
        }
    }
}

private struct SearchViewContent: View {
    let modelContext: ModelContext

    @StateObject private var aiViewModel = AiViewModel()
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var recentSearchRepo: RecentSearchRepository

    @State private var showAiSearch = false
    @State private var isSearchPresented = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _recentSearchRepo = StateObject(wrappedValue: RecentSearchRepository(modelContext: modelContext))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                if isSearchPresented || !viewModel.query.isEmpty {
                    RecentSearchesList(viewModel: viewModel, repository: recentSearchRepo)
                } else {
                    IdlePlaceholder()
                }

            case .loading:
                ProgressView("Searching...")
                    .padding(.top, 16)

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
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 8)
        }
        .toolbar {
            // LEFT: "Search" label (inline with right button)
            ToolbarItem(placement: .topBarLeading) {
                Text("Search")
                    .font(.title3.bold()) // adjust to taste
            }

            // RIGHT: AI button
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAiSearch = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)

                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom)
        .searchable(
            text: $viewModel.query,
            isPresented: $isSearchPresented,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "What do you want to watch?"
        )
        .navigationDestination(for: MediaSummary.self) { media in
            MediaDetailView(mediaId: media.id, mediaType: media.mediaType)
        }
        .sheet(isPresented: $showAiSearch) {
            AiSearchSheet(viewModel: aiViewModel, onCandidateSelected: { candidate in
                viewModel.searchNow(candidate.title)
            })
        }
        .onAppear {
            viewModel.recentSearchRepository = recentSearchRepo
        }
    }
}

// MARK: - Idle Placeholder

private struct IdlePlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "Search Movies & TV Shows",
            systemImage: "magnifyingglass",
            description: Text("Enter a title to search or use AI search")
        )
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
    @ObservedObject var repository: RecentSearchRepository

    var body: some View {
        List {
            Section {
                ForEach(repository.recentSearches) { search in
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
                        repository.delete(repository.recentSearches[index])
                    }
                }
            } header: {
                HStack {
                    Text("Recent Searches")
                    Spacer()
                    if !repository.recentSearches.isEmpty {
                        Button("Clear All") {
                            repository.clearAll()
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
    let onCandidateSelected: (Candidate) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Content
            VStack(spacing: 20) {
                switch viewModel.state {
                case .idle:
                    AiSearchIdleView(viewModel: viewModel)

                case let .imageSelected(image):
                    AiImagePreviewView(image: image, viewModel: viewModel)

                case .uploadingImage:
                    ProgressView("Uploading image...")

                case .identifying:
                    ProgressView("Identifying with AI...")

                case let .loaded(response):
                    NavigationStack {
                        AiResultsView(
                            response: response,
                            onClose: { dismiss() },
                            onCandidateSelected: onCandidateSelected
                        )
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    viewModel.beginNewAttemptKeepingCache()
                                } label: {
                                    Label("New Attempt", systemImage: "arrow.counterclockwise")
                                }
                            }
                        }
                    }

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
            .padding(.top)
        }
        .presentationDetents([.fraction(0.92)])
        .presentationDragIndicator(.visible)
        .onAppear {
            viewModel.restoreCachedResultsIfAvailable()
        }
        .onDisappear {
            viewModel.resetTransientUI()
        }
    }
}

// MARK: - AI Search Idle View

private struct AiSearchIdleView: View {
    @ObservedObject var viewModel: AiViewModel
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Identify with AI")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Identify movies or TV shows from a screenshot")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                // Camera Roll option
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                        Text("Select from Camera Roll")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .onChange(of: photoItem) { _, newItem in
                    Task {
                        await viewModel.selectPhoto(newItem)
                    }
                }

                Button {
                    showCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera")
                            .font(.title3)
                        Text("Take a Screenshot")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureSheet(isPresented: $showCamera) { image in
                viewModel.selectCameraImage(image)
            }
        }
    }
}


// MARK: - Camera Capture View

/// UIKit wrapper for the system camera.
private struct CameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
    }
}


// MARK: - AI Image Preview View

private struct AiImagePreviewView: View {
    let image: UIImage
    @ObservedObject var viewModel: AiViewModel
    @FocusState private var hintFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image preview card at top
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
                    
                    // Change button overlay
                    Button {
                        viewModel.clearImage()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption.weight(.semibold))
                            Text("Change")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                }
                
                // Text hint card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Add a Hint")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.primary)
                    
                    Text("Optional but highly recommended for better accuracy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., \"sci-fi series with robots\"", text: $viewModel.textHint, axis: .vertical)
                        .font(.body)
                        .lineLimit(2...4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                        .focused($hintFocused)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.secondary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                )
                
                Spacer()
                
                Button {
                    hintFocused = false
                    Task { await viewModel.identifySelectedImage() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.headline)
                        Text("Identify with AI")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .purple.opacity(0.3), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .padding(20)
        }
    }
}

// MARK: - AI Results View

private struct AiResultsView: View {
    let response: AiIdentifyResponse
    let onClose: () -> Void
    let onCandidateSelected: (Candidate) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Summary card with gradient accent
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("AI Analysis")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    Text(response.querySummary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )

                // Candidates section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Top Matches")
                        .font(.title3)
                        .fontWeight(.bold)

                    ForEach(response.candidates) { candidate in
                        Button {
                            onCandidateSelected(candidate)
                            onClose()
                        } label: {
                            AiCandidateRow(candidate: candidate)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Metadata footer
                if let provider = response.provider, let model = response.model {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("Powered by \(provider)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)

                        if let latency = response.latencyMs {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text("Processed in \(latency)ms")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - AI Candidate Row

private struct AiCandidateRow: View {
    let candidate: Candidate

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Poster placeholder with confidence badge
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.secondary.opacity(0.15),
                                Color.secondary.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.secondary.opacity(0.5))
                            .font(.title2)
                    }

                // Confidence badge
                Text("\(Int(candidate.confidence * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        confidenceColor(for: candidate.confidence)
                            .opacity(0.9)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(4)
            }
            .frame(width: 70, height: 105)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(candidate.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                // Year and type
                HStack(spacing: 8) {
                    Text(candidate.year)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    MediaTypeBadge(mediaType: candidate.type)
                }

                // Rationale
                Text(candidate.rationale)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    private func confidenceColor(for confidence: Double) -> Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    SearchView()
}
