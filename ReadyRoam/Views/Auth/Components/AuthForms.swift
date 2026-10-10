import SwiftUI

struct AuthModeSwitcherView: View {
    @ObservedObject var viewModel: AuthViewModel
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 10) {
            ForEach([AuthMode.signIn, AuthMode.signUp]) { mode in
                Button(action: {
                    viewModel.switchMode(mode)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 14, weight: .bold))

                        Text(mode.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(viewModel.authMode == mode ? .white : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background {
                        if viewModel.authMode == mode {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.electricBlue)
                                .shadow(color: AppTheme.electricBlue.opacity(0.55), radius: 12, x: 0, y: 4)
                                .matchedGeometryEffect(id: "ActiveTab", in: namespace)
                        } else {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.darkSurfaceAlt)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(AppTheme.inputBorder.opacity(0.7), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }
}

struct SignInFormView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 18) {
            DarkInputField(
                title: "Email",
                icon: "envelope.fill",
                placeholder: "Enter your email",
                text: $viewModel.loginEmail,
                keyboardType: .emailAddress,
                isSecure: false
            )

            VStack(alignment: .trailing, spacing: 6) {
                DarkInputField(
                    title: "Password",
                    icon: "lock.fill",
                    placeholder: "Enter your password",
                    text: $viewModel.loginPassword,
                    keyboardType: .default,
                    isSecure: !viewModel.isLoginPasswordVisible,
                    trailingContent: {
                        Button(action: { viewModel.isLoginPasswordVisible.toggle() }) {
                            Image(systemName: viewModel.isLoginPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                )

                Button(action: viewModel.handleForgotPassword) {
                    Text("Forgot Password?")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.skyCyan)
                }
                .padding(.top, 4)
            }

            AuthActionButton(
                title: "Sign In",
                icon: "arrow.right",
                isLoading: viewModel.isLoading,
                action: viewModel.handleSignIn
            )
            .padding(.top, 6)
        }
    }
}

struct SignUpFormView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                DarkInputField(
                    title: "First Name",
                    icon: "person.fill",
                    placeholder: "First name",
                    text: $viewModel.signupFirstName,
                    keyboardType: .default,
                    isSecure: false
                )

                DarkInputField(
                    title: "Last Name",
                    icon: "person.fill",
                    placeholder: "Last name",
                    text: $viewModel.signupLastName,
                    keyboardType: .default,
                    isSecure: false
                )
            }

            DarkInputField(
                title: "Email",
                icon: "envelope.fill",
                placeholder: "Enter your email",
                text: $viewModel.signupEmail,
                keyboardType: .emailAddress,
                isSecure: false
            )

            DarkInputField(
                title: "Password",
                icon: "lock.fill",
                placeholder: "Create a password (min 6 chars)",
                text: $viewModel.signupPassword,
                keyboardType: .default,
                isSecure: !viewModel.isSignupPasswordVisible,
                trailingContent: {
                    Button(action: { viewModel.isSignupPasswordVisible.toggle() }) {
                        Image(systemName: viewModel.isSignupPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            )

            DarkInputField(
                title: "Repeat Password",
                icon: "lock.shield.fill",
                placeholder: "Repeat your password",
                text: $viewModel.signupRepeatPassword,
                keyboardType: .default,
                isSecure: !viewModel.isSignupRepeatPasswordVisible,
                trailingContent: {
                    HStack(spacing: 8) {
                        if !viewModel.signupRepeatPassword.isEmpty {
                            Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.passwordsMatch ? AppTheme.accentMint : AppTheme.accentCoral)
                                .font(.system(size: 16, weight: .bold))
                        }
                        Button(action: { viewModel.isSignupRepeatPasswordVisible.toggle() }) {
                            Image(systemName: viewModel.isSignupRepeatPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            )

            AuthActionButton(
                title: "Sign Up",
                icon: "arrow.right",
                isLoading: viewModel.isLoading,
                action: viewModel.handleSignUp
            )
            .padding(.top, 6)
        }
    }
}

struct ForgotPasswordFormView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppTheme.electricBlue.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "key.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppTheme.skyCyan)
                }

                Text("Forgot Password")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Enter your account email and we'll send you a 6-digit code to reset your password.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            .padding(.bottom, 4)

            DarkInputField(
                title: "Email",
                icon: "envelope.fill",
                placeholder: "Enter your email",
                text: $viewModel.forgotEmail,
                keyboardType: .emailAddress,
                isSecure: false
            )

            AuthActionButton(
                title: "Send Reset Code",
                icon: "paperplane.fill",
                isLoading: viewModel.isLoading,
                action: viewModel.handleSendResetCode
            )
            .padding(.top, 4)

            HStack(spacing: 6) {
                Text("Remember your password?")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)

                Button(action: {
                    viewModel.switchMode(.signIn)
                }) {
                    Text("Sign In")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.skyCyan)
                }
            }
            .padding(.top, 4)
        }
    }
}

struct AuthFooterToggleView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        HStack(spacing: 6) {
            Text(viewModel.authMode == .signIn ? "Don't have an account?" : "Already have an account?")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)

            Button(action: {
                viewModel.switchMode(viewModel.authMode == .signIn ? .signUp : .signIn)
            }) {
                Text(viewModel.authMode == .signIn ? "Sign Up" : "Sign In")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.skyCyan)
            }
        }
    }
}
