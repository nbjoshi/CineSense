//
//  CineSenseApp.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import SwiftData
import SwiftUI

@main
struct CineSenseApp: App {
    @StateObject private var sessionStore = SessionStore()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RecentSearch.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if sessionStore.isBootstrapping {
                    ProgressView("Loading...")
                } else if sessionStore.session != nil {
                    RootTabView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(sessionStore)
            .onOpenURL { url in
                print("🔗 Deep link received: \(url)")
                sessionStore.handleOpenURL(url)
            }
            .task {
                await sessionStore.bootstrap()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
