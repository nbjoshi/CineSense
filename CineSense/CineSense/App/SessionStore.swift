//
//  SessionStore.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Combine
import Foundation
import Supabase

/// ObservableObject managing session state and app bootstrapping
@MainActor
final class SessionStore: ObservableObject {
    // Session state
    @Published var session: Session?
    @Published var isBootstrapping = true

    // Auth form state
    @Published var email = ""
    @Published var authMode: AuthMode = .login {
        didSet {
            // Reset messages when mode changes
            resetMessages()
        }
    }

    @Published var isSubmitting = false
    @Published var didSubmit = false
    @Published var errorMessage: String?

    private let authService: AuthService
    private var authStateTask: Task<Void, Never>?

    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    /// Reset UI messages
    func resetMessages() {
        didSubmit = false
        errorMessage = nil
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
            print("Sending magic link to: \(email) (mode: \(authMode.rawValue))")
            try await authService.signInWithOTP(email: email, mode: authMode)
            didSubmit = true
            print("Magic link sent successfully!")
        } catch {
            errorMessage = mapErrorToFriendlyMessage(error)
            print("Sign in error: \(error)")
        }

        isSubmitting = false
    }

    /// Map Supabase errors to user-friendly, mode-specific messages
    private func mapErrorToFriendlyMessage(_ error: Error) -> String {
        let errorString = "\(error)"

        // Login mode: user not found
        if authMode == .login && errorString.contains("User not found") {
            return "No account found. Switch to Sign up."
        }

        // Signup mode: user already exists
        if authMode == .signup && (errorString.contains("already registered") || errorString.contains("already exists")) {
            return "Account already exists. Switch to Log in."
        }

        // Invalid email format
        if errorString.contains("email") && errorString.contains("invalid") {
            return "Please enter a valid email address."
        }

        // Rate limiting
        if errorString.contains("rate limit") || errorString.contains("too many") {
            return "Too many requests. Please try again in a few minutes."
        }

        // Default fallback
        return error.localizedDescription
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
