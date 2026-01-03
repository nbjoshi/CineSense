//
//  Designs.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation
import SwiftUI

// MARK: - Spotify-ish Design System (CineSense)

enum DS {
    // Spacing (Spotify tends to be a bit tighter with strong rhythm)
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32

    // Corners (Spotify cards are usually subtle-rounded, not super pill-y)
    static let radiusSm: CGFloat = 10
    static let radiusMd: CGFloat = 14
    static let radiusLg: CGFloat = 18

    // Layout
    static let maxContentWidth: CGFloat = 560

    enum Colors {
        // Spotify-like dark theme tokens
        static let background = Color(hex: 0x121212)   // main app background
        static let surface    = Color(hex: 0x181818)   // cards, list rows
        static let elevated   = Color(hex: 0x242424)   // pressed/hover/elevated surfaces
        static let divider    = Color.white.opacity(0.08)

        static let textPrimary   = Color.white
        static let textSecondary = Color(hex: 0xB3B3B3)

        // Spotify green (use your accent asset if you have one; this is safe fallback)
        static let accent = Color(hex: 0x1DB954)
        static let accentAlt = Color(hex: 0x1ED760)
        static let danger = Color.red
        static let info = Color.blue
        static let success = Color.green
    }
}

// MARK: - Typography (Spotify-like hierarchy: bold headers + readable body)

extension Font {
    static let spLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let spTitle = Font.system(size: 22, weight: .bold, design: .default)
    static let spHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    static let spBody = Font.system(size: 16, weight: .regular, design: .default)
    static let spSubhead = Font.system(size: 14, weight: .regular, design: .default)
    static let spCaption = Font.system(size: 12, weight: .regular, design: .default)
}

// MARK: - Base Surfaces / Layout Helpers

extension View {
    /// App default background (Spotify-like)
    func csAppBackground() -> some View {
        background(DS.Colors.background)
            .foregroundStyle(DS.Colors.textPrimary)
    }

    /// Standard horizontal page padding.
    func csPagePadding() -> some View {
        padding(.horizontal, DS.md)
    }

    /// Limit line length for readable layouts.
    func csContentWidth() -> some View {
        frame(maxWidth: DS.maxContentWidth)
    }

    /// Spotify-ish card surface (solid dark, subtle border).
    func csCard() -> some View {
        padding(DS.md)
            .background(DS.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .strokeBorder(DS.Colors.divider, lineWidth: 1)
            )
    }

    /// A slightly elevated surface (good for pressed state or modals).
    func csElevatedCard() -> some View {
        padding(DS.md)
            .background(DS.Colors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .strokeBorder(DS.Colors.divider, lineWidth: 1)
            )
    }
}

// MARK: - Buttons

struct CSPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.spHeadline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, DS.md)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .fill(DS.Colors.accent)
                    .opacity(configuration.isPressed ? 0.88 : 1.0)
            )
            // Spotify buttons often use dark text on green
            .foregroundStyle(Color.black.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

struct CSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.spHeadline)
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, DS.md)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .fill(configuration.isPressed ? DS.Colors.elevated : DS.Colors.surface)
            )
            .foregroundStyle(DS.Colors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .strokeBorder(DS.Colors.divider, lineWidth: 1)
            )
    }
}

/// Small icon button (useful for Spotify-style headers)
struct CSIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(configuration.isPressed ? DS.Colors.elevated : DS.Colors.surface)
            )
            .overlay(
                Circle()
                    .strokeBorder(DS.Colors.divider, lineWidth: 1)
            )
            .foregroundStyle(DS.Colors.textPrimary)
    }
}

// MARK: - Inputs

struct CSTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.vertical, 12)
            .padding(.horizontal, DS.md)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous)
                    .fill(DS.Colors.elevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous)
                    .strokeBorder(DS.Colors.divider, lineWidth: 1)
            )
            .foregroundStyle(DS.Colors.textPrimary)
    }
}

extension View {
    func csTextField() -> some View { modifier(CSTextFieldStyle()) }
}

// MARK: - Empty / Error / Info

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
        case .success: return DS.Colors.success
        case .error: return DS.Colors.danger
        case .info: return DS.Colors.info
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: DS.sm) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.spSubhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Colors.textPrimary)

                if let message, !message.isEmpty {
                    Text(message)
                        .font(.spCaption)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(DS.md)
        .background(DS.Colors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Utilities

extension Color {
    /// Hex color convenience (e.g., 0x121212)
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
