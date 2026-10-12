import Foundation

public struct PresetItemDto: Codable, Identifiable, Hashable {
    public var id: UUID?
    public var section: String
    public var title: String
    public var quantity: Int
    public var tag: String?

    public init(id: UUID? = nil, section: String, title: String, quantity: Int = 1, tag: String? = nil) {
        self.id = id
        self.section = section
        self.title = title
        self.quantity = quantity
        self.tag = tag
    }
}

public struct CreatePresetRequest: Codable {
    public let name: String
    public let description: String?
    public let categories: [String: [PresetItemDto]]?

    public init(name: String, description: String?, categories: [String: [PresetItemDto]]?) {
        self.name = name
        self.description = description
        self.categories = categories
    }
}

public struct UpdatePresetRequest: Codable {
    public let name: String
    public let description: String?
    public let categories: [String: [PresetItemDto]]?

    public init(name: String, description: String?, categories: [String: [PresetItemDto]]?) {
        self.name = name
        self.description = description
        self.categories = categories
    }
}

public struct PresetSummaryDto: Codable, Identifiable, Hashable {
    public let id: UUID
    public let userId: UUID
    public let name: String
    public let description: String?
    public let totalItemsCount: Int
    public let createdAt: String
    public let updatedAt: String?

    public init(id: UUID, userId: UUID, name: String, description: String?, totalItemsCount: Int, createdAt: String, updatedAt: String?) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.totalItemsCount = totalItemsCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct PresetDto: Codable, Identifiable, Hashable {
    public let id: UUID
    public let userId: UUID
    public let name: String
    public let description: String?
    public let categories: [String: [PresetItemDto]]
    public let createdAt: String
    public let updatedAt: String?

    public init(id: UUID, userId: UUID, name: String, description: String?, categories: [String: [PresetItemDto]], createdAt: String, updatedAt: String?) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.categories = categories
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var allItems: [PresetItemDto] {
        categories.values.flatMap { $0 }
    }
}

extension PresetItemDto {
    public static let defaultItems: [PresetItemDto] = [
        PresetItemDto(section: "Essentials & Documents", title: "Passport / ID", quantity: 1, tag: "Essential"),
        PresetItemDto(section: "Essentials & Documents", title: "Boarding Pass & Tickets", quantity: 1, tag: "Essential"),
        PresetItemDto(section: "Essentials & Documents", title: "Credit Cards & Cash", quantity: 1, tag: "Essential"),
        PresetItemDto(section: "Clothes & Footwear", title: "T-Shirts / Tops", quantity: 4, tag: "Important"),
        PresetItemDto(section: "Clothes & Footwear", title: "Pants / Jeans", quantity: 2, tag: "Important"),
        PresetItemDto(section: "Clothes & Footwear", title: "Underwear & Socks", quantity: 5, tag: "Essential"),
        PresetItemDto(section: "Clothes & Footwear", title: "Comfortable Walking Shoes", quantity: 1, tag: "Important"),
        PresetItemDto(section: "Electronics & Tech", title: "Smartphone", quantity: 1, tag: "Essential"),
        PresetItemDto(section: "Electronics & Tech", title: "Phone Charger", quantity: 1, tag: "Important"),
        PresetItemDto(section: "Electronics & Tech", title: "Power Bank", quantity: 1, tag: "Important"),
        PresetItemDto(section: "Electronics & Tech", title: "Travel Adapter", quantity: 1, tag: "Important"),
        PresetItemDto(section: "Toiletries & Health", title: "Toothbrush & Toothpaste", quantity: 1, tag: "Essential"),
        PresetItemDto(section: "Toiletries & Health", title: "Personal Medications & First Aid", quantity: 1, tag: "Safety"),
        PresetItemDto(section: "Toiletries & Health", title: "Shampoo & Body Wash", quantity: 1, tag: "Optional"),
        PresetItemDto(section: "Misc & Gear", title: "Reusable Water Bottle", quantity: 1, tag: "Optional"),
        PresetItemDto(section: "Misc & Gear", title: "Sunglasses", quantity: 1, tag: "Optional"),
        PresetItemDto(section: "Misc & Gear", title: "Daypack / Backpack", quantity: 1, tag: "Important")
    ]
}
