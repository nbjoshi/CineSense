//
//  SessionStore.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation
import Combine
import Supabase

/// ObservableObject managing session state and app bootstrapping
@MainActor
final class SessionStore: ObservableObject {
    @Published var session: Session?
    @Published var isBootstrapping = true

    private let authService: AuthService

    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    /// Bootstrap the app by checking for an existing session
    func bootstrap() async {
        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            session = try await authService.getCurrentSession()
        } catch {
            // sessionMissing is expected when there's no stored session (e.g., first launch)
            // Only log other errors
            if !(error is AuthError && "\(error)".contains("sessionMissing")) {
                print("Bootstrap error: \(error)")
            }
            session = nil
        }
    }

    /// Sign out the current user
    func signOut() async {
        do {
            try await authService.signOut()
            session = nil
        } catch {
            print("Sign out error: \(error)")
        }
    }
}
