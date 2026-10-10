import Foundation

@MainActor
final class DestinationService: DestinationServiceProtocol, ObservableObject {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func searchDestinations(query: String) async throws -> [DestinationDto] {
        return await searchDestinationsInternal(query: query, limit: 20)
    }

    func getPopularDestinations() async throws -> [DestinationDto] {
        return await searchDestinationsInternal(query: nil, limit: 20)
    }

    func getDestinationByCity(city: String) async throws -> DestinationDto {
        let results = await searchDestinationsInternal(query: city, limit: 1)
        if let match = results.first {
            return match
        }
        return DestinationDto(country: "Unknown", city: city, countryFlag: "✈️", bannerImage: nil)
    }

    func searchDestinationsInternal(query: String?, limit: Int = 20) async -> [DestinationDto] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        if let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: trimmed))
        }

        let endpoint = Endpoint(
            path: "destinations",
            method: .get,
            queryItems: queryItems,
            requiresAuth: false
        )

        do {
            return try await networkClient.request(endpoint)
        } catch {
            return []
        }
    }
}
