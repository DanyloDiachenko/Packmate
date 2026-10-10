import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var onLogout: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil
    @ObservedObject private var authService = AuthService.shared

    @State private var showingLogoutDialog = false
    @State private var showingEditProfile = false
    @State private var editFirstName = ""
    @State private var editLastName = ""
    @State private var isSavingProfile = false
    @State private var profileErrorMessage: String? = nil

    var body: some View {
        ZStack {
            AppTheme.darkBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerBar
                        .padding(.top, 8)

                    profileCard

                    aboutSection

                    logoutButton
                        .padding(.top, 4)
                        .padding(.bottom, 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingEditProfile) {
            editProfileSheet
        }
    }

    private func handleBackNavigation() {
        if let onBack = onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("ACCOUNT & PREFERENCES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundColor(AppTheme.skyCyan)

                Text("Settings")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()
        }
    }

    private var profileCard: some View {
        let user = authService.currentUser
        let displayName = user?.fullName ?? "Traveler"
        let displayEmail = user?.email ?? "traveler@example.com"
        let displayInitial = user?.initial ?? "T"

        return Button(action: {
            editFirstName = user?.firstName ?? ""
            editLastName = user?.lastName ?? ""
            profileErrorMessage = nil
            showingEditProfile = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "818CF8"), Color(hex: "A855F7")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: Color(hex: "A855F7").opacity(0.4), radius: 10, x: 0, y: 4)

                    Text(displayInitial)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(displayEmail)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .medium))
                        Text("Edit profile")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(AppTheme.skyCyan)
                    .padding(.top, 2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(18)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("ABOUT")

            VStack(spacing: 0) {
                settingRow(
                    icon: "questionmark.circle.fill",
                    iconColor: AppTheme.skyCyan,
                    title: "Help & Support"
                )

                divider

                settingRow(
                    icon: "lock.shield.fill",
                    iconColor: Color(hex: "10B981"),
                    title: "Privacy Policy"
                )

                divider

                versionRow
            }
            .background(cardBackground)
        }
    }

    private var versionRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "1F2432"))
                    .frame(width: 32, height: 32)

                Image(systemName: "info.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Text("Version")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Text(appVersionString)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (Build \(build))"
    }

    private var logoutButton: some View {
        Button(action: {
            showingLogoutDialog = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text("Log Out")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(Color(hex: "EF4444"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "EF4444").opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: "EF4444").opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .confirmationDialog("Are you sure you want to log out?", isPresented: $showingLogoutDialog, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.28)) {
                    authService.logout()
                    onLogout?()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var editProfileSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.darkBackground
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    if let profileErrorMessage = profileErrorMessage {
                        profileErrorBanner(text: profileErrorMessage)
                    }

                    SettingsTextField(title: "First Name", text: $editFirstName)

                    SettingsTextField(title: "Last Name", text: $editLastName)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingEditProfile = false
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveProfile) {
                        if isSavingProfile {
                            ProgressView()
                                .tint(AppTheme.skyCyan)
                        } else {
                            Text("Save")
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.skyCyan)
                        }
                    }
                    .disabled(isSavingProfile || editFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(340)])
        .preferredColorScheme(.dark)
    }

    private func profileErrorBanner(text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(hex: "EF4444"))
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "EF4444"))
            Spacer()
        }
        .padding(14)
        .background(Color(hex: "EF4444").opacity(0.12))
        .cornerRadius(12)
    }

    @MainActor
    private func saveProfile() {
        guard !isSavingProfile else { return }

        isSavingProfile = true
        profileErrorMessage = nil

        Task {
            defer { isSavingProfile = false }
            do {
                let trimmedFirst = editFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedLast = editLastName.trimmingCharacters(in: .whitespacesAndNewlines)
                try await authService.updateProfile(firstName: trimmedFirst, lastName: trimmedLast)
                showingEditProfile = false
            } catch {
                profileErrorMessage = error.localizedDescription
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(1.2)
            .foregroundColor(AppTheme.textMuted)
            .padding(.leading, 4)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(AppTheme.darkSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }

    private var divider: some View {
        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.leading, 56)
    }

    private func settingRow(
        icon: String,
        iconColor: Color,
        title: String,
        action: (() -> Void)? = nil
    ) -> some View {
        Button(action: { action?() }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "1F2432"))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

private struct SettingsTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(AppTheme.textMuted)

            TextField(title, text: $text)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textPrimary)
                .padding(14)
                .background(AppTheme.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
