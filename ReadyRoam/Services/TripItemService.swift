import Foundation

@MainActor
final class TripItemService: TripItemServiceProtocol, ObservableObject {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func fetchTripItems(tripId: UUID) async throws -> [TripSectionGroupResponse] {
        let endpoint = Endpoint(
            path: "trip-items/\(tripId.uuidString)",
            method: .get
        )
        return try await networkClient.request(endpoint)
    }

    func createTripItem(tripId: UUID, request: CreateTripItemRequest) async throws -> TripItemResponse {
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(request)

        let endpoint = Endpoint(
            path: "trip-items/\(tripId.uuidString)",
            method: .post,
            body: bodyData
        )
        return try await networkClient.request(endpoint)
    }

    func bulkCreateTripItems(tripId: UUID, items: [CreateTripItemRequest]) async throws -> [TripItemResponse] {
        let encoder = JSONEncoder()
        let bulkRequest = BulkCreateTripItemsRequest(items: items)
        let bodyData = try encoder.encode(bulkRequest)

        let endpoint = Endpoint(
            path: "trip-items/\(tripId.uuidString)/bulk",
            method: .post,
            body: bodyData
        )
        return try await networkClient.request(endpoint)
    }

    func updateTripItem(id: UUID, request: UpdateTripItemRequest) async throws -> TripItemResponse {
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(request)

        let endpoint = Endpoint(
            path: "trip-items/\(id.uuidString)",
            method: .patch,
            body: bodyData
        )
        return try await networkClient.request(endpoint)
    }

    func deleteTripItem(id: UUID) async throws {
        let endpoint = Endpoint(
            path: "trip-items/\(id.uuidString)",
            method: .delete
        )
        try await networkClient.requestVoid(endpoint)
    }

    static var defaultItemsForNewTrip: [CreateTripItemRequest] {
        PresetItemDto.defaultItems.map {
            CreateTripItemRequest(section: $0.section, title: $0.title, quantity: $0.quantity, tag: $0.tag)
        }
    }

    func seedDefaultItems(for tripId: UUID) async throws {
        let items = Self.defaultItemsForNewTrip
        do {
            _ = try await bulkCreateTripItems(tripId: tripId, items: items)
        } catch {
            for item in items {
                _ = try await createTripItem(tripId: tripId, request: item)
            }
        }
    }
}
