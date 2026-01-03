//
//  SectionHeaderView.swift
//  CineSense
//
//  Created by Claude Code on 1/2/26.
//

import SwiftUI

/// Spotify-style section header with bold title
struct SectionHeaderView: View {
    let title: String
    let showSeeAll: Bool
    let onSeeAll: (() -> Void)?

    init(title: String, showSeeAll: Bool = false, onSeeAll: (() -> Void)? = nil) {
        self.title = title
        self.showSeeAll = showSeeAll
        self.onSeeAll = onSeeAll
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.spTitle)
                .foregroundStyle(DS.Colors.textPrimary)

            Spacer()

            if showSeeAll {
                Button {
                    onSeeAll?()
                } label: {
                    Text("See all")
                        .font(.spSubhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, DS.md)
    }
}
