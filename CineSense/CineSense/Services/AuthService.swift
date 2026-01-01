//
//  AuthService.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation
import Supabase

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

    /// Sign out the current user
    func signOut() async throws {
        try await client.auth.signOut()
    }
}
