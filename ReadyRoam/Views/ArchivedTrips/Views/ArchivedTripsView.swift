import SwiftUI

struct ArchivedTripsView: View {
    @Binding var isViewingTripDetails: Bool
    var onOpenSettings: (() -> Void)? = nil

    @StateObject private var viewModel: ArchivedTripsViewModel

    private let navigationAnimation = Animation.spring(response: 0.35, dampingFraction: 0.8)

    init(
        isViewingTripDetails: Binding<Bool> = .constant(false),
        onOpenSettings: (() -> Void)? = nil,
        viewModel: ArchivedTripsViewModel? = nil
    ) {
        self._isViewingTripDetails = isViewingTripDetails
        self.onOpenSettings = onOpenSettings
        self._viewModel = StateObject(wrappedValue: viewModel ?? ArchivedTripsViewModel())
    }

    var body: some View {
        ZStack {
            AppTheme.darkBackground
                .ignoresSafeArea()

            if let trip = viewModel.selectedTripForDetails {
                tripDetailsView(for: trip)
            } else {
                archivedTripsContent
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadArchivedTrips()
        }
        .simultaneousGesture(backSwipeGesture)
    }

    private var archivedTripsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerBar
                    .padding(.top, 8)

                if let refreshError = viewModel.refreshErrorMessage {
                    refreshErrorBanner(refreshError)
                }

                if viewModel.isLoading {
                    skeletonList
                } else if viewModel.archivedTrips.isEmpty, let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else if viewModel.archivedTrips.isEmpty {
                    emptyStateView
                } else {
                    tripList
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.loadArchivedTrips()
        }
    }

    private var tripList: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.archivedTrips) { trip in
                ArchivedTripCard(trip: trip) {
                    openTrip(trip)
                }
            }
        }
    }

    private func tripDetailsView(for trip: Trip) -> some View {
        TripDetailsView(
            isViewingTripDetails: $isViewingTripDetails,
            isShowingAIDrawer: .constant(false),
            trip: trip,
            isReadOnly: true,
            onTripDeleted: { deletedId in
                viewModel.removeTrip(id: deletedId)
                closeTripDetails()
            },
            onBack: {
                closeTripDetails()
            }
        )
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
        .zIndex(10)
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PAST JOURNEYS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundColor(AppTheme.skyCyan)

                Text("Archived Trips")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()

            Button(action: {
                onOpenSettings?()
            }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.darkSurface)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    private var skeletonList: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.darkSurface)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.skyCyan.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "archivebox.fill")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.skyCyan)
            }

            Text("No Archived Trips")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text("Completed trips or trips marked as archived will appear here for reference.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 60)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "EF4444"))

            Text("Failed to load archived trips")
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

    private func openTrip(_ trip: Trip) {
        withAnimation(navigationAnimation) {
            viewModel.selectedTripForDetails = trip
            isViewingTripDetails = true
        }
    }

    private func closeTripDetails() {
        withAnimation(navigationAnimation) {
            viewModel.selectedTripForDetails = nil
            isViewingTripDetails = false
        }
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                if value.startLocation.x < 50 && value.translation.width > 60 && abs(value.translation.height) < 80 {
                    if viewModel.selectedTripForDetails != nil {
                        closeTripDetails()
                    }
                }
            }
    }
}
