import SwiftUI

struct TripDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var isViewingTripDetails: Bool
    @Binding var isShowingAIDrawer: Bool
    @StateObject private var viewModel: TripDetailsViewModel

    init(
        isViewingTripDetails: Binding<Bool> = .constant(false),
        isShowingAIDrawer: Binding<Bool> = .constant(false),
        trip: Trip,
        isReadOnly: Bool = false,
        onTripDeleted: ((UUID) -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self._isViewingTripDetails = isViewingTripDetails
        self._isShowingAIDrawer = isShowingAIDrawer
        _viewModel = StateObject(wrappedValue: TripDetailsViewModel(
            trip: trip,
            isReadOnly: isReadOnly,
            onTripDeleted: onTripDeleted,
            onBack: onBack
        ))
    }

    init(
        isViewingTripDetails: Binding<Bool> = .constant(false),
        isShowingAIDrawer: Binding<Bool> = .constant(false),
        tripId: UUID? = nil,
        city: String = "",
        country: String = "",
        flagEmoji: String = "",
        dateRange: String = "",
        nightsCount: Int = 0,
        weatherToday: String? = nil,
        currentSeason: String? = nil,
        isReadOnly: Bool = false,
        onTripDeleted: ((UUID) -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self._isViewingTripDetails = isViewingTripDetails
        self._isShowingAIDrawer = isShowingAIDrawer
        _viewModel = StateObject(wrappedValue: TripDetailsViewModel(
            tripId: tripId,
            city: city,
            country: country,
            flagEmoji: flagEmoji,
            dateRange: dateRange,
            nightsCount: nightsCount,
            weatherToday: weatherToday,
            currentSeason: currentSeason,
            isReadOnly: isReadOnly,
            onTripDeleted: onTripDeleted,
            onBack: onBack
        ))
    }

    var body: some View {
        mainContent
            .overlay {
                drawerOverlayMask
            }
            .overlay(alignment: .bottom) {
                drawerContent
            }
            .navigationBarBackButtonHidden(true)
            .preferredColorScheme(.dark)
            .simultaneousGesture(backSwipeGesture)
            .confirmationDialog("Are you sure you want to delete this trip?", isPresented: $viewModel.showingDeleteDialog, titleVisibility: .visible) {
                Button("Delete Trip", role: .destructive) {
                    Task {
                        await viewModel.handleDeleteTrip(dismiss: { dismiss() })
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Error", isPresented: $viewModel.showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.itemErrorMessage ?? "An unexpected error occurred.")
            }
            .task {
                await viewModel.loadInitialData()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isViewingTripDetails = true
                }
            }
            .onDisappear {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isViewingTripDetails = false
                    isShowingAIDrawer = false
                }
            }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            AppTheme.darkBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                fixedHeaderSection
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 14)
                    .background(AppTheme.darkBackground)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if viewModel.isLoadingItems && viewModel.categories.allSatisfy({ $0.items.isEmpty }) {
                            loadingChecklistItemsView
                        } else {
                            categoryCardsList

                            if viewModel.tripId != nil && !viewModel.isReadOnly {
                                deleteTripButton
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 180)
                }
                .refreshable {
                    await viewModel.loadTripItems()
                }
            }

            if !viewModel.isReadOnly {
                TripDetailsBottomBarView(
                    onOpenAI: { viewModel.openAIDrawer(isShowingAIDrawerBinding: $isShowingAIDrawer) },
                    onOpenAddItem: { viewModel.openAddItemDrawer(isShowingAIDrawerBinding: $isShowingAIDrawer) }
                )
            }
        }
        .blur(radius: viewModel.isAnyDrawerOpen ? 5 : 0)
        .allowsHitTesting(!viewModel.isAnyDrawerOpen)
    }

    private var fixedHeaderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            TripDetailsHeaderView(
                flagEmoji: viewModel.flagEmoji,
                city: viewModel.city,
                dateRange: viewModel.dateRange,
                nightsCount: viewModel.nightsCount,
                isReadOnly: viewModel.isReadOnly,
                onBack: { viewModel.handleBackNavigation(dismiss: { dismiss() }) }
            )

            WeatherProgressCardView(
                isLoadingWeather: viewModel.isLoadingWeather,
                hasWeatherInfo: viewModel.hasWeatherInfo,
                weatherIconDisplay: viewModel.weatherIconDisplay,
                temperatureDisplay: viewModel.temperatureDisplay,
                weatherSeasonDisplay: viewModel.weatherSeasonDisplay,
                totalPacked: viewModel.totalPacked,
                totalItems: viewModel.totalItems,
                overallProgress: viewModel.overallProgress
            )
        }
    }

    private var loadingChecklistItemsView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.skyCyan))
            Text("Loading checklist items...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
        }
        .padding(.vertical, 30)
    }

    private var categoryCardsList: some View {
        ForEach($viewModel.categories) { $category in
            ChecklistCategoryCard(
                category: $category,
                isExpanded: viewModel.expandedCategoryIds.contains(category.id),
                swipedItemId: viewModel.swipedItemId,
                isReadOnly: viewModel.isReadOnly,
                onToggleExpand: {
                    viewModel.toggleCategoryExpanded(category.id)
                },
                onAddItem: {
                    viewModel.openAddItemDrawer(for: category.title, isShowingAIDrawerBinding: $isShowingAIDrawer)
                },
                onSwipeItem: { itemId, isOpen in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        if isOpen {
                            viewModel.swipedItemId = itemId
                        } else if viewModel.swipedItemId == itemId {
                            viewModel.swipedItemId = nil
                        }
                    }
                },
                onDeleteItem: { item in
                    viewModel.handleDeleteItem(item: item, categoryId: category.id)
                },
                onToggleItem: { item in
                    viewModel.handleToggleItem(item: item)
                }
            )
        }
    }

    private var deleteTripButton: some View {
        Button(action: {
            viewModel.showingDeleteDialog = true
        }) {
            HStack(spacing: 8) {
                if viewModel.isDeletingTrip {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "EF4444")))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(viewModel.isDeletingTrip ? "Deleting Trip..." : "Delete Trip")
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
        .disabled(viewModel.isDeletingTrip)
        .padding(.top, 14)
    }

    private var drawerOverlayMask: some View {
        DrawerOverlayMask(
            isShowing: viewModel.isAnyDrawerOpen,
            onTap: {
                viewModel.closeDrawer(isShowingAIDrawerBinding: $isShowingAIDrawer)
            }
        )
    }

    private var drawerContent: some View {
        ZStack(alignment: .bottom) {
            aiSuggestionsDrawerSection
            addItemDrawerSection
        }
    }

    private var aiSuggestionsDrawerSection: some View {
        SlidingDrawerContainer(
            isShowing: viewModel.showingAIDrawer,
            height: viewModel.drawerHeight,
            dragOffset: $viewModel.dragOffset,
            onDismiss: {
                viewModel.closeDrawer(isShowingAIDrawerBinding: $isShowingAIDrawer)
            },
            onDragReset: {
                viewModel.resetDrawerOffset()
            }
        ) {
            AISuggestionsDrawer(
                cityName: viewModel.city,
                country: viewModel.country,
                season: viewModel.effectiveCurrentSeason ?? "",
                temperature: viewModel.temperatureDisplay,
                tripDays: viewModel.nightsCount,
                tripType: "City",
                existingItems: viewModel.categories.flatMap { $0.items }.map { $0.title },
                onAddItem: { suggestion in
                    let req = CreateTripItemRequest(
                        section: suggestion.sectionTitle,
                        title: suggestion.title,
                        quantity: 1,
                        tag: suggestion.importance.rawValue
                    )
                    viewModel.handleAddItem(request: req)
                },
                onRemoveItem: { suggestion in
                    viewModel.handleRemoveItem(title: suggestion.title)
                },
                onClose: {
                    viewModel.closeDrawer(isShowingAIDrawerBinding: $isShowingAIDrawer)
                }
            )
        }
    }

    private var addItemDrawerSection: some View {
        SlidingDrawerContainer(
            isShowing: viewModel.showingAddItemDrawer,
            height: viewModel.addItemDrawerHeight,
            dragOffset: $viewModel.addItemDragOffset,
            onDismiss: {
                viewModel.closeDrawer(isShowingAIDrawerBinding: $isShowingAIDrawer)
            },
            onDragReset: {
                viewModel.resetDrawerOffset()
            }
        ) {
            AddItemDrawer(
                initialSection: viewModel.selectedInitialSection.rawValue,
                onAddItem: { request in
                    return viewModel.handleAddItem(request: request)
                },
                onClose: {
                    viewModel.closeDrawer(isShowingAIDrawerBinding: $isShowingAIDrawer)
                }
            )
        }
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                guard !viewModel.isAnyDrawerOpen else { return }
                if value.startLocation.x < 50 && value.translation.width > 60 && abs(value.translation.height) < 80 {
                    viewModel.handleBackNavigation(dismiss: { dismiss() })
                }
            }
    }
}

struct TripDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TripDetailsView()
        }
    }
}
