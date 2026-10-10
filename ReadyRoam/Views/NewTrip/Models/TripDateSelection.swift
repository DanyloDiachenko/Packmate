import Foundation

struct TripDateSelection: Equatable {
    var departDate: Date? = nil
    var returnDate: Date? = nil
    var viewingMonthIndex: Int = 0

    private static let monthYearFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "MMMM yyyy"
        return fmt
    }()

    private static let shortDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "MMM d"
        return fmt
    }()

    var availableMonths: [Date] {
        let cal = Calendar.current
        let startOfCurrentMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
        return (0..<12).compactMap { cal.date(byAdding: .month, value: $0, to: startOfCurrentMonth) }
    }

    var currentViewingMonth: Date {
        guard viewingMonthIndex >= 0 && viewingMonthIndex < availableMonths.count else {
            return Date()
        }
        return availableMonths[viewingMonthIndex]
    }

    var monthHeaderTitle: String {
        Self.monthYearFormatter.string(from: currentViewingMonth)
    }

    var departBoxText: String {
        guard let d = departDate else { return "Select" }
        return Self.shortDateFormatter.string(from: d)
    }

    var returnBoxText: String {
        guard let r = returnDate else { return "Select" }
        return Self.shortDateFormatter.string(from: r)
    }

    var dateRangeString: String {
        guard let dep = departDate, let ret = returnDate else { return "" }
        return "\(Self.shortDateFormatter.string(from: dep)) – \(Self.shortDateFormatter.string(from: ret))"
    }
}
