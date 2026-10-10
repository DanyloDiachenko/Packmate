import Foundation

@MainActor
final class DestinationService: DestinationServiceProtocol, ObservableObject {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func searchDestinations(query: String) async throws -> [DestinationDto] {
        return try await searchDestinationsInternal(query: query, limit: 20)
    }

    func getPopularDestinations() async throws -> [DestinationDto] {
        return try await searchDestinationsInternal(query: nil, limit: 20)
    }

    func getDestinationByCity(city: String) async throws -> DestinationDto {
        let results = try await searchDestinationsInternal(query: city, limit: 1)
        guard let match = results.first else {
            throw APIError.notFound("Destination '\(city)' not found.")
        }
        return match
    }

    private func searchDestinationsInternal(query: String?, limit: Int = 20) async throws -> [DestinationDto] {
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

        return try await networkClient.request(endpoint)
    }
}
