import SwiftUI

struct NewTripView: View {
    @Environment(\.dismiss) private var dismiss

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
            destinationService: container.destinationService
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
                        .padding(.bottom, 12)
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

            fixedBottomBar
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
        if let onCancel = onCancel {
            onCancel()
        } else {
            dismiss()
        }
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
}

struct NewTripView_Previews: PreviewProvider {
    static var previews: some View {
        NewTripView()
    }
}
