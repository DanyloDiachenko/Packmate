import Foundation
import SwiftUI

struct AIRecommendationRequest: Encodable {
    let city: String
    let country: String
    let tripDays: Int
    let tripType: String
    let weatherSummary: String?
    let currentSeason: String?
    let existingItems: [String]?
}

struct AIRecommendationItem: Decodable {
    let section: String
    let title: String
    let quantity: Int
    let tag: String?
    let reason: String?
}

struct AIRecommendationResponse: Decodable {
    let recommendations: [AIRecommendationItem]
    let summaryNotes: String?
}

@MainActor
final class AIService: AIServiceProtocol, ObservableObject {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func fetchPackingSuggestions(cityName: String, country: String, season: String, temperature: String, tripDays: Int, tripType: String, existingItems: [String]) async throws -> [AISuggestion] {
        let response = try await fetchRecommendations(
            city: cityName,
            country: country,
            tripDays: tripDays,
            tripType: tripType,
            weatherSummary: temperature,
            currentSeason: season,
            existingItems: existingItems
        )
        return response.recommendations.map { $0.toAISuggestion() }
    }

    func fetchRecommendations(
        city: String,
        country: String,
        tripDays: Int,
        tripType: String,
        weatherSummary: String?,
        currentSeason: String?,
        existingItems: [String]
    ) async throws -> AIRecommendationResponse {
        let bodyObj = AIRecommendationRequest(
            city: city,
            country: country,
            tripDays: tripDays,
            tripType: tripType,
            weatherSummary: weatherSummary,
            currentSeason: currentSeason,
            existingItems: existingItems.isEmpty ? nil : existingItems
        )
        let bodyData = try JSONEncoder().encode(bodyObj)

        let endpoint = Endpoint(
            path: "ai/recommendations",
            method: .post,
            body: bodyData,
            requiresAuth: true
        )

        return try await networkClient.request(endpoint)
    }
}

extension AIRecommendationItem {
    func toAISuggestion() -> AISuggestion {
        let info = ChecklistCategory.categoryInfo(for: section)
        let importance = ItemTag(rawValue: (tag ?? "optional").capitalized) ?? .optional
        let emoji = defaultEmoji(for: section)

        return AISuggestion(
            title: title,
            description: reason ?? "",
            iconEmoji: emoji,
            sectionTitle: info.title,
            sectionAccentColor: info.color,
            importance: importance
        )
    }

    private func defaultEmoji(for section: String) -> String {
        let lower = section.lowercased()
        if lower.contains("cloth") || lower.contains("wear") { return "👕" }
        if lower.contains("electr") || lower.contains("tech") { return "🔌" }
        if lower.contains("doc") || lower.contains("money") { return "📄" }
        if lower.contains("toil") || lower.contains("health") { return "🧴" }
        return "🎒"
    }
}
