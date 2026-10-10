import SwiftUI

struct MyTripsView: View {
    @StateObject private var viewModel: MyTripsViewModel

    @Binding var isViewingTripDetails: Bool
    @Binding var isShowingAIDrawer: Bool
    @Binding var upcomingTrips: [Trip]
    @Binding var createdTrip: Trip?

    var onOpenSettings: (() -> Void)? = nil
    var onPlanTrip: (() -> Void)? = nil

    init(
        isViewingTripDetails: Binding<Bool> = .constant(false),
        isShowingAIDrawer: Binding<Bool> = .constant(false),
        upcomingTrips: Binding<[Trip]> = .constant([]),
        createdTrip: Binding<Trip?> = .constant(nil),
        onOpenSettings: (() -> Void)? = nil,
        onPlanTrip: (() -> Void)? = nil,
        viewModel: MyTripsViewModel? = nil
    ) {
        self._isViewingTripDetails = isViewingTripDetails
        self._isShowingAIDrawer = isShowingAIDrawer
        self._upcomingTrips = upcomingTrips
        self._createdTrip = createdTrip
        self.onOpenSettings = onOpenSettings
        self.onPlanTrip = onPlanTrip
        self._viewModel = StateObject(wrappedValue: viewModel ?? MyTripsViewModel())
    }

    var body: some View {
        ZStack {
            AppTheme.darkBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    headerBar
                        .padding(.top, 8)

                    if let refreshError = viewModel.refreshErrorMessage {
                        refreshErrorBanner(refreshError)
                    }

                    if viewModel.isLoading && viewModel.trips.isEmpty {
                        skeletonView
                    } else if let error = viewModel.errorMessage, viewModel.trips.isEmpty {
                        errorView(error)
                    } else if viewModel.trips.isEmpty {
                        EmptyTripsView(onPlanTrip: onPlanTrip)
                    } else {
                        populatedTripsView
                    }
                }
                .padding(.horizontal, 20)
            }
            .refreshable {
                await viewModel.loadInitialTrips()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadInitialTrips()
        }
        .onChange(of: createdTrip) { newTrip in
            if let newTrip = newTrip {
                viewModel.handleCreatedTrip(newTrip)
                createdTrip = nil
            }
        }
        .onReceive(viewModel.$trips) { trips in
            upcomingTrips = Array(trips.dropFirst())
        }
    }

    @ViewBuilder
    private var populatedTripsView: some View {
        if let active = viewModel.activeTrip {
            NavigationLink(destination: TripDetailsView(
                isViewingTripDetails: $isViewingTripDetails,
                isShowingAIDrawer: $isShowingAIDrawer,
                trip: active,
                onTripDeleted: { deletedId in
                    viewModel.removeTrip(id: deletedId)
                }
            )) {
                ActiveTripCard(trip: active)
            }
            .buttonStyle(.plain)
        }

        if !viewModel.upcomingTrips.isEmpty {
            Text("Upcoming")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.top, 8)

            VStack(spacing: 12) {
                ForEach(viewModel.upcomingTrips) { trip in
                    NavigationLink(destination: TripDetailsView(
                        isViewingTripDetails: $isViewingTripDetails,
                        isShowingAIDrawer: $isShowingAIDrawer,
                        trip: trip,
                        onTripDeleted: { deletedId in
                            viewModel.removeTrip(id: deletedId)
                        }
                    )) {
                        UpcomingTripRow(trip: trip)
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        if viewModel.hasMoreTrips {
            Button(action: {
                Task {
                    await viewModel.loadMoreTrips()
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.skyCyan))
                            .scaleEffect(0.85)
                    }
                    Text("Load More Trips")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.skyCyan)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .disabled(viewModel.isLoadingMore)
            .padding(.top, 4)
            .padding(.bottom, 75)
        } else {
            Spacer()
                .frame(height: 75)
        }
    }

    private var skeletonView: some View {
        VStack(alignment: .leading, spacing: 22) {
            ActiveTripSkeletonCard()

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.1))
                .frame(width: 110, height: 22)
                .padding(.top, 8)
                .skeletonPulse()

            VStack(spacing: 12) {
                UpcomingTripSkeletonRow()
                UpcomingTripSkeletonRow()
            }
            .padding(.bottom, 75)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "EF4444"))

            Text("Failed to load trips")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private func refreshErrorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 14, weight: .semibold))
            Text("Unable to update: \(message)")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(Color(hex: "F59E0B"))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "F59E0B").opacity(0.12))
        .cornerRadius(8)
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("READYROAM")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundColor(AppTheme.skyCyan)

                Text("My Trips")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()

            Button(action: {
                onOpenSettings?()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "818CF8"), Color(hex: "A855F7")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .shadow(color: Color(hex: "A855F7").opacity(0.4), radius: 8, x: 0, y: 3)

                    Text(AuthService.shared.currentUser?.initial ?? "A")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct MyTripsView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
