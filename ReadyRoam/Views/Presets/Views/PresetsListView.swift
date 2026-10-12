import SwiftUI

struct PresetsListView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var presets: [PresetSummaryDto] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingErrorAlert: Bool = false

    @State private var selectedPresetForEdit: PresetSummaryDto? = nil
    @State private var showingCreateEditor: Bool = false
    @State private var presetToDelete: PresetSummaryDto? = nil
    @State private var showingDeleteDialog: Bool = false

    private let presetService: any PresetServiceProtocol = AppContainer.shared.presetService

    var body: some View {
        ZStack {
            AppTheme.darkBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 14)

                if isLoading && presets.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(AppTheme.skyCyan)
                        .scaleEffect(1.2)
                    Spacer()
                } else if presets.isEmpty {
                    emptyStateView
                } else {
                    presetsList
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .simultaneousGesture(backSwipeGesture)
        .sheet(isPresented: $showingCreateEditor) {
            PresetEditorView { newPreset in
                Task {
                    await loadPresets()
                }
            }
        }
        .sheet(item: $selectedPresetForEdit) { preset in
            PresetEditorView(presetId: preset.id) { _ in
                Task {
                    await loadPresets()
                }
            }
        }
        .confirmationDialog(
            "Delete Preset?",
            isPresented: $showingDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let toDelete = presetToDelete {
                    Task {
                        await deletePreset(toDelete)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this preset? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unexpected error occurred.")
        }
        .task {
            await loadPresets()
        }
    }

    private var headerBar: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.darkSurface)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("USER PRESETS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundColor(AppTheme.skyCyan)

                Text("Packing Presets")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.leading, 6)

            Spacer()

            Button(action: {
                showingCreateEditor = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("New")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0284C7"), Color(hex: "2563EB")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
            }
        }
    }

    private var presetsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(presets) { preset in
                    presetRow(preset: preset)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 40)
        }
        .refreshable {
            await loadPresets()
        }
    }

    private func presetRow(preset: PresetSummaryDto) -> some View {
        Button(action: {
            selectedPresetForEdit = preset
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.electricBlue.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.skyCyan)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(preset.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text("\(preset.totalItemsCount) items")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.skyCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.skyCyan.opacity(0.14))
                            .clipShape(Capsule())
                    }

                    if let desc = preset.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(2)
                    }
                }

                Button(action: {
                    presetToDelete = preset
                    showingDeleteDialog = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "EF4444"))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "EF4444").opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.darkSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.skyCyan.opacity(0.12))
                    .frame(width: 76, height: 76)

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.skyCyan)
            }

            Text("No Packing Presets")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text("Create custom presets with your favorite packing lists to quickly apply them when planning new trips.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button(action: {
                showingCreateEditor = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Create Preset")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0284C7"), Color(hex: "2563EB")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
            }
            .padding(.top, 10)

            Spacer()
        }
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                if value.startLocation.x < 50 && value.translation.width > 60 && abs(value.translation.height) < 80 {
                    dismiss()
                }
            }
    }

    private func loadPresets() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await presetService.fetchPresets()
            guard !Task.isCancelled else { return }
            self.presets = fetched
        } catch {
            guard !Task.isCancelled else { return }
            self.errorMessage = error.localizedDescription
            self.showingErrorAlert = true
        }
    }

    private func deletePreset(_ preset: PresetSummaryDto) async {
        do {
            try await presetService.deletePreset(id: preset.id)
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    presets.removeAll { $0.id == preset.id }
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showingErrorAlert = true
            }
        }
    }
}
