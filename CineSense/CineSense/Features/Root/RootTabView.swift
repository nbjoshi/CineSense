//
//  RootTabView.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import SwiftUI
import Auth

/// Root tab view with 5 tabs: Home, Search, Discover, Lists, Account
struct RootTabView: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        TabView {
            HomeTab()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            DiscoverTab()
                .tabItem {
                    Label("Discover", systemImage: "sparkles")
                }

            ListsTab()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }

            AccountTab()
                .tabItem {
                    Label("Account", systemImage: "person.fill")
                }
        }
    }
}

// MARK: - Tab Placeholders

private struct HomeTab: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Home")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Home")
        }
    }
}

private struct DiscoverTab: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Discover")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Discover")
        }
    }
}

private struct ListsTab: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "list.bullet")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Lists")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Lists")
        }
    }
}

private struct AccountTab: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        NavigationStack {
            List {
                Section("Debug Panel") {
                    LabeledContent("Status") {
                        Text(sessionStore.session != nil ? "Logged In" : "Not Logged In")
                            .foregroundColor(sessionStore.session != nil ? .green : .red)
                    }

                    if let session = sessionStore.session {
                        LabeledContent("User ID") {
                            Text(session.user.id.uuidString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

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
            .navigationTitle("Account")
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(SessionStore())
}
