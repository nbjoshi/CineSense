//
//  SupabaseClientProvider.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Auth
import Foundation
import Supabase

/// Singleton providing a configured Supabase client
final class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    storage: KeychainLocalStorage(),
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
