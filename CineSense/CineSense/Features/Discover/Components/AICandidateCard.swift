//
//  AICandidateCard.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import SwiftUI

struct AICandidateCard: View {
    let candidate: ResolvedCandidate
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onTap()
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Poster (show actual image when available, otherwise skeleton)
                Group {
                    if let posterURL = candidate.posterURL {
                        AsyncPosterImage(url: posterURL)
                    } else {
                        StaticSkeletonPoster()
                    }
                }
                .frame(width: 80, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Title with year
                    HStack(spacing: 6) {
                        Text(candidate.original.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text("(\(candidate.original.year))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Media type badge
                    MediaTypeBadge(mediaType: candidate.original.type)

                    // Confidence
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                        Text("Confidence: \(Int(candidate.original.confidence * 100))%")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }

                    // Rationale
                    Text(candidate.original.rationale)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    // Status indicator at bottom
                    HStack {
                        StatusIndicator(candidate: candidate)
                        Spacer()
                    }
                }

                Spacer()

                // Chevron for interactable items
                if candidate.isInteractable {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .imageScale(.small)
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: .black.opacity(isPressed ? 0.1 : 0.06),
                        radius: isPressed ? 8 : 12,
                        y: isPressed ? 2 : 6
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(CardButtonStyle(isPressed: $isPressed))
        .disabled(!candidate.isInteractable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(candidate.original.title), \(candidate.original.year)")
    }
}

// MARK: - Poster View

private struct PosterView: View {
    let candidate: ResolvedCandidate

    var body: some View {
        // Always show skeleton for AI candidates (no image loading)
        SkeletonPoster()
            .frame(width: 90, height: 135)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            }
    }
}

// MARK: - Async Poster Image

private struct AsyncPosterImage: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                SkeletonPoster()

            case let .success(image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .failure:
                PlaceholderPoster(failed: true)

            @unknown default:
                PlaceholderPoster()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: url)
    }
}

// MARK: - Static Skeleton Poster

private struct StaticSkeletonPoster: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray5),
                        Color(.systemGray4),
                        Color(.systemGray5),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
    }
}

// MARK: - Skeleton Poster

private struct SkeletonPoster: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray5),
                        Color(.systemGray4),
                        Color(.systemGray5),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.3),
                                    .clear,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
                .clipped()
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

// MARK: - Placeholder Poster

private struct PlaceholderPoster: View {
    var failed: Bool = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemGray6))

            VStack(spacing: 8) {
                Image(systemName: failed ? "exclamationmark.triangle.fill" : "photo")
                    .font(.title2)
                    .foregroundStyle(failed ? .orange : .secondary)
                    .symbolEffect(.bounce, value: failed)

                if failed {
                    Text("Failed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Status Indicator

private struct StatusIndicator: View {
    let candidate: ResolvedCandidate

    var body: some View {
        Group {
            switch candidate.state {
            case let .resolved(media):
                ConfidenceChip(level: media.confidenceLevel)

            case .ambiguous:
                AmbiguousBadge()

            case .failed:
                FailedBadge()

            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Confidence Chip

struct ConfidenceChip: View {
    let level: ResolvedMedia.ConfidenceLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.caption2)
                .imageScale(.small)

            Text(level.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(level.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(level.color.opacity(0.15))
        }
        .overlay {
            Capsule()
                .strokeBorder(level.color.opacity(0.3), lineWidth: 0.5)
        }
        .accessibilityLabel("Match confidence: \(level.rawValue)")
    }
}

// MARK: - Ambiguous Badge

private struct AmbiguousBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "questionmark.circle.fill")
                .font(.caption2)
                .imageScale(.small)

            Text("Multiple")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(.orange.opacity(0.15))
        }
        .overlay {
            Capsule()
                .strokeBorder(.orange.opacity(0.3), lineWidth: 0.5)
        }
        .accessibilityLabel("Multiple matches found")
    }
}

// MARK: - Failed Badge

private struct FailedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
                .imageScale(.small)

            Text("Search")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.red)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(.red.opacity(0.15))
        }
        .overlay {
            Capsule()
                .strokeBorder(.red.opacity(0.3), lineWidth: 0.5)
        }
        .accessibilityLabel("Match failed, tap to search")
    }
}

// MARK: - Rationale View

private struct RationaleView: View {
    let text: String
    @State private var isExpanded = false

    private var shouldShowExpansion: Bool {
        text.count > 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)

            if shouldShowExpansion {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show less" : "Why?")
                            .font(.caption2)
                            .fontWeight(.medium)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .imageScale(.small)
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Card Button Style

private struct CardButtonStyle: ButtonStyle {
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

#Preview("Resolved - High Confidence") {
    let candidate = ResolvedCandidate(from: Candidate(
        title: "Inception",
        type: .movie,
        year: "2010",
        confidence: 0.95,
        rationale: "Christopher Nolan's mind-bending thriller about dream manipulation and corporate espionage."
    ))

    var resolved = candidate
    resolved.state = .resolved(ResolvedMedia(
        tmdbId: 27205,
        mediaType: .movie,
        matchedTitle: "Inception",
        matchedYear: "2010",
        posterPath: "/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg",
        matchConfidence: 0.95
    ))

    return AICandidateCard(candidate: resolved) {}
        .padding()
}

#Preview("Resolving") {
    var candidate = ResolvedCandidate(from: Candidate(
        title: "The Matrix",
        type: .movie,
        year: "1999",
        confidence: 0.88,
        rationale: "A hacker discovers reality is a simulation."
    ))
    candidate.state = .resolving

    return AICandidateCard(candidate: candidate) {}
        .padding()
}

#Preview("Ambiguous") {
    var candidate = ResolvedCandidate(from: Candidate(
        title: "The Office",
        type: .tv,
        year: "2005",
        confidence: 0.75,
        rationale: "Mockumentary sitcom about office workers."
    ))
    candidate.state = .ambiguous([])

    return AICandidateCard(candidate: candidate) {}
        .padding()
}
