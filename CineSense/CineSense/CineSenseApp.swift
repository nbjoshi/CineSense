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
            .task {
                await sessionStore.bootstrap()
            }
        }
    }
}
