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
    // Session state
    @Published var session: Session?
    @Published var isBootstrapping = true

    // Auth form state
    @Published var email = ""
    @Published var isSubmitting = false
    @Published var didSubmit = false
    @Published var errorMessage: String?

    private let authService: AuthService
    private var authStateTask: Task<Void, Never>?

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

        // Listen for auth state changes
        startAuthStateListener()
    }

    /// Send magic link to email
    func sendMagicLink() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter an email address"
            return
        }

        isSubmitting = true
        didSubmit = false
        errorMessage = nil

        do {
            print("Sending magic link to: \(email)")
            try await authService.signInWithOTP(email: email)
            didSubmit = true
            print("Magic link sent successfully!")
        } catch {
            errorMessage = error.localizedDescription
            print("Sign in error: \(error)")
        }

        isSubmitting = false
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

    /// Listen for auth state changes (e.g., when user clicks magic link)
    private func startAuthStateListener() {
        authStateTask?.cancel()
        authStateTask = Task { @MainActor in
            for await state in await SupabaseClientProvider.shared.client.auth.authStateChanges {
                print("Auth state changed: \(state.event)")
                session = state.session
            }
        }
    }
    
    func handleOpenURL(_ url: URL) {
        SupabaseClientProvider.shared.client.auth.handle(url)
    }

    deinit {
        authStateTask?.cancel()
    }
}
