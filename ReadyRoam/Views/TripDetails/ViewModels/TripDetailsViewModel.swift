import Foundation
import SwiftUI

enum ActiveDrawer: Equatable {
    case none
    case aiSuggestions
    case addItem
}

@MainActor
class TripDetailsViewModel: ObservableObject {
    let tripId: UUID?
    let city: String
    let country: String
    let flagEmoji: String
    let dateRange: String
    let nightsCount: Int
    let weatherToday: String?
    let currentSeason: String?
    let departDate: Date?
    let returnDate: Date?
    let isReadOnly: Bool
    var onTripDeleted: ((UUID) -> Void)?
    var onBack: (() -> Void)?

    let tripItemService: any TripItemServiceProtocol
    let tripService: any TripServiceProtocol
    let weatherService: any WeatherServiceProtocol

    @Published var liveWeatherToday: String? = nil
    @Published var liveCurrentSeason: String? = nil
    @Published var isLoadingWeather: Bool = true

    @Published var categories: [ChecklistCategory] = ChecklistCategory.defaultEmptyCategories()
    @Published var expandedCategoryIds: Set<UUID> = []
    @Published var activeDrawer: ActiveDrawer = .none
    @Published var showingDeleteDialog: Bool = false
    @Published var isDeletingTrip: Bool = false
    @Published var selectedInitialSection: ChecklistSection = .clothesAndFootwear
    @Published var dragOffset: CGFloat = 0
    @Published var addItemDragOffset: CGFloat = 0
    @Published var swipedItemId: UUID? = nil
    @Published var isLoadingItems: Bool = false
    @Published var hasLoadedItems: Bool = false
    @Published var showingErrorAlert: Bool = false
    @Published var itemErrorMessage: String? = nil

    let drawerAnimation = Animation.spring(response: 0.38, dampingFraction: 0.82)

    var showingAIDrawer: Bool {
        activeDrawer == .aiSuggestions
    }

    var showingAddItemDrawer: Bool {
        activeDrawer == .addItem
    }

    var isAnyDrawerOpen: Bool {
        activeDrawer != .none
    }

    convenience init(
        trip: Trip,
        isReadOnly: Bool = false,
        tripItemService: any TripItemServiceProtocol,
        tripService: any TripServiceProtocol,
        weatherService: any WeatherServiceProtocol,
        onTripDeleted: ((UUID) -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self.init(
            tripId: trip.id,
            city: trip.destination,
            country: trip.country,
            flagEmoji: trip.flagEmoji,
            dateRange: trip.dateRange,
            nightsCount: trip.nightsCount,
            weatherToday: trip.weatherToday,
            currentSeason: trip.currentSeason,
            departDate: trip.departDate,
            returnDate: trip.returnDate,
            isReadOnly: isReadOnly || trip.isArchived,
            tripItemService: tripItemService,
            tripService: tripService,
            weatherService: weatherService,
            onTripDeleted: onTripDeleted,
            onBack: onBack
        )
    }

    init(
        tripId: UUID? = nil,
        city: String = "Barcelona",
        country: String = "Spain",
        flagEmoji: String = "🇪🇸",
        dateRange: String = "Oct 12 – Oct 18",
        nightsCount: Int = 6,
        weatherToday: String? = nil,
        currentSeason: String? = nil,
        departDate: Date? = nil,
        returnDate: Date? = nil,
        isReadOnly: Bool = false,
        tripItemService: any TripItemServiceProtocol,
        tripService: any TripServiceProtocol,
        weatherService: any WeatherServiceProtocol,
        onTripDeleted: ((UUID) -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self.tripId = tripId
        self.city = city
        self.country = country
        self.flagEmoji = flagEmoji
        self.dateRange = dateRange
        self.nightsCount = nightsCount
        self.weatherToday = weatherToday
        self.currentSeason = currentSeason
        self.departDate = departDate
        self.returnDate = returnDate
        self.isReadOnly = isReadOnly
        self.tripItemService = tripItemService
        self.tripService = tripService
        self.weatherService = weatherService
        self.onTripDeleted = onTripDeleted
        self.onBack = onBack

        let defaults = ChecklistCategory.defaultEmptyCategories()
        self.categories = defaults
        if let first = defaults.first {
            self.expandedCategoryIds = [first.id]
        }
    }

    var totalPacked: Int {
        categories.flatMap { $0.items }.filter { $0.isPacked }.count
    }

    var totalItems: Int {
        categories.flatMap { $0.items }.count
    }

    var overallProgress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(totalPacked) / Double(totalItems)
    }

    var overallPercentage: Int {
        Int(overallProgress * 100)
    }

    func loadInitialData() async {
        async let items: () = loadTripItems()
        async let weather: () = fetchLiveWeather()
        _ = await (items, weather)
    }
}
