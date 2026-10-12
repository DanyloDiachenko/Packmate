import SwiftUI

struct NewTripView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter

    enum TripCreationMode {
        case manual
        case aiAssistant
    }

    @State private var creationMode: TripCreationMode = .manual
    @StateObject private var aiViewModel: AITripGeneratorViewModel = AITripGeneratorViewModel()
    @StateObject private var viewModel: NewTripViewModel
    @FocusState private var isSearchFieldFocused: Bool

    @State private var searchTask: Task<Void, Never>? = nil

    var onTripCreated: ((Trip) -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    @Binding var dragOffset: CGFloat

    init(
        existingTrips: [Trip] = [],
        onTripCreated: ((Trip) -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        dragOffset: Binding<CGFloat> = .constant(0),
        viewModel: NewTripViewModel? = nil
    ) {
        self.onTripCreated = onTripCreated
        self.onCancel = onCancel
        self._dragOffset = dragOffset
        let container = AppContainer.shared
        self._viewModel = StateObject(wrappedValue: viewModel ?? NewTripViewModel(
            existingTrips: existingTrips,
            tripService: container.tripService,
            tripItemService: container.tripItemService,
            destinationService: container.destinationService,
            presetService: container.presetService
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.darkBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 38, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    headerBar
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 10)

                    modeSwitchBar
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 60 {
                                cancelView()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )

                if creationMode == .aiAssistant {
                    ScrollView(showsIndicators: false) {
                        AITripGeneratorView(
                            viewModel: aiViewModel,
                            onTripCreated: { createdTrip in
                                viewModel.addTrip(createdTrip)
                                onTripCreated?(createdTrip)
                                cancelView()
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 16)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        ZStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 22) {
                                DestinationSearchSection(
                                    destinationText: $viewModel.destinationText,
                                    isSearchActive: viewModel.isSearchActive,
                                    focusState: $isSearchFieldFocused,
                                    onClear: {
                                        viewModel.destinationText = ""
                                        viewModel.selectedDestination = nil
                                    },
                                    onTap: {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                            viewModel.isSearchActive = true
                                            isSearchFieldFocused = true
                                        }
                                        if viewModel.searchResults.isEmpty {
                                            Task {
                                                await viewModel.fetchDestinations(query: viewModel.destinationText)
                                            }
                                        }
                                    }
                                )

                                TripCalendarView(
                                    dateSelection: $viewModel.dateSelection,
                                    blockedDates: viewModel.blockedDates,
                                    onDateTap: { date in
                                        viewModel.handleDateTap(date: date)
                                    },
                                    onPrevMonth: {
                                        if viewModel.dateSelection.viewingMonthIndex > 0 {
                                            viewModel.dateSelection.viewingMonthIndex -= 1
                                        }
                                    },
                                    onNextMonth: {
                                        if viewModel.dateSelection.viewingMonthIndex < viewModel.dateSelection.availableMonths.count - 1 {
                                            viewModel.dateSelection.viewingMonthIndex += 1
                                        }
                                    }
                                )

                                presetSelectorSection

                                TripTypeSelector(selectedTripTypes: $viewModel.selectedTripTypes)
                            }

                            if viewModel.isSearchActive {
                                Color.black.opacity(0.001)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        closeSearchSelector()
                                    }
                                    .zIndex(15)

                                DestinationDropdownCard(
                                    destinationText: viewModel.destinationText,
                                    isLoading: viewModel.isLoadingDestinations,
                                    results: viewModel.searchResults,
                                    onSelect: { item in
                                        viewModel.selectDestination(item)
                                        isSearchFieldFocused = false
                                    },
                                    onClose: {
                                        closeSearchSelector()
                                    }
                                )
                                .padding(.top, 78)
                                .zIndex(20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 90)
                    }
                }
            }

            if creationMode == .manual {
                fixedBottomBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .alert("Error Creating Trip", isPresented: $viewModel.showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
        }
        .task {
            await viewModel.loadInitialData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didDeleteTrip)) { notification in
            if let deletedId = notification.object as? UUID {
                viewModel.removeTrip(id: deletedId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCreateNewTrip)) { notification in
            if let createdTrip = notification.object as? Trip {
                viewModel.addTrip(createdTrip)
            } else {
                Task {
                    await viewModel.refreshTrips()
                }
            }
        }
        .onChange(of: router.isShowingNewTripDrawer) { isShowing in
            if isShowing {
                Task {
                    await viewModel.refreshTrips()
                }
            }
        }
        .onChange(of: isSearchFieldFocused) { isFocused in
            if isFocused {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    viewModel.isSearchActive = true
                }
                if viewModel.searchResults.isEmpty {
                    Task {
                        await viewModel.fetchDestinations(query: viewModel.destinationText)
                    }
                }
            } else if viewModel.isSearchActive {
                closeSearchSelector()
            }
        }
        .onChange(of: viewModel.destinationText) { newText in
            guard !viewModel.isSelectingDestination else { return }
            if let selected = viewModel.selectedDestination {
                let formatted = "\(selected.city), \(selected.country)"
                if newText != formatted && newText != selected.city {
                    viewModel.selectedDestination = nil
                }
            }
            if !viewModel.isSearchActive && isSearchFieldFocused {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    viewModel.isSearchActive = true
                }
            }
            searchTask?.cancel()
            viewModel.isLoadingDestinations = true
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 280_000_000)
                if !Task.isCancelled {
                    await viewModel.fetchDestinations(query: newText)
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    if value.startLocation.x < 50 && value.translation.width > 60 && abs(value.translation.height) < 80 {
                        cancelView()
                    }
                }
        )
    }

    private func closeSearchSelector() {
        isSearchFieldFocused = false
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            viewModel.isSearchActive = false
        }
    }

    private func cancelView() {
        isSearchFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        viewModel.resetState()
        aiViewModel.reset()
        if let onCancel = onCancel {
            onCancel()
        } else {
            dismiss()
        }
    }

    private var modeSwitchBar: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    creationMode = .manual
                }
                viewModel.validateAndAdjustSelectedDates()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .bold))
                    Text("Manual")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(creationMode == .manual ? .white : AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(creationMode == .manual ? Color(hex: "273142") : Color.clear)
                )
            }
            .buttonStyle(.plain)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    creationMode = .aiAssistant
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("AI Generator")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(creationMode == .aiAssistant ? .white : AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(creationMode == .aiAssistant ? AppTheme.electricBlue : Color.clear)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "151821"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private var headerBar: some View {
        HStack {
            Button(action: {
                cancelView()
            }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppTheme.skyCyan)
                    .contentShape(Rectangle())
                    .frame(minWidth: 54, minHeight: 36, alignment: .leading)
            }

            Spacer()

            Text("New Trip")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Text("Cancel")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.clear)
                .accessibilityHidden(true)
                .frame(minWidth: 54, minHeight: 36, alignment: .trailing)
        }
    }

    private var fixedBottomBar: some View {
        VStack(spacing: 0) {
            Button(action: {
                Task {
                    await viewModel.handleCreateTrip { createdTrip in
                        onTripCreated?(createdTrip)
                        cancelView()
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isCreatingTrip {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: viewModel.isFormValid ? "plus" : "circle.slash")
                            .font(.system(size: 15, weight: .bold))
                    }

                    Text(viewModel.isCreatingTrip ? "Creating Trip..." : "Create Trip")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(viewModel.isFormValid ? .white : AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    if viewModel.isFormValid {
                        LinearGradient(
                            colors: [Color(hex: "0284C7"), Color(hex: "2563EB")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(26)
                    } else {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color(hex: "252A36"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                }
                .shadow(color: viewModel.isFormValid ? AppTheme.electricBlue.opacity(0.55) : Color.clear, radius: 14, x: 0, y: 5)
            }
            .disabled(!viewModel.isFormValid || viewModel.isCreatingTrip)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [Color.clear, AppTheme.darkBackground.opacity(0.85), AppTheme.darkBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var presetSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PACKING PRESET")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                if viewModel.isLoadingPresets {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(AppTheme.skyCyan)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button(action: {
                        viewModel.selectedPreset = nil
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 13, weight: .semibold))
                            Text("No Preset")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(viewModel.selectedPreset == nil ? .white : AppTheme.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(viewModel.selectedPreset == nil ? AppTheme.electricBlue : Color(hex: "1F2432"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(viewModel.selectedPreset == nil ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    ForEach(viewModel.availablePresets) { preset in
                        let isSelected = viewModel.selectedPreset?.id == preset.id
                        Button(action: {
                            viewModel.selectedPreset = isSelected ? nil : preset
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 13, weight: .semibold))

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(preset.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                        .lineLimit(1)

                                    Text("\(preset.totalItemsCount) items")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(isSelected ? Color.white.opacity(0.85) : AppTheme.textMuted)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? AppTheme.electricBlue : Color(hex: "1F2432"))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct NewTripView_Previews: PreviewProvider {
    static var previews: some View {
        NewTripView()
    }
}
