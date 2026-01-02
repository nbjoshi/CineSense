//
//  HapticManager.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import SwiftUI
import UIKit

/// Centralized haptic feedback manager for consistent UX
enum HapticManager {
    // MARK: - Impact Feedback

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func lightImpact() {
        impact(.light)
    }

    static func mediumImpact() {
        impact(.medium)
    }

    static func heavyImpact() {
        impact(.heavy)
    }

    static func softImpact() {
        impact(.soft)
    }

    static func rigidImpact() {
        impact(.rigid)
    }

    // MARK: - Notification Feedback

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func success() {
        notification(.success)
    }

    static func warning() {
        notification(.warning)
    }

    static func error() {
        notification(.error)
    }

    // MARK: - Selection Feedback

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - View Extension for Haptics

extension View {
    /// Adds haptic feedback on tap
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.impact(style)
                }
        )
    }

    /// Adds success haptic feedback
    func successHaptic() -> some View {
        simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.success()
                }
        )
    }
}
