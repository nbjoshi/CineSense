//
//  MediaDetailView.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import SwiftUI
import UIKit

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
    @Environment(\.dismiss) private var dismiss
    private let headerHeight: CGFloat = 320

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { geo in
                                        let minY = geo.frame(in: .named("scroll")).minY
                                        let y = min(0, minY)              // ✅ only negative values
                                        // no stretching:
                                        header
                                            .frame(height: headerHeight)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                            .offset(y: y)                 // ✅ moves up with scroll
                                    }
                                    .frame(height: headerHeight)
                                    .ignoresSafeArea(edges: .top)
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and Year
                        VStack(alignment: .leading, spacing: 16) {
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
                    .padding(.top, 20)
                }
            }
            .coordinateSpace(name: "scroll")
            .overlay(alignment: .topLeading) {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 36, height: 36)

                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.top, 8)
                .padding(.leading, 16)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .background(NavigationControllerConfigurator())
        }
    }

    @ViewBuilder
    private var header: some View {
        if let backdropURL = detail.backdropURL {
            AsyncImage(url: backdropURL) { image in
                image
                    .resizable()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay { ProgressView() }
            }
        }
    }
}

// MARK: - Navigation Controller Configurator

private struct NavigationControllerConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NavigationControllerConfiguratorViewController {
        NavigationControllerConfiguratorViewController()
    }

    func updateUIViewController(_ uiViewController: NavigationControllerConfiguratorViewController, context: Context) {
        uiViewController.configure()
    }
}

private class NavigationControllerConfiguratorViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configure()
    }

    func configure() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
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
