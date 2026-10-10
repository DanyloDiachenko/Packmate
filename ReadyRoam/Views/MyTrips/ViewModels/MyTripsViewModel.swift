import Foundation
import SwiftUI

@MainActor
final class MyTripsViewModel: ObservableObject {
    @Published private(set) var trips: [Trip] = []
    @Published private(set) var totalItems: Int = 0

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var isRefreshing: Bool = false
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var refreshErrorMessage: String? = nil

    private let tripService: any TripServiceProtocol
    private let tripItemService: any TripItemServiceProtocol
    private let pageSize = 10

    var activeTrip: Trip? {
        trips.first
    }

    var upcomingTrips: [Trip] {
        Array(trips.dropFirst())
    }

    var hasMoreTrips: Bool {
        trips.count < totalItems
    }

    init(
        tripService: (any TripServiceProtocol)? = nil,
        tripItemService: (any TripItemServiceProtocol)? = nil
    ) {
        self.tripService = tripService ?? TripService.shared
        self.tripItemService = tripItemService ?? TripItemService.shared
    }

    func loadInitialTrips() async {
        guard !isLoading else { return }

        let isInitialLoad = trips.isEmpty
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
            let response = try await tripService.fetchTrips(limit: pageSize, offset: 0, isArchived: false)
            guard !Task.isCancelled else { return }
            let loadedTrips = response.trips.map { Trip(from: $0) }
            self.trips = loadedTrips
            self.totalItems = response.totalItems

            if let active = loadedTrips.first {
                await refreshTripProgress(for: active.id)
            }
        } catch {
            guard !Task.isCancelled else { return }
            if isInitialLoad {
                self.errorMessage = error.localizedDescription
            } else {
                self.refreshErrorMessage = error.localizedDescription
            }
        }
    }

    func loadMoreTrips() async {
        guard !isLoading, !isLoadingMore, hasMoreTrips else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let offset = trips.count
            let response = try await tripService.fetchTrips(limit: 5, offset: offset, isArchived: false)
            guard !Task.isCancelled else { return }
            let newTrips = response.trips.map { Trip(from: $0) }
            self.totalItems = response.totalItems

            let existingIDs = Set(trips.map(\.id))
            let uniqueTrips = newTrips.filter { !existingIDs.contains($0.id) }
            self.trips.append(contentsOf: uniqueTrips)
        } catch {
            print("Failed to load more trips: \(error)")
        }
    }

    func refreshTripProgress(for tripID: UUID) async {
        do {
            let groups = try await tripItemService.fetchTripItems(tripId: tripID)
            guard !Task.isCancelled else { return }
            let allItems = groups.flatMap(\.items)
            let packedCount = allItems.filter(\.isTaken).count
            let totalCount = allItems.count

            if let index = trips.firstIndex(where: { $0.id == tripID }) {
                trips[index].packedItems = packedCount
                trips[index].totalItems = totalCount
            }
        } catch {
            print("Failed to refresh trip progress: \(error)")
        }
    }

    func handleCreatedTrip(_ trip: Trip) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            trips.insert(trip, at: 0)
            totalItems += 1
        }
    }

    func removeTrip(id: UUID) {
        guard trips.contains(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: 0.28)) {
            trips.removeAll { $0.id == id }
            totalItems = max(0, totalItems - 1)
        }
        if let newActive = trips.first {
            Task {
                await refreshTripProgress(for: newActive.id)
            }
        }
    }
}
