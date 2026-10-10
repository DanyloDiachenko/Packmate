import Foundation
import SwiftUI

extension TripDetailsViewModel {
    private static let isoDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt
    }()

    var weatherPresentation: TripWeatherPresentation {
        TripWeatherPresentation(
            weather: liveWeatherToday ?? weatherToday,
            season: liveCurrentSeason ?? currentSeason
        )
    }

    var effectiveWeatherToday: String? {
        liveWeatherToday ?? weatherToday
    }

    var effectiveCurrentSeason: String? {
        liveCurrentSeason ?? currentSeason
    }

    var hasWeatherInfo: Bool {
        weatherPresentation.hasWeatherInfo
    }

    var temperatureDisplay: String {
        weatherPresentation.temperatureDisplay
    }

    var weatherSeasonDisplay: String {
        weatherPresentation.seasonDisplay
    }

    var weatherIconDisplay: String {
        weatherPresentation.iconDisplay
    }

    func fetchLiveWeather() async {
        if !hasWeatherInfo {
            isLoadingWeather = true
        }
        defer {
            withAnimation(.easeInOut(duration: 0.25)) {
                isLoadingWeather = false
            }
        }

        let cal = Calendar.current
        let dep = departDate ?? Date()
        let ret = returnDate ?? (cal.date(byAdding: .day, value: max(1, nightsCount), to: dep) ?? dep)

        let isoFmt = Self.isoDateFormatter

        do {
            let dto = try await weatherService.fetchWeather(
                city: city,
                country: country,
                departDate: isoFmt.string(from: dep),
                returnDate: isoFmt.string(from: ret)
            )
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                self.liveWeatherToday = dto.weatherToday
                self.liveCurrentSeason = dto.currentSeason
            }
        } catch {
            print("Failed to fetch live weather: \(error)")
        }
    }
}
