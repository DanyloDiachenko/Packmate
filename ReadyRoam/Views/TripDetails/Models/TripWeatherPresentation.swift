import Foundation

public struct TripWeatherPresentation: Equatable {
    public let temperatureDisplay: String
    public let seasonDisplay: String
    public let iconDisplay: String
    public let hasWeatherInfo: Bool

    public init(weather: String?, season: String?) {
        let w = weather?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let s = season?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        self.temperatureDisplay = w
        self.seasonDisplay = s
        self.hasWeatherInfo = !w.isEmpty || !s.isEmpty

        let combined = "\(w) \(s)".lowercased()

        if combined.contains("snow") || combined.contains("winter") {
            self.iconDisplay = "❄️"
        } else if combined.contains("rain") || combined.contains("shower") {
            self.iconDisplay = "🌧️"
        } else if combined.contains("cloud") {
            self.iconDisplay = "⛅️"
        } else if combined.contains("sun") || combined.contains("clear") || combined.contains("summer") {
            self.iconDisplay = "☀️"
        } else if combined.contains("autumn") || combined.contains("fall") {
            self.iconDisplay = "🍂"
        } else if combined.contains("spring") {
            self.iconDisplay = "🌸"
        } else {
            self.iconDisplay = "🌤️"
        }
    }
}
