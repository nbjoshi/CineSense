//
//  AmbiguityPickerSheet.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import SwiftUI

struct AmbiguityPickerSheet: View {
    let matches: [TMDBMatch]
    let onSelect: (TMDBMatch) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMatch: TMDBMatch?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                HeaderSection()
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                Divider()

                // Matches List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(matches.prefix(3).enumerated()), id: \.element.id) { index, match in
                            MatchCard(
                                match: match,
                                rank: index + 1,
                                isSelected: selectedMatch?.id == match.id
                            ) {
                                selectedMatch = match
                                // Add haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()

                                // Slight delay for visual feedback
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    onSelect(match)
                                    dismiss()
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.1), value: matches.count)
                        }
                    }
                    .padding(20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onCancel()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Header Section

private struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.2), .orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, value: true)
            }

            // Title
            Text("Multiple Matches Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            // Subtitle
            Text("Choose the correct match below")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Match Card

private struct MatchCard: View {
    let match: TMDBMatch
    let rank: Int
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Rank Badge
                RankBadge(rank: rank)

                // Poster
                PosterImage(url: match.posterURL)

                // Details
                VStack(alignment: .leading, spacing: 8) {
                    Text(match.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        if let year = match.year {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(year)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        }

                        MediaTypeBadge(mediaType: match.mediaType)
                    }

                    // Metadata
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("\(match.voteCount)")
                                .font(.caption)
                        }
                        .foregroundStyle(.yellow)

                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                            Text("\(Int(match.matchScore * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.blue)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .imageScale(.medium)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.06),
                        radius: isPressed ? 8 : 12,
                        y: isPressed ? 2 : 6
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? .blue.opacity(0.5) : .clear,
                        lineWidth: 2
                    )
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank): \(match.title)")
    }
}

// MARK: - Rank Badge

private struct RankBadge: View {
    let rank: Int

    private var color: Color {
        switch rank {
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        default: return .gray
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.gradient)
                .frame(width: 32, height: 32)

            Text("\(rank)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .shadow(color: color.opacity(0.3), radius: 4, y: 2)
    }
}

// MARK: - Poster Image

private struct PosterImage: View {
    let url: URL?

    var body: some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        SkeletonPoster()

                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)

                    case .failure:
                        PlaceholderPoster()

                    @unknown default:
                        PlaceholderPoster()
                    }
                }
            } else {
                PlaceholderPoster()
            }
        }
        .frame(width: 80, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        }
    }
}

private struct SkeletonPoster: View {
    var body: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay {
                ProgressView()
                    .tint(.gray)
            }
    }
}

private struct PlaceholderPoster: View {
    var body: some View {
        Rectangle()
            .fill(Color(.systemGray6))
            .overlay {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Pressable Button Style

private struct PressableButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = newValue
                }
            }
    }
}

// MARK: - Previews

#Preview {
    let matches = [
        TMDBMatch(
            id: 1,
            mediaType: .movie,
            title: "Inception",
            year: "2010",
            posterPath: "/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg",
            voteCount: 35420,
            popularity: 89.5,
            matchScore: 0.95
        ),
        TMDBMatch(
            id: 2,
            mediaType: .movie,
            title: "Inception: The Cobol Job",
            year: "2010",
            posterPath: nil,
            voteCount: 142,
            popularity: 12.3,
            matchScore: 0.72
        ),
        TMDBMatch(
            id: 3,
            mediaType: .tv,
            title: "Inception Stories",
            year: "2011",
            posterPath: nil,
            voteCount: 45,
            popularity: 5.1,
            matchScore: 0.68
        ),
    ]

    return AmbiguityPickerSheet(
        matches: matches,
        onSelect: { _ in },
        onCancel: {}
    )
}
