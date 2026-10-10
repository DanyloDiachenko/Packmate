import Foundation
import SwiftUI

@MainActor
final class ArchivedTripsViewModel: ObservableObject {
    @Published var archivedTrips: [Trip] = []
    @Published var isLoading: Bool = true
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var refreshErrorMessage: String? = nil
    @Published var selectedTripForDetails: Trip? = nil

    private let tripService: any TripServiceProtocol

    init(tripService: any TripServiceProtocol) {
        self.tripService = tripService
    }

    func loadArchivedTrips() async {
        let isInitialLoad = archivedTrips.isEmpty

        if isInitialLoad {
            isLoading = true
        } else {
            isRefreshing = true
        }

        errorMessage = nil
        refreshErrorMessage = nil

        defer {
            isLoading = false
            isRefreshing = false
        }

        do {
            let response = try await tripService.fetchTrips(limit: 50, offset: 0, isArchived: true)
            guard !Task.isCancelled else { return }
            let loaded = response.trips.map { Trip(from: $0) }
            self.archivedTrips = loaded
        } catch {
            guard !Task.isCancelled else { return }
            if isInitialLoad {
                self.errorMessage = error.localizedDescription
            } else {
                self.refreshErrorMessage = error.localizedDescription
            }
        }
    }

    func removeTrip(id: UUID) {
        archivedTrips.removeAll { $0.id == id }
    }
}
