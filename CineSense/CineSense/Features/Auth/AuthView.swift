//
//  AuthView.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import SwiftUI

/// Placeholder authentication view
struct AuthView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "film.stack")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            Text("CineSense")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sign in (TODO)")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)

            Text("Authentication with Sign in with Apple will be implemented in Milestone 1.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    AuthView()
}
