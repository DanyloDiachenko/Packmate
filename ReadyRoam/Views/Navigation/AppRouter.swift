import SwiftUI

enum Route: Hashable {
    case tripDetails(Trip)
    case archivedTripDetails(Trip)
}

enum Sheet: Identifiable {
    case editProfile
    case addItem(tripId: UUID)

    var id: String {
        switch self {
        case .editProfile:
            return "editProfile"
        case .addItem(let tripId):
            return "addItem-\(tripId.uuidString)"
        }
    }
}

extension Notification.Name {
    static let didCreateNewTrip = Notification.Name("didCreateNewTrip")
    static let didDeleteTrip = Notification.Name("didDeleteTrip")
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .myTrips
    @Published var myTripsPath: [Route] = []
    @Published var archivePath: [Route] = []
    @Published var presentedSheet: Sheet?
    @Published var isShowingNewTripDrawer: Bool = false
    @Published var newTripDragOffset: CGFloat = 0

    func open(_ trip: Trip, isArchived: Bool = false) {
        if isArchived {
            archivePath.append(.archivedTripDetails(trip))
        } else {
            myTripsPath.append(.tripDetails(trip))
        }
    }

    func pop() {
        switch selectedTab {
        case .myTrips:
            if !myTripsPath.isEmpty {
                myTripsPath.removeLast()
            }
        case .archivedTrips:
            if !archivePath.isEmpty {
                archivePath.removeLast()
            }
        default:
            break
        }
    }

    func popToRoot() {
        switch selectedTab {
        case .myTrips:
            myTripsPath.removeAll()
        case .archivedTrips:
            archivePath.removeAll()
        default:
            break
        }
    }

    func present(_ sheet: Sheet) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func presentNewTripDrawer() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            isShowingNewTripDrawer = true
            newTripDragOffset = 0
        }
    }

    func dismissNewTripDrawer() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isShowingNewTripDrawer = false
            newTripDragOffset = 0
        }
    }
}
