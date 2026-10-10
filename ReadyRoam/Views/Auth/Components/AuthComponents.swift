import SwiftUI

struct DarkInputField<TrailingContent: View>: View {
    let title: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    @ViewBuilder var trailingContent: () -> TrailingContent

    init(
        title: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.trailingContent = trailingContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.skyCyan)
                    .frame(width: 20)

                if isSecure {
                    SecureField(
                        "",
                        text: $text,
                        prompt: Text(placeholder)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    )
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                } else {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(placeholder)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    )
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }

                trailingContent()
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.inputBorder, lineWidth: 1)
            )
        }
    }
}

struct AuthActionButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                AppTheme.buttonGradient
                    .cornerRadius(14)
            )
            .shadow(color: AppTheme.electricBlue.opacity(0.5), radius: 14, x: 0, y: 6)
        }
        .disabled(isLoading)
    }
}

enum AuthBannerType {
    case error
    case success

    var iconName: String {
        switch self {
        case .error: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .error: return AppTheme.accentCoral
        case .success: return AppTheme.accentMint
        }
    }
}

struct AuthBannerView: View {
    let text: String
    let type: AuthBannerType

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.iconName)
                .foregroundColor(type.color)
                .font(.system(size: 14))

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(type.color)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(type.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct AuthHeaderView: View {
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.logoGradient)
                    .frame(width: 76, height: 76)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: AppTheme.electricBlue.opacity(0.5), radius: 20, x: 0, y: 8)

                ZStack {
                    Capsule()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 14, height: 3)
                        .rotationEffect(.degrees(-35))
                        .offset(x: -16, y: 14)

                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 10, height: 2)
                        .rotationEffect(.degrees(-35))
                        .offset(x: -20, y: 19)

                    Image(systemName: "airplane")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(-45))
                }
            }

            VStack(spacing: 4) {
                Text("ReadyRoam")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                Text("ReadyRoam TRAVEL CHECKLIST")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundColor(AppTheme.skyCyan)
            }
        }
    }
}

struct AuthBackgroundGlowView: View {
    var body: some View {
        ZStack {
            AppTheme.darkBackground
                .ignoresSafeArea()

            VStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.electricBlue.opacity(0.28))
                        .frame(width: 320, height: 320)
                        .blur(radius: 80)
                        .offset(y: -40)

                    Circle()
                        .fill(AppTheme.skyCyan.opacity(0.16))
                        .frame(width: 240, height: 240)
                        .blur(radius: 65)
                        .offset(x: 70, y: -20)
                }
                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}
