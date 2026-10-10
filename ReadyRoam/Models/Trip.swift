import Foundation

struct Trip: Identifiable, Hashable {
    let id: UUID
    let destination: String
    let country: String
    let flagEmoji: String
    let dateRange: String
    let nightsCount: Int
    let daysUntil: Int
    let tags: [String]
    var bannerImage: String?
    var weatherToday: String?
    var currentSeason: String?
    var packedItems: Int
    var totalItems: Int
    var isActive: Bool
    var isArchived: Bool
    var departDate: Date?
    var returnDate: Date?

    var packingPercentage: Int {
        guard totalItems > 0 else { return 0 }
        return Int((Double(packedItems) / Double(totalItems)) * 100)
    }

    var progress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(packedItems) / Double(totalItems)
    }

    var daysUntilText: String {
        if daysUntil <= 0 {
            return "Trip now 🌍"
        } else if daysUntil == 1 {
            return "Tomorrow"
        } else {
            return "In \(daysUntil) days"
        }
    }

    init(
        id: UUID = UUID(),
        destination: String,
        country: String,
        flagEmoji: String,
        dateRange: String,
        nightsCount: Int,
        daysUntil: Int,
        tags: [String] = [],
        bannerImage: String? = nil,
        weatherToday: String? = nil,
        currentSeason: String? = nil,
        packedItems: Int = 0,
        totalItems: Int = 0,
        isActive: Bool = false,
        isArchived: Bool = false,
        departDate: Date? = nil,
        returnDate: Date? = nil
    ) {
        self.id = id
        self.destination = destination
        self.country = country
        self.flagEmoji = flagEmoji
        self.dateRange = dateRange
        self.nightsCount = nightsCount
        self.daysUntil = daysUntil
        self.tags = tags
        self.bannerImage = bannerImage
        self.weatherToday = weatherToday
        self.currentSeason = currentSeason
        self.packedItems = packedItems
        self.totalItems = totalItems
        self.isActive = isActive
        self.isArchived = isArchived
        self.departDate = departDate
        self.returnDate = returnDate
    }

    init(from dto: TripResponseDto, packedItems: Int = 0, totalItems: Int = 0, isActive: Bool = false) {
        self.id = dto.id
        self.destination = dto.destination.city
        self.country = dto.destination.country
        self.flagEmoji = dto.destination.countryFlag.isEmpty ? "✈️" : dto.destination.countryFlag
        self.tags = dto.tags
        self.bannerImage = dto.destination.bannerImage
        self.weatherToday = dto.destination.weatherToday
        self.currentSeason = dto.destination.currentSeason
        self.packedItems = packedItems
        self.totalItems = totalItems
        self.isActive = isActive
        self.isArchived = dto.isArchived

        let dDate = Self.parseDate(dto.departDate)
        let rDate = Self.parseDate(dto.returnDate)
        self.departDate = dDate
        self.returnDate = rDate

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        if let d = dDate, let r = rDate {
            let nights = cal.dateComponents([.day], from: d, to: r).day ?? 1
            self.nightsCount = max(1, nights)

            let days = cal.dateComponents([.day], from: today, to: d).day ?? 0
            self.daysUntil = max(0, days)

            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "en_US_POSIX")
            displayFormatter.dateFormat = "MMM d"
            self.dateRange = "\(displayFormatter.string(from: d)) – \(displayFormatter.string(from: r))"
        } else {
            self.nightsCount = 7
            self.daysUntil = 0
            self.dateRange = "\(dto.departDate) – \(dto.returnDate)"
        }
    }

    static func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateOnlyFormatter.date(from: trimmed) {
            return date
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: trimmed) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: trimmed) {
            return date
        }

        return nil
    }
}


