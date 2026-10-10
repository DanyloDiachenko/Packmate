import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel
    @Namespace private var tabAnimation

    init(onAuthenticated: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: AppContainer.shared.authService, onAuthenticated: onAuthenticated))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuthBackgroundGlowView()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        AuthHeaderView()
                            .padding(.top, 20)

                        if case .verification(let purpose, let targetEmail) = viewModel.authStep {
                            verificationCard(purpose: purpose, email: targetEmail)
                        } else {
                            credentialsCard
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.28), value: viewModel.authMode)
        }
    }

    @ViewBuilder
    private var credentialsCard: some View {
        VStack(spacing: 24) {
            if viewModel.authMode != .forgotPassword {
                AuthModeSwitcherView(viewModel: viewModel, namespace: tabAnimation)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 20) {
                if let error = viewModel.errorMessage {
                    AuthBannerView(text: error, type: .error)
                } else if let success = viewModel.successMessage {
                    AuthBannerView(text: success, type: .success)
                }

                switch viewModel.authMode {
                case .signIn:
                    SignInFormView(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                case .signUp:
                    SignUpFormView(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .forgotPassword:
                    ForgotPasswordFormView(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.darkSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
            )
            .padding(.horizontal, 20)

            if viewModel.authMode != .forgotPassword {
                AuthFooterToggleView(viewModel: viewModel)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
            }
        }
    }

    private func verificationCard(purpose: VerificationPurpose, email: String) -> some View {
        VStack(spacing: 20) {
            VerificationCodeView(
                email: email,
                purpose: purpose,
                onVerified: {
                    viewModel.handleVerificationCompleted(purpose: purpose)
                },
                onBack: {
                    viewModel.handleVerificationBack()
                }
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
        )
        .padding(.horizontal, 20)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .previewDisplayName("Dark Themed Auth")
    }
}
