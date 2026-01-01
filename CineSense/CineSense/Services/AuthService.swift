//
//  AuthService.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation
import Supabase
import System

/// Service handling authentication operations
final class AuthService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    /// Retrieve the current session if available
    func getCurrentSession() async throws -> Session? {
        return try await client.auth.session
    }

    /// Send magic link (OTP) to email with mode-specific options
    func signInWithOTP(email: String, mode: AuthMode) async throws {
        let redirectURL = URL(string: "cinesense://auth-callback")!

        // Control user creation based on mode
        let shouldCreateUser = (mode == .signup)

        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: redirectURL
        )
    }

    /// Sign out the current user
    func signOut() async throws {
        try await client.auth.signOut()
    }
}
