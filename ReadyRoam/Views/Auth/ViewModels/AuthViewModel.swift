import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var authMode: AuthMode = .signIn
    @Published var authStep: AuthStep = .credentials

    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var isLoginPasswordVisible = false

    @Published var signupFirstName = ""
    @Published var signupLastName = ""
    @Published var signupEmail = ""
    @Published var signupPassword = ""
    @Published var signupRepeatPassword = ""
    @Published var isSignupPasswordVisible = false
    @Published var isSignupRepeatPasswordVisible = false

    @Published var forgotEmail = ""

    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    @Published var isLoading = false

    var onAuthenticated: (() -> Void)? = nil
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService.shared, onAuthenticated: (() -> Void)? = nil) {
        self.authService = authService
        self.onAuthenticated = onAuthenticated
    }

    var passwordsMatch: Bool {
        !signupPassword.isEmpty && signupPassword == signupRepeatPassword
    }

    func switchMode(_ mode: AuthMode) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.authMode = mode
            self.errorMessage = nil
        }
    }

    func handleSignIn() {
        let trimmedEmail = loginEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }
        guard !loginPassword.isEmpty else {
            errorMessage = "Please enter your password."
            return
        }
        clearMessages()
        isLoading = true

        Task {
            do {
                let result = try await authService.signIn(email: trimmedEmail, password: loginPassword)
                isLoading = false
                switch result {
                case .authenticated:
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.onAuthenticated?()
                    }
                case .requiresTwoFactor(let email, _):
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        self.authStep = .verification(purpose: .login, email: email)
                    }
                case .emailNotConfirmed(let email, _):
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        self.authStep = .verification(purpose: .register, email: email)
                    }
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func handleSignUp() {
        let trimmedFirst = signupFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = signupLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = signupEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFirst.isEmpty else {
            errorMessage = "Please enter your first name."
            return
        }
        guard !trimmedLast.isEmpty else {
            errorMessage = "Please enter your last name."
            return
        }
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter an email address."
            return
        }
        guard signupPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        guard passwordsMatch else {
            errorMessage = "Passwords do not match."
            return
        }
        clearMessages()
        isLoading = true

        Task {
            do {
                _ = try await authService.signUp(
                    firstName: trimmedFirst,
                    lastName: trimmedLast,
                    email: trimmedEmail,
                    password: signupPassword
                )
                isLoading = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.authStep = .verification(purpose: .register, email: trimmedEmail)
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func handleForgotPassword() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if !loginEmail.isEmpty {
                forgotEmail = loginEmail
            }
            authMode = .forgotPassword
            clearMessages()
        }
    }

    func handleSendResetCode() {
        let trimmedEmail = forgotEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        clearMessages()
        isLoading = true

        Task {
            do {
                _ = try await authService.forgotPassword(email: trimmedEmail)
                isLoading = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.authStep = .verification(purpose: .reset, email: trimmedEmail)
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func handleVerificationCompleted(purpose: VerificationPurpose) {
        if purpose == .reset {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                authStep = .credentials
                authMode = .signIn
                errorMessage = nil
                successMessage = "Password successfully reset! Please sign in with your new password."
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                onAuthenticated?()
            }
        }
    }

    func handleVerificationBack() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            authStep = .credentials
            errorMessage = nil
        }
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
