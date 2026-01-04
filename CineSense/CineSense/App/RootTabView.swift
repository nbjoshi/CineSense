//
//  RootTabView.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Auth
import SwiftData
import SwiftUI

/// Root tab view with exactly 4 tabs: Home, Search, Lists, Profile
/// Per docs/architecture/decisions.md and docs/architecture/navigation-and-ui.md
struct RootTabView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            // Home tab - Spotify-style rails
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Search tab - includes text search + AI search
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            // Lists tab
            ListsTab()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }

            // Profile tab (renamed from Account)
            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

// MARK: - Tab Placeholders

private struct ListsTab: View {
    var body: some View {
        // Per docs: no default navigation titles
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Lists")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }
}

private struct ProfileTab: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        // Per docs: no default navigation titles
        NavigationStack {
            VStack (alignment: .leading) {
                HStack (alignment: .center, spacing: 16){
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                    
                    Text("User Profile")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.vertical)
            
            List {
                Section("Profile") {
                    LabeledContent("Status") {
                        Text(sessionStore.session != nil ? "Logged In" : "Not Logged In")
                            .foregroundColor(sessionStore.session != nil ? .green : .red)
                    }

                    if let session = sessionStore.session {
                        if let email = session.user.email {
                            LabeledContent("Email") {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Button(role: .destructive) {
                        Task {
                            await sessionStore.signOut()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "arrow.backward.circle.fill")
                    }
                }
            }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(SessionStore())
}
