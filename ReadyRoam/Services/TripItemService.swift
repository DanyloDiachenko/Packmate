import Foundation

@MainActor
final class TripItemService: TripItemServiceProtocol, ObservableObject {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func fetchTripItems(tripId: UUID) async throws -> [TripSectionGroupResponse] {
        let endpoint = Endpoint(
            path: "trip-items/\(tripId.uuidString.lowercased())",
            method: .get,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func createTripItem(tripId: UUID, request dto: CreateTripItemRequest) async throws -> TripItemResponse {
        let bodyData = try JSONEncoder().encode(dto)
        let endpoint = Endpoint(
            path: "trip-items/\(tripId.uuidString.lowercased())",
            method: .post,
            body: bodyData,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func bulkCreateTripItems(tripId: UUID, items: [CreateTripItemRequest]) async throws -> [TripItemResponse] {
        let bodyData = try JSONEncoder().encode(BulkCreateTripItemsRequest(items: items))
        let endpoint = Endpoint(
            path: "trip-items/\(tripId.uuidString.lowercased())/bulk",
            method: .post,
            body: bodyData,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func updateTripItem(id: UUID, request dto: UpdateTripItemRequest) async throws -> TripItemResponse {
        let bodyData = try JSONEncoder().encode(dto)
        let endpoint = Endpoint(
            path: "trip-items/\(id.uuidString.lowercased())",
            method: .put,
            body: bodyData,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func deleteTripItem(id: UUID) async throws {
        let endpoint = Endpoint(
            path: "trip-items/\(id.uuidString.lowercased())",
            method: .delete,
            requiresAuth: true
        )
        try await networkClient.requestVoid(endpoint)
    }

    static let defaultItemsForNewTrip: [CreateTripItemRequest] = [
        CreateTripItemRequest(section: "Documents & Money", title: "Passport", quantity: 1, tag: "Important"),
        CreateTripItemRequest(section: "Documents & Money", title: "Credit Cards / Cash", quantity: 1, tag: "Important"),
        CreateTripItemRequest(section: "Documents & Money", title: "Travel Insurance & Tickets", quantity: 1, tag: "Important"),
        CreateTripItemRequest(section: "Clothes & Footwear", title: "Comfortable Walking Shoes", quantity: 1, tag: "Important"),
        CreateTripItemRequest(section: "Clothes & Footwear", title: "T-Shirts & Tops", quantity: 3, tag: "Important"),
        CreateTripItemRequest(section: "Clothes & Footwear", title: "Underwear & Socks", quantity: 4, tag: "Important"),
        CreateTripItemRequest(section: "Clothes & Footwear", title: "Jacket / Outerwear", quantity: 1, tag: "Important"),
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

    func seedDefaultItems(for tripId: UUID) async {
        let items = Self.defaultItemsForNewTrip
        do {
            _ = try await bulkCreateTripItems(tripId: tripId, items: items)
        } catch {
            for item in items {
                _ = try? await createTripItem(tripId: tripId, request: item)
            }
        }
    }
}
