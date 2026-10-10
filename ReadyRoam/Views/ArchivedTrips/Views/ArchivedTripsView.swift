import SwiftUI

struct ArchivedTripsView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: ArchivedTripsViewModel

    var onOpenSettings: (() -> Void)? = nil

    init(
        onOpenSettings: (() -> Void)? = nil,
        viewModel: ArchivedTripsViewModel? = nil
    ) {
        self.onOpenSettings = onOpenSettings
        let container = AppContainer.shared
        self._viewModel = StateObject(wrappedValue: viewModel ?? ArchivedTripsViewModel(tripService: container.tripService))
    }

    var body: some View {
        ZStack {
            AppTheme.darkBackground
                .ignoresSafeArea()

            archivedTripsContent
        }
        .preferredColorScheme(.dark)
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .archivedTripDetails(let trip), .tripDetails(let trip):
                TripDetailsView(
                    trip: trip,
                    isReadOnly: true,
                    onTripDeleted: { deletedId in
                        viewModel.removeTrip(id: deletedId)
                        router.pop()
                    }
                )
            }
        }
        .task {
            await viewModel.loadArchivedTrips()
        }
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
                    router.open(trip, isArchived: true)
                }
            }
        }
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
                if let onOpenSettings = onOpenSettings {
                    onOpenSettings()
                } else {
                    router.selectedTab = .settings
                }
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
        ErrorStateView(
            title: "Failed to load archived trips",
            message: message,
            onRetry: {
                Task {
                    await viewModel.loadArchivedTrips()
                }
            }
        )
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
}

struct ArchivedTripsView_Previews: PreviewProvider {
    static var previews: some View {
        ArchivedTripsView()
            .environmentObject(AppRouter())
    }
}
