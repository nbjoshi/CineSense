//
//  AuthMode.swift
//  CineSense
//
//  Created by Neel Joshi on 12/31/25.
//

import Foundation

enum AuthMode: String, CaseIterable, Identifiable {
    case login = "Log in"
    case signup = "Sign up"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .login:
            return "Welcome back"
        case .signup:
            return "Create your account"
        }
    }

    var buttonLabel: String {
        switch self {
        case .login:
            return "Send login link"
        case .signup:
            return "Send sign-up link"
        }
    }
}
