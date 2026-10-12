import Foundation
import SwiftUI

@MainActor
final class NewTripViewModel: ObservableObject {
    @Published var destinationText: String = ""
    @Published var selectedFlag: String = "🇪🇸"
    @Published var isSearchActive: Bool = false
    @Published var searchResults: [DestinationDto] = []
    @Published var isLoadingDestinations: Bool = false
    @Published var destinationSearchState: LoadState<[DestinationDto]> = .idle
    @Published var selectedDestination: DestinationDto? = nil
    @Published var isSelectingDestination: Bool = false
    @Published var isCreatingTrip: Bool = false

    @Published var dateSelection = TripDateSelection()
    @Published var selectedTripTypes: Set<NewTripType> = []
    @Published var fetchedTrips: [Trip] = []

    @Published var showingErrorAlert: Bool = false
    @Published var errorMessage: String? = nil
    @Published var availablePresets: [PresetSummaryDto] = []
    @Published var selectedPreset: PresetSummaryDto? = nil
    @Published var isLoadingPresets: Bool = false

    let existingTrips: [Trip]
    private let tripService: any TripServiceProtocol
    private let tripItemService: any TripItemServiceProtocol
    private let destinationService: any DestinationServiceProtocol
    private let presetService: any PresetServiceProtocol

    private var currentSearchQueryToken: String = ""

    private static let isoDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt
    }()

    private static let shortDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "MMM d"
        return fmt
    }()

    init(
        existingTrips: [Trip] = [],
        tripService: any TripServiceProtocol,
        tripItemService: any TripItemServiceProtocol,
        destinationService: any DestinationServiceProtocol,
        presetService: (any PresetServiceProtocol)? = nil
    ) {
        self.existingTrips = existingTrips
        self.tripService = tripService
        self.tripItemService = tripItemService
        self.destinationService = destinationService
        self.presetService = presetService ?? AppContainer.shared.presetService
    }

    var allTrips: [Trip] {
        if existingTrips.isEmpty {
            return fetchedTrips
        } else {
            var combined = existingTrips
            for t in fetchedTrips where !combined.contains(where: { $0.id == t.id }) {
                combined.append(t)
            }
            return combined
        }
    }

    var blockedDates: Set<Date> {
        let cal = Calendar.current
        var set = Set<Date>()
        for trip in allTrips {
            guard !trip.isArchived, let d = trip.departDate, let r = trip.returnDate else { continue }
            var curr = cal.startOfDay(for: d)
            let end = cal.startOfDay(for: r)
            while curr <= end {
                set.insert(curr)
                guard let next = cal.date(byAdding: .day, value: 1, to: curr) else { break }
                curr = next
            }
        }
        return set
    }

    var isFormValid: Bool {
        guard selectedDestination != nil else { return false }
        guard let dep = dateSelection.departDate, let ret = dateSelection.returnDate else { return false }
        return ret >= dep && isDateRangeAvailable(from: dep, to: ret)
    }

    func isDateRangeAvailable(from departure: Date, to returnDate: Date) -> Bool {
        let cal = Calendar.current
        let start = cal.startOfDay(for: departure)
        let end = cal.startOfDay(for: returnDate)
        guard end >= start else { return false }

        let blocked = blockedDates
        var curr = start
        while curr <= end {
            if blocked.contains(curr) {
                return false
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: curr) else { return false }
            curr = next
        }
        return true
    }

    func loadInitialData() async {
        await fetchDestinations(query: destinationText)
        await loadPresets()

        if existingTrips.isEmpty {
            do {
                let response = try await tripService.fetchTrips(limit: 50, offset: 0, isArchived: false)
                guard !Task.isCancelled else { return }
                self.fetchedTrips = response.trips.map { Trip(from: $0) }
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = error.localizedDescription
                self.showingErrorAlert = true
            }
        }

        setupInitialDates()
    }

    func loadPresets() async {
        isLoadingPresets = true
        defer { isLoadingPresets = false }
        do {
            let presets = try await presetService.fetchPresets()
            guard !Task.isCancelled else { return }
            self.availablePresets = presets
        } catch {
            guard !Task.isCancelled else { return }
            self.availablePresets = []
        }
    }

    func removeTrip(id: UUID) {
        fetchedTrips.removeAll { $0.id == id }
        validateAndAdjustSelectedDates()
    }

    func addTrip(_ trip: Trip) {
        if !fetchedTrips.contains(where: { $0.id == trip.id }) {
            fetchedTrips.append(trip)
        }
        validateAndAdjustSelectedDates()
    }

    func refreshTrips() async {
        do {
            let response = try await tripService.fetchTrips(limit: 50, offset: 0, isArchived: false)
            guard !Task.isCancelled else { return }
            self.fetchedTrips = response.trips.map { Trip(from: $0) }
            validateAndAdjustSelectedDates()
        } catch {
            guard !Task.isCancelled else { return }
        }
    }

    func fetchDestinations(query: String) async {
        let queryToken = query
        currentSearchQueryToken = queryToken
        isLoadingDestinations = true
        destinationSearchState = .loading
        defer {
            if currentSearchQueryToken == queryToken {
                isLoadingDestinations = false
            }
        }

        do {
            let results = try await destinationService.searchDestinations(query: queryToken)
            guard !Task.isCancelled, currentSearchQueryToken == queryToken else { return }
            self.searchResults = results
            if results.isEmpty {
                self.destinationSearchState = .empty
            } else {
                self.destinationSearchState = .loaded(results)
            }
        } catch {
            guard !Task.isCancelled, currentSearchQueryToken == queryToken else { return }
            self.searchResults = []
            self.destinationSearchState = .failed(message: error.localizedDescription)
        }
    }

    func selectDestination(_ item: DestinationDto) {
        isSelectingDestination = true
        selectedDestination = item
        destinationText = "\(item.city), \(item.country)"
        selectedFlag = item.countryFlag
        isSearchActive = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.isSelectingDestination = false
        }
    }

    func validateAndAdjustSelectedDates() {
        let blocked = blockedDates
        var needsReset = false
        if let dep = dateSelection.departDate {
            if blocked.contains(dep) {
                needsReset = true
            }
        }
        if let ret = dateSelection.returnDate {
            if blocked.contains(ret) {
                needsReset = true
            }
        }
        if let dep = dateSelection.departDate, let ret = dateSelection.returnDate {
            if !isDateRangeAvailable(from: dep, to: ret) {
                needsReset = true
            }
        }
        if needsReset {
            dateSelection.departDate = nil
            dateSelection.returnDate = nil
            setupInitialDates(forceReset: true)
        }
    }

    func setupInitialDates(forceReset: Bool = false) {
        if !forceReset && dateSelection.departDate != nil { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let blocked = blockedDates

        var foundDepart: Date? = nil
        var foundReturn: Date? = nil

        for offset in 1...60 {
            if let candidateDepart = cal.date(byAdding: .day, value: offset, to: today),
               !blocked.contains(candidateDepart) {
                var validRange = true
                for dayOffset in 0...5 {
                    if let day = cal.date(byAdding: .day, value: dayOffset, to: candidateDepart),
                       blocked.contains(day) {
                        validRange = false
                        break
                    }
                }
                if validRange {
                    foundDepart = candidateDepart
                    foundReturn = cal.date(byAdding: .day, value: 5, to: candidateDepart)
                    break
                }
            }
        }

        if let dep = foundDepart, let ret = foundReturn {
            dateSelection.departDate = dep
            dateSelection.returnDate = ret
        } else {
            let defaultDep = cal.date(byAdding: .day, value: 7, to: today) ?? today
            let defaultRet = cal.date(byAdding: .day, value: 12, to: defaultDep) ?? today
            dateSelection.departDate = defaultDep
            dateSelection.returnDate = defaultRet
        }

        if let dep = dateSelection.departDate {
            let depMonth = cal.date(from: cal.dateComponents([.year, .month], from: dep)) ?? dep
            if let idx = dateSelection.availableMonths.firstIndex(where: { cal.isDate($0, equalTo: depMonth, toGranularity: .month) }) {
                dateSelection.viewingMonthIndex = idx
            }
        }
    }

    func handleDateTap(date: Date) {
        let cal = Calendar.current
        let target = cal.startOfDay(for: date)
        if blockedDates.contains(target) {
            return
        }

        if dateSelection.departDate == nil || (dateSelection.departDate != nil && dateSelection.returnDate != nil) {
            dateSelection.departDate = target
            dateSelection.returnDate = nil
        } else if let dep = dateSelection.departDate {
            if target < dep {
                dateSelection.departDate = target
                dateSelection.returnDate = nil
            } else if cal.isDate(target, inSameDayAs: dep) {
                dateSelection.returnDate = nil
            } else {
                let rangeAvailable = isDateRangeAvailable(from: dep, to: target)
                if rangeAvailable {
                    dateSelection.returnDate = target
                } else {
                    dateSelection.departDate = target
                    dateSelection.returnDate = nil
                }
            }
        }
    }

    func handleCreateTrip(onSuccess: @escaping (Trip) -> Void) async {
        guard isFormValid && !isCreatingTrip, let selected = selectedDestination else { return }
        isCreatingTrip = true
        defer { isCreatingTrip = false }

        let cityName = selected.city
        let countryName = selected.country
        let cal = Calendar.current
        let dep = dateSelection.departDate ?? Date()
        let ret = dateSelection.returnDate ?? cal.date(byAdding: .day, value: 6, to: dep)!

        let flag = selected.countryFlag
        let selectedTags = selectedTripTypes.map { $0.tagKey }
        let banner = selected.bannerImage

        let isoFmt = Self.isoDateFormatter
        let departDateStr = isoFmt.string(from: dep)
        let returnDateStr = isoFmt.string(from: ret)

        let destDto = TripDestinationDto(
            country: countryName,
            countryFlag: flag,
            city: cityName,
            bannerImage: banner
        )
        let reqDto = CreateTripRequestDto(
            destination: destDto,
            departDate: departDateStr,
            returnDate: returnDateStr,
            tags: selectedTags
        )

        do {
            let createdDto = try await tripService.createTrip(request: reqDto, presetId: selectedPreset?.id)

            let tripToEmit = Trip(
                from: createdDto,
                packedItems: 0,
                totalItems: selectedPreset?.totalItemsCount ?? 0
            )

            await MainActor.run {
                self.addTrip(tripToEmit)
                resetState()
                onSuccess(tripToEmit)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }

    func resetState() {
        destinationText = ""
        selectedFlag = "🇪🇸"
        isSearchActive = false
        searchResults = []
        isLoadingDestinations = false
        destinationSearchState = .idle
        selectedDestination = nil
        selectedPreset = nil
        isSelectingDestination = false
        isCreatingTrip = false
        dateSelection = TripDateSelection()
        selectedTripTypes = []
        showingErrorAlert = false
        errorMessage = nil
        setupInitialDates()
    }
}
