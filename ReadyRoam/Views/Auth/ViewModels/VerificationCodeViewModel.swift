import Foundation
import SwiftUI

@MainActor
final class VerificationCodeViewModel: ObservableObject {
    let email: String
    let purpose: VerificationPurpose
    var onVerified: (() -> Void)?
    var onBack: (() -> Void)?

    @Published var code: String = ""
    @Published var newPassword: String = ""
    @Published var repeatNewPassword: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var isRepeatPasswordVisible: Bool = false

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    @Published var resendCooldown: Int = 0

    let codeLength: Int = 6
    private let authService: AuthServiceProtocol
    private var cooldownTask: Task<Void, Never>? = nil

    init(
        email: String,
        purpose: VerificationPurpose,
        authService: AuthServiceProtocol,
        onVerified: (() -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self.email = email
        self.purpose = purpose
        self.authService = authService
        self.onVerified = onVerified
        self.onBack = onBack
    }

    deinit {
        cooldownTask?.cancel()
    }

    func onDisappear() {
        cancelTimer()
    }

    func updateCode(_ newValue: String) {
        let filtered = newValue.unicodeScalars
            .filter { CharacterSet.decimalDigits.contains($0) }
            .map { String($0) }
            .joined()

        if filtered.count > codeLength {
            code = String(filtered.prefix(codeLength))
        } else {
            code = filtered
        }

        if code.count == codeLength && purpose != .reset && !isLoading {
            verify()
        }
    }

    var isCodeValid: Bool {
        code.count == codeLength
    }

    var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == repeatNewPassword
    }

    var isPasswordValid: Bool {
        newPassword.count >= 6 && passwordsMatch
    }

    var canSubmit: Bool {
        guard !isLoading && isCodeValid else { return false }
        if purpose == .reset {
            return isPasswordValid
        }
        return true
    }

    func character(at index: Int) -> String {
        guard index < code.count else { return "" }
        let startIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[startIndex])
    }

    func verify() {
        guard canSubmit else {
            if !isCodeValid {
                errorMessage = "Please enter the full 6-digit code."
            } else if purpose == .reset && !passwordsMatch {
                errorMessage = "Passwords do not match."
            } else if purpose == .reset && newPassword.count < 6 {
                errorMessage = "New password must be at least 6 characters."
            }
            return
        }

        clearMessages()
        isLoading = true

        Task {
            defer { isLoading = false }
            do {
                switch purpose {
                case .register:
                    try await authService.confirmEmail(email: email, code: code)
                    onVerified?()

                case .login:
                    try await authService.verifyLogin(email: email, code: code)
                    onVerified?()

                case .reset:
                    let msg = try await authService.resetPassword(email: email, code: code, newPassword: newPassword)
                    successMessage = msg
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    if !Task.isCancelled {
                        onVerified?()
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func resendCode() {
        guard resendCooldown <= 0 && !isLoading else { return }

        clearMessages()
        isLoading = true

        Task {
            defer { isLoading = false }
            do {
                let msg = try await authService.resendCode(email: email, purpose: purpose.rawValue)
                successMessage = msg
                startResendTimer()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func startResendTimer() {
        cancelTimer()
        resendCooldown = 30

        cooldownTask = Task { [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self, !Task.isCancelled else { break }

                if self.resendCooldown > 1 {
                    self.resendCooldown -= 1
                } else {
                    self.resendCooldown = 0
                    break
                }
            }
        }
    }

    private func cancelTimer() {
        cooldownTask?.cancel()
        cooldownTask = nil
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
