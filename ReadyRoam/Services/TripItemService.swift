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

    static let defaultItemsForNewTrip: [CreateTripItemRequest] = [
        CreateTripItemRequest(section: "Essentials & Documents", title: "Passport / ID", quantity: 1, tag: "Essential"),
        CreateTripItemRequest(section: "Essentials & Documents", title: "Boarding Pass & Tickets", quantity: 1, tag: "Essential"),
        CreateTripItemRequest(section: "Essentials & Documents", title: "Credit Cards & Cash", quantity: 1, tag: "Essential"),
        CreateTripItemRequest(section: "Clothes & Footwear", title: "T-Shirts / Tops", quantity: 4, tag: "Important"),
        CreateTripItemRequest(section: "Clothes & Footwear", title: "Pants / Jeans", quantity: 2, tag: "Important"),
        CreateTripItemRequest(section: "Clothes & Footwear", title: "Underwear & Socks", quantity: 5, tag: "Essential"),
        CreateTripItemRequest(section: "Clothes & Footwear", title: "Comfortable Walking Shoes", quantity: 1, tag: "Important"),
        CreateTripItemRequest(section: "Electronics & Tech", title: "Smartphone", quantity: 1, tag: "Important"),
        CreateTripItemRequest(section: "Electronics & Tech", title: "Phone Charger", quantity: 1, tag: "Important"),
        CreateTripItemRequest(section: "Electronics & Tech", title: "Power Bank", quantity: 1, tag: "Important"),
        CreateTripItemRequest(section: "Electronics & Tech", title: "Travel Adapter", quantity: 1, tag: "Important"),
        CreateTripItemRequest(section: "Toiletries & Health", title: "Toothbrush & Toothpaste", quantity: 1, tag: "Essential"),
        CreateTripItemRequest(section: "Toiletries & Health", title: "Personal Medications & First Aid", quantity: 1, tag: "Safety"),
        CreateTripItemRequest(section: "Toiletries & Health", title: "Shampoo & Body Wash", quantity: 1, tag: "Optional"),
        CreateTripItemRequest(section: "Misc & Gear", title: "Reusable Water Bottle", quantity: 1, tag: "Optional"),
        CreateTripItemRequest(section: "Misc & Gear", title: "Sunglasses", quantity: 1, tag: "Optional"),
        CreateTripItemRequest(section: "Misc & Gear", title: "Daypack / Backpack", quantity: 1, tag: "Important")
    ]

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
