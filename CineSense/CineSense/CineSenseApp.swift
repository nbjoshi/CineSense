//
//  CineSenseApp.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import SwiftUI

@main
struct CineSenseApp: App {
    @StateObject private var sessionStore = SessionStore()

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
    }
}
