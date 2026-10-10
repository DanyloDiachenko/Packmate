import Foundation
import SwiftUI

@MainActor
final class AISuggestionsViewModel: ObservableObject {
    let cityName: String
    let country: String
    let season: String
    let temperature: String
    let tripDays: Int
    let tripType: String
    let existingItems: [String]

    var onAddItem: ((AISuggestion) -> Void)?
    var onRemoveItem: ((AISuggestion) -> Void)?

    @Published var suggestions: [AISuggestion] = []
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false

    private let aiService: any AIServiceProtocol

    init(
        cityName: String = "",
        country: String = "",
        season: String = "",
        temperature: String = "",
        tripDays: Int = 0,
        tripType: String = "",
        existingItems: [String] = [],
        aiService: any AIServiceProtocol,
        onAddItem: ((AISuggestion) -> Void)? = nil,
        onRemoveItem: ((AISuggestion) -> Void)? = nil
    ) {
        self.cityName = cityName
        self.country = country
        self.season = season
        self.temperature = temperature
        self.tripDays = tripDays
        self.tripType = tripType
        self.existingItems = existingItems
        self.aiService = aiService
        self.onAddItem = onAddItem
        self.onRemoveItem = onRemoveItem
    }

    var headerSubtitle: String {
        let parts = [cityName, season, temperature].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return "Based on " + parts.joined(separator: " · ")
    }

    func loadSuggestions(appending: Bool) async {
        isLoading = true
        hasError = false
        defer { isLoading = false }

        do {
            let combinedExisting = Array(Set(existingItems + suggestions.map { $0.title }))
            let response = try await aiService.fetchRecommendations(
                city: cityName,
                country: country,
                tripDays: tripDays,
                tripType: tripType,
                weatherSummary: temperature.isEmpty ? nil : temperature,
                currentSeason: season.isEmpty ? nil : season,
                existingItems: combinedExisting
            )
            let newSuggestions = response.recommendations.map { $0.toAISuggestion() }
            if appending {
                suggestions.append(contentsOf: newSuggestions)
            } else {
                suggestions = newSuggestions
            }
        } catch {
            if suggestions.isEmpty {
                hasError = true
            }
        }
    }

    func toggleSuggestion(_ suggestion: AISuggestion) {
        if let index = suggestions.firstIndex(where: { $0.id == suggestion.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                suggestions[index].isAdded.toggle()
                let updated = suggestions[index]
                if updated.isAdded {
                    onAddItem?(updated)
                } else {
                    onRemoveItem?(updated)
                }
            }
        }
    }
}
