//
//  Designs.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation
import SwiftUI

// MARK: - Design System (CineSense)

enum DS {
    // Spacing
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32

    // Corners
    static let radiusSm: CGFloat = 12
    static let radiusMd: CGFloat = 16
    static let radiusLg: CGFloat = 22

    // Layout
    static let maxContentWidth: CGFloat = 520
}

// MARK: - Typography

extension Font {
    static let csHeroTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let csTitle = Font.system(.title2, design: .rounded).weight(.bold)
    static let csHeadline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let csBody = Font.system(.body, design: .default)
    static let csSubhead = Font.system(.subheadline, design: .default)
    static let csCaption = Font.system(.caption, design: .default)
}

// MARK: - Surfaces

extension View {
    /// A consistent card surface that looks great in dark mode.
    func csCard() -> some View {
        padding(DS.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            )
    }

    /// Standard horizontal page padding.
    func csPagePadding() -> some View {
        padding(.horizontal, DS.md)
    }

    /// Limit line length for readable layouts.
    func csContentWidth() -> some View {
        frame(maxWidth: DS.maxContentWidth)
    }
}

// MARK: - Buttons

struct CSPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.csHeadline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, DS.md)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .fill(Color.accentColor)
                    .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .foregroundStyle(.white)
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            )
    }
}

struct CSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.csHeadline)
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, DS.md)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .opacity(configuration.isPressed ? 0.70 : 1.0)
            )
            .foregroundStyle(.primary)
    }
}

// MARK: - Inputs

struct CSEmailFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func csEmailField() -> some View {
        modifier(CSEmailFieldStyle())
    }
}

// MARK: - Empty / Error / Success

struct CSInlineMessage: View {
    enum Kind { case success, error, info }
    let kind: Kind
    let title: String
    let message: String?

    private var icon: String {
        switch kind {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var tint: Color {
        switch kind {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: DS.sm) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.csSubhead).fontWeight(.semibold)
                if let message, !message.isEmpty {
                    Text(message).font(.csCaption).foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(DS.md)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
    }
}
