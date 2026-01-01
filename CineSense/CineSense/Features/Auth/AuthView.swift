//
//  AuthView.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import SwiftUI

/// Authentication view with magic link sign-in
struct AuthView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon
            Image(systemName: "film.stack")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            Text("CineSense")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            // Email Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                TextField("your@email.com", text: $sessionStore.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .focused($isEmailFocused)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .disabled(sessionStore.isSubmitting)
            }
            .padding(.horizontal)

            // Sign In Button
            Button {
                isEmailFocused = false
                Task {
                    await sessionStore.sendMagicLink()
                }
            } label: {
                if sessionStore.isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Send Magic Link")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isButtonDisabled ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(isButtonDisabled)

            // Success Message
            if sessionStore.didSubmit {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Magic link sent! Check your email.")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }

            // Error Message
            if let errorMessage = sessionStore.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }

            // Info Text
            Text("We'll send you a sign-in link. Click it to access your account.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
            Spacer()
        }
        .padding()
    }

    private var isButtonDisabled: Bool {
        sessionStore.email.isEmpty || sessionStore.isSubmitting
    }
}

#Preview {
    AuthView()
        .environmentObject(SessionStore())
}
