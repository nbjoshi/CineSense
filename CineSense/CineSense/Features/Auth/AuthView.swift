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
        ScrollView {
            VStack(spacing: DS.xl) {
                // Hero Section
                VStack(spacing: DS.md) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 72))
                        .foregroundStyle(.tint)
                        .padding(.top, DS.xl)

                    Text("CineSense")
                        .font(.spLargeTitle)

                    Text(sessionStore.authMode.subtitle)
                        .font(.spSubhead)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, DS.lg)

                // Form Card
                VStack(spacing: DS.lg) {
                    // Mode Picker
                    Picker("Mode", selection: $sessionStore.authMode) {
                        ForEach(AuthMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Email Field
                    VStack(alignment: .leading, spacing: DS.sm) {
                        Text("Email")
                            .font(.spSubhead)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextField("your@email.com", text: $sessionStore.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .focused($isEmailFocused)
                            .disabled(sessionStore.isSubmitting || sessionStore.didSubmit)
                            .csTextField()
                    }

                    // Primary Action Button
                    if !sessionStore.didSubmit {
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
                                Text(sessionStore.authMode.buttonLabel)
                            }
                        }
                        .buttonStyle(CSPrimaryButtonStyle())
                        .disabled(isButtonDisabled)
                        .opacity(isButtonDisabled ? 0.6 : 1.0)
                    }

                    // Success State
                    if sessionStore.didSubmit {
                        CSInlineMessage(
                            kind: .success,
                            title: "Check your email",
                            message: "Open the link on this phone to finish."
                        )

                        // Post-submit actions
                        HStack(spacing: DS.sm) {
                            Button("Resend link") {
                                Task {
                                    await sessionStore.sendMagicLink()
                                }
                            }
                            .buttonStyle(CSSecondaryButtonStyle())

                            Button("Change email") {
                                sessionStore.resetMessages()
                                isEmailFocused = true
                            }
                            .buttonStyle(CSSecondaryButtonStyle())
                        }
                    }

                    // Error Message
                    if let errorMessage = sessionStore.errorMessage {
                        CSInlineMessage(
                            kind: .error,
                            title: "Error",
                            message: errorMessage
                        )
                    }
                }
                .csCard()
                .csPagePadding()
                .csContentWidth()
            }
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var isButtonDisabled: Bool {
        sessionStore.email.isEmpty || sessionStore.isSubmitting
    }
}

#Preview {
    AuthView()
        .environmentObject(SessionStore())
}
