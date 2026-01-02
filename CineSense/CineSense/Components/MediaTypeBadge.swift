//
//  MediaTypeBadge.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import SwiftUI

struct MediaTypeBadge: View {
    let mediaType: MediaType

    private var config: (color: Color, label: String) {
        switch mediaType {
        case .movie:
            return (.blue, "Movie")
        case .tv:
            return (.purple, "TV")
        }
    }

    var body: some View {
        Text(config.label)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(config.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(config.color.opacity(0.15))
            }
            .overlay {
                Capsule()
                    .strokeBorder(config.color.opacity(0.3), lineWidth: 0.5)
            }
    }
}
