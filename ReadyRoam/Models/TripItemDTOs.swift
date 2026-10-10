import Foundation

struct CreateTripItemRequest: Codable {
    var section: String
    var title: String
    var quantity: Int = 1
    var tag: String? = nil

    enum CodingKeys: String, CodingKey {
        case section
        case title
        case quantity
        case tag
    }
}

struct BulkCreateTripItemsRequest: Codable {
    var items: [CreateTripItemRequest]
}

struct UpdateTripItemRequest: Codable {
    var section: String? = nil
    var title: String? = nil
    var quantity: Int? = nil
    var isTaken: Bool? = nil
    var tag: String? = nil
}

struct TripItemResponse: Codable, Identifiable, Equatable {
    let id: UUID
    let tripId: UUID
    var section: String
    var title: String
    var quantity: Int
    var isTaken: Bool
    var tag: String?

    enum CodingKeys: String, CodingKey {
        case id
        case tripId
        case section
        case title
        case quantity
        case isTaken
        case tag
    }
}

struct TripSectionGroupResponse: Codable, Identifiable {
    var id: String { section }
    let section: String
    var items: [TripItemResponse]
}

struct ItemErrorResponse: Codable {
    let message: String?
}
