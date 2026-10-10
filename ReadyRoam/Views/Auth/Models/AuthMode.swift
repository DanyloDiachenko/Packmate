import Foundation

enum AuthMode: String, CaseIterable, Identifiable {
    case signIn = "Sign In"
    case signUp = "Sign Up"
    case forgotPassword = "Forgot Password"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .signIn: return "arrow.right.circle.fill"
        case .signUp: return "person.crop.circle.badge.plus"
        case .forgotPassword: return "key.fill"
        }
    }
}

enum AuthStep: Equatable {
    case credentials
    case verification(purpose: VerificationPurpose, email: String)
}
