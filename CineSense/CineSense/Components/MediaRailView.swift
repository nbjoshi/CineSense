//
//  MediaRailView.swift
//  CineSense
//
//  Created by Claude Code on 1/2/26.
//

import SwiftUI

/// Horizontal scrollable rail of media posters
struct MediaRailView: View {
    let media: [MediaSummary]
    let onTap: (MediaSummary) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.sm) {
                ForEach(media.prefix(20)) { item in
                    Button {
                        onTap(item)
                    } label: {
                        MediaPosterCard(media: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.md)
        }
    }
}
