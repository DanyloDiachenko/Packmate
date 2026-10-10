import Foundation

@MainActor
final class MockTripService: TripServiceProtocol, ObservableObject {
    var mockTrips: [TripResponseDto] = [
        TripResponseDto(
            id: UUID(),
            userId: UUID(),
            destination: TripDestinationDto(country: "Japan", countryFlag: "🇯🇵", city: "Tokyo"),
            departDate: "2026-11-01",
            returnDate: "2026-11-10",
            tags: ["Adventure", "Culture"],
            isArchived: false
        ),
        TripResponseDto(
            id: UUID(),
            userId: UUID(),
            destination: TripDestinationDto(country: "France", countryFlag: "🇫🇷", city: "Paris"),
            departDate: "2026-12-15",
            returnDate: "2026-12-22",
            tags: ["Relaxation"],
            isArchived: false
        )
    ]

    func fetchTrips(limit: Int, offset: Int, isArchived: Bool?) async throws -> PaginatedTripsResponseDto {
        let filtered = mockTrips.filter { isArchived == nil || $0.isArchived == isArchived }
        return PaginatedTripsResponseDto(totalItems: filtered.count, trips: filtered)
    }

    func createTrip(request dto: CreateTripRequestDto) async throws -> TripResponseDto {
        let newTrip = TripResponseDto(
            id: UUID(),
            userId: UUID(),
            destination: dto.destination,
            departDate: dto.departDate,
            returnDate: dto.returnDate,
            tags: dto.tags,
            isArchived: false
        )
        mockTrips.insert(newTrip, at: 0)
        return newTrip
    }

    func archiveTrip(id: UUID) async throws -> TripResponseDto {
        guard let index = mockTrips.firstIndex(where: { $0.id == id }) else {
            throw APIError.httpError(statusCode: 404, message: "Trip not found")
        }
        let trip = mockTrips[index]
        let updated = TripResponseDto(
            id: trip.id,
            userId: trip.userId,
            destination: trip.destination,
            departDate: trip.departDate,
            returnDate: trip.returnDate,
            tags: trip.tags,
            isArchived: true,
            createdAt: trip.createdAt
        )
        mockTrips[index] = updated
        return updated
    }

    func unarchiveTrip(id: UUID) async throws -> TripResponseDto {
        guard let index = mockTrips.firstIndex(where: { $0.id == id }) else {
            throw APIError.httpError(statusCode: 404, message: "Trip not found")
        }
        let trip = mockTrips[index]
        let updated = TripResponseDto(
            id: trip.id,
            userId: trip.userId,
            destination: trip.destination,
            departDate: trip.departDate,
            returnDate: trip.returnDate,
            tags: trip.tags,
            isArchived: false,
            createdAt: trip.createdAt
        )
        mockTrips[index] = updated
        return updated
    }

    func updateTrip(id: UUID, request dto: UpdateTripRequestDto) async throws -> TripResponseDto {
        guard let index = mockTrips.firstIndex(where: { $0.id == id }) else {
            throw APIError.httpError(statusCode: 404, message: "Trip not found")
        }
        return mockTrips[index]
    }

    func deleteTrip(id: UUID) async throws {
        mockTrips.removeAll { $0.id == id }
    }
}
