//
//  RailSkeletonView.swift
//  CineSense
//
//  Created by Claude Code on 1/2/26.
//

import SwiftUI

/// Skeleton loader for horizontal rail while content is loading
struct RailSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.sm) {
                ForEach(0..<5, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: DS.xs) {
                        // Poster skeleton
                        RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous)
                            .fill(DS.Colors.surface)
                            .frame(width: 120, height: 180)
                            .overlay {
                                RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DS.Colors.surface,
                                                DS.Colors.elevated.opacity(0.8),
                                                DS.Colors.surface
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .opacity(isAnimating ? 1 : 0.3)
                            }

                        // Title skeleton
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(DS.Colors.surface)
                            .frame(width: 100, height: 12)

                        // Year skeleton
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(DS.Colors.surface)
                            .frame(width: 40, height: 10)
                    }
                }
            }
            .padding(.horizontal, DS.md)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
