import SwiftUI

public enum VerificationPurpose: String {
    case register = "register"
    case login = "login"
    case reset = "reset"

    var title: String {
        switch self {
        case .register: return "Verify Email"
        case .login: return "2FA Verification"
        case .reset: return "Reset Password"
        }
    }

    var subtitle: String {
        switch self {
        case .register: return "Enter the 6-digit code sent to your email to activate your account."
        case .login: return "Enter the 6-digit login verification code sent to your email."
        case .reset: return "Enter the 6-digit code sent to your email and create a new password."
        }
    }

    var iconName: String {
        switch self {
        case .register: return "envelope.badge.shield.half.filled"
        case .login: return "lock.shield.fill"
        case .reset: return "key.fill"
        }
    }

    var buttonTitle: String {
        switch self {
        case .register: return "Verify Email"
        case .login: return "Verify & Log In"
        case .reset: return "Reset Password"
        }
    }
}

struct VerificationCodeView: View {
    @StateObject private var viewModel: VerificationCodeViewModel
    @FocusState private var isCodeFocused: Bool

    init(
        email: String,
        purpose: VerificationPurpose,
        onVerified: (() -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: VerificationCodeViewModel(
            email: email,
            purpose: purpose,
            authService: AppContainer.shared.authService,
            onVerified: onVerified,
            onBack: onBack
        ))
    }

    var body: some View {
        VStack(spacing: 24) {
            topNavigationHeader

            infoBadgeHeader

            if let error = viewModel.errorMessage {
                AuthBannerView(text: error, type: .error)
            } else if let success = viewModel.successMessage {
                AuthBannerView(text: success, type: .success)
            }

            codeInputGrid

            if viewModel.purpose == .reset {
                passwordResetFields
            }

            AuthActionButton(
                title: viewModel.purpose.buttonTitle,
                icon: "arrow.right",
                isLoading: viewModel.isLoading,
                action: { viewModel.verify() }
            )
            .disabled(!viewModel.canSubmit)
            .opacity(viewModel.canSubmit ? 1.0 : 0.6)

            resendFooter
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isCodeFocused = true
            }
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var topNavigationHeader: some View {
        HStack {
            Button(action: { viewModel.onBack?() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                    Text("Back")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(AppTheme.skyCyan)
            }

            Spacer()

            Text(viewModel.purpose.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 60, height: 20)
        }
        .padding(.top, 4)
    }

    private var infoBadgeHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.electricBlue.opacity(0.2))
                    .frame(width: 64, height: 64)

                Image(systemName: viewModel.purpose.iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppTheme.skyCyan)
            }

            Text(viewModel.purpose.subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            HStack(spacing: 6) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.skyCyan)

                Text(viewModel.email)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(AppTheme.darkSurfaceAlt)
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.inputBorder, lineWidth: 1)
                    )
            )
        }
    }

    private var codeInputGrid: some View {
        VStack(spacing: 10) {
            ZStack {
                TextField("", text: Binding(
                    get: { viewModel.code },
                    set: { viewModel.updateCode($0) }
                ))
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFocused)
                .opacity(0.01)

                HStack(spacing: 8) {
                    ForEach(0..<viewModel.codeLength, id: \.self) { index in
                        let char = viewModel.character(at: index)
                        let isFocusedBox = isCodeFocused && (viewModel.code.count == index || (viewModel.code.count == viewModel.codeLength && index == viewModel.codeLength - 1))

                        Text(char)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(width: 44, height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.inputBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        isFocusedBox ? AppTheme.electricBlue : (char.isEmpty ? AppTheme.inputBorder : AppTheme.skyCyan.opacity(0.6)),
                                        lineWidth: isFocusedBox ? 2 : 1
                                    )
                            )
                            .shadow(color: isFocusedBox ? AppTheme.electricBlue.opacity(0.4) : .clear, radius: 8)
                    }
                }
            }
            .onTapGesture {
                isCodeFocused = true
            }
        }
    }

    private var passwordResetFields: some View {
        VStack(spacing: 14) {
            DarkInputField(
                title: "New Password",
                icon: "lock.fill",
                placeholder: "Min 6 characters",
                text: $viewModel.newPassword,
                isSecure: !viewModel.isPasswordVisible,
                trailingContent: {
                    Button(action: { viewModel.isPasswordVisible.toggle() }) {
                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            )

            DarkInputField(
                title: "Repeat New Password",
                icon: "lock.shield.fill",
                placeholder: "Repeat new password",
                text: $viewModel.repeatNewPassword,
                isSecure: !viewModel.isRepeatPasswordVisible,
                trailingContent: {
                    HStack(spacing: 8) {
                        if !viewModel.repeatNewPassword.isEmpty {
                            Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.passwordsMatch ? AppTheme.accentMint : AppTheme.accentCoral)
                                .font(.system(size: 16, weight: .bold))
                        }
                        Button(action: { viewModel.isRepeatPasswordVisible.toggle() }) {
                            Image(systemName: viewModel.isRepeatPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            )
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var resendFooter: some View {
        HStack(spacing: 6) {
            Text("Didn't receive the code?")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)

            Button(action: { viewModel.resendCode() }) {
                if viewModel.resendCooldown > 0 {
                    Text("Resend in \(viewModel.resendCooldown)s")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textMuted)
                } else {
                    Text("Resend Code")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.skyCyan)
                }
            }
            .disabled(viewModel.resendCooldown > 0 || viewModel.isLoading)
        }
        .padding(.top, 4)
    }
}
