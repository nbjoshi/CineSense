//
//  MediaPosterCard.swift
//  CineSense
//
//  Created by Claude Code on 1/2/26.
//

import SwiftUI

/// Spotify-style poster card for media items
/// Lightweight card with rounded corners, no heavy decorations
struct MediaPosterCard: View {
    let media: MediaSummary

    var body: some View {
        VStack(alignment: .leading, spacing: DS.xs) {
            // Poster Image
            AsyncImage(url: media.posterURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(DS.Colors.surface)
                        .overlay {
                            ProgressView()
                                .tint(DS.Colors.textSecondary)
                        }
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(DS.Colors.surface)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(DS.Colors.textSecondary)
                                .font(.title3)
                        }
                @unknown default:
                    Rectangle()
                        .fill(DS.Colors.surface)
                }
            }
            .frame(width: 120, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

            // Title
            Text(media.title)
                .font(.spCaption)
                .fontWeight(.medium)
                .foregroundStyle(DS.Colors.textPrimary)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            // Year
            if let year = media.year {
                Text(year)
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
    }
}
