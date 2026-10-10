import Foundation

@MainActor
final class TripService: TripServiceProtocol, ObservableObject {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func fetchTrips(limit: Int = 4, offset: Int = 0, isArchived: Bool? = nil) async throws -> PaginatedTripsResponseDto {
        var queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        if let isArchived = isArchived {
            queryItems.append(URLQueryItem(name: "isArchived", value: "\(isArchived)"))
        }

        let endpoint = Endpoint(
            path: "trips",
            method: .get,
            queryItems: queryItems,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func createTrip(request dto: CreateTripRequestDto) async throws -> TripResponseDto {
        let bodyData = try JSONEncoder().encode(dto)
        let endpoint = Endpoint(
            path: "trips",
            method: .post,
            body: bodyData,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func archiveTrip(id: UUID) async throws -> TripResponseDto {
        let endpoint = Endpoint(
            path: "trips/\(id.uuidString.lowercased())/archive",
            method: .post,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func unarchiveTrip(id: UUID) async throws -> TripResponseDto {
        let endpoint = Endpoint(
            path: "trips/\(id.uuidString.lowercased())/unarchive",
            method: .post,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func updateTrip(id: UUID, request dto: UpdateTripRequestDto) async throws -> TripResponseDto {
        let bodyData = try JSONEncoder().encode(dto)
        let endpoint = Endpoint(
            path: "trips/\(id.uuidString.lowercased())",
            method: .put,
            body: bodyData,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func deleteTrip(id: UUID) async throws {
        let endpoint = Endpoint(
            path: "trips/\(id.uuidString.lowercased())",
            method: .delete,
            requiresAuth: true
        )
        try await networkClient.requestVoid(endpoint)
    }
}
