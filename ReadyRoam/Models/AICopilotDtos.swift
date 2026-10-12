import Foundation

public struct AICopilotExistingItemDto: Codable, Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let section: String
    public let quantity: Int
    public let isPacked: Bool
    public let tag: String?

    public init(
        id: UUID,
        title: String,
        section: String,
        quantity: Int = 1,
        isPacked: Bool = false,
        tag: String? = nil
    ) {
        self.id = id
        self.title = title
        self.section = section
        self.quantity = quantity
        self.isPacked = isPacked
        self.tag = tag
    }

    enum CodingKeys: String, CodingKey {
        case id, title, section, quantity, isPacked, tag
        case idPascal = "Id"
        case titlePascal = "Title"
        case sectionPascal = "Section"
        case quantityPascal = "Quantity"
        case isPackedPascal = "IsPacked"
        case tagPascal = "Tag"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try? container.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = decodedId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .id), let uuid = UUID(uuidString: idStr) {
            self.id = uuid
        } else if let decodedId = try? container.decodeIfPresent(UUID.self, forKey: .idPascal) {
            self.id = decodedId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .idPascal), let uuid = UUID(uuidString: idStr) {
            self.id = uuid
        } else {
            self.id = UUID()
        }
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .titlePascal)
            ?? ""
        self.section = try container.decodeIfPresent(String.self, forKey: .section)
            ?? container.decodeIfPresent(String.self, forKey: .sectionPascal)
            ?? ""
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
            ?? container.decodeIfPresent(Int.self, forKey: .quantityPascal)
            ?? 1
        self.isPacked = try container.decodeIfPresent(Bool.self, forKey: .isPacked)
            ?? container.decodeIfPresent(Bool.self, forKey: .isPackedPascal)
            ?? false
        self.tag = try container.decodeIfPresent(String.self, forKey: .tag)
            ?? container.decodeIfPresent(String.self, forKey: .tagPascal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(section, forKey: .section)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(isPacked, forKey: .isPacked)
        try container.encodeIfPresent(tag, forKey: .tag)
    }
}

public struct AIPackingCopilotRequest: Codable {
    public let tripId: UUID
    public let prompt: String
    public let destination: String
    public let dateRange: String?
    public let nightsCount: Int
    public let existingItems: [AICopilotExistingItemDto]

    public init(
        tripId: UUID,
        prompt: String,
        destination: String,
        dateRange: String? = nil,
        nightsCount: Int = 0,
        existingItems: [AICopilotExistingItemDto] = []
    ) {
        self.tripId = tripId
        self.prompt = prompt
        self.destination = destination
        self.dateRange = dateRange
        self.nightsCount = nightsCount
        self.existingItems = existingItems
    }

    enum CodingKeys: String, CodingKey {
        case tripId, prompt, destination, dateRange, nightsCount, existingItems
        case tripIdPascal = "TripId"
        case promptPascal = "Prompt"
        case destinationPascal = "Destination"
        case dateRangePascal = "DateRange"
        case nightsCountPascal = "NightsCount"
        case existingItemsPascal = "ExistingItems"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try? container.decodeIfPresent(UUID.self, forKey: .tripId) {
            self.tripId = decodedId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .tripId), let uuid = UUID(uuidString: idStr) {
            self.tripId = uuid
        } else if let decodedId = try? container.decodeIfPresent(UUID.self, forKey: .tripIdPascal) {
            self.tripId = decodedId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .tripIdPascal), let uuid = UUID(uuidString: idStr) {
            self.tripId = uuid
        } else {
            self.tripId = UUID()
        }
        self.prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
            ?? container.decodeIfPresent(String.self, forKey: .promptPascal)
            ?? ""
        self.destination = try container.decodeIfPresent(String.self, forKey: .destination)
            ?? container.decodeIfPresent(String.self, forKey: .destinationPascal)
            ?? ""
        self.dateRange = try container.decodeIfPresent(String.self, forKey: .dateRange)
            ?? container.decodeIfPresent(String.self, forKey: .dateRangePascal)
        self.nightsCount = try container.decodeIfPresent(Int.self, forKey: .nightsCount)
            ?? container.decodeIfPresent(Int.self, forKey: .nightsCountPascal)
            ?? 0
        self.existingItems = try container.decodeIfPresent([AICopilotExistingItemDto].self, forKey: .existingItems)
            ?? container.decodeIfPresent([AICopilotExistingItemDto].self, forKey: .existingItemsPascal)
            ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tripId, forKey: .tripId)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(destination, forKey: .destination)
        try container.encodeIfPresent(dateRange, forKey: .dateRange)
        try container.encode(nightsCount, forKey: .nightsCount)
        try container.encode(existingItems, forKey: .existingItems)
    }
}

public struct AICopilotItemAdditionDto: Codable, Identifiable, Hashable {
    public let id: UUID
    public let section: String
    public let title: String
    public let quantity: Int
    public let tag: String?
    public let reason: String?

    public init(
        id: UUID = UUID(),
        section: String,
        title: String,
        quantity: Int = 1,
        tag: String? = nil,
        reason: String? = nil
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.quantity = quantity
        self.tag = tag
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case id, section, title, quantity, tag, reason
        case idPascal = "Id"
        case sectionPascal = "Section"
        case titlePascal = "Title"
        case quantityPascal = "Quantity"
        case tagPascal = "Tag"
        case reasonPascal = "Reason"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try? container.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = decodedId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .id), let uuid = UUID(uuidString: idStr) {
            self.id = uuid
        } else if let decodedId = try? container.decodeIfPresent(UUID.self, forKey: .idPascal) {
            self.id = decodedId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .idPascal), let uuid = UUID(uuidString: idStr) {
            self.id = uuid
        } else {
            self.id = UUID()
        }
        self.section = try container.decodeIfPresent(String.self, forKey: .section)
            ?? container.decodeIfPresent(String.self, forKey: .sectionPascal)
            ?? ""
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .titlePascal)
            ?? ""
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
            ?? container.decodeIfPresent(Int.self, forKey: .quantityPascal)
            ?? 1
        self.tag = try container.decodeIfPresent(String.self, forKey: .tag)
            ?? container.decodeIfPresent(String.self, forKey: .tagPascal)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
            ?? container.decodeIfPresent(String.self, forKey: .reasonPascal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(section, forKey: .section)
        try container.encode(title, forKey: .title)
        try container.encode(quantity, forKey: .quantity)
        try container.encodeIfPresent(tag, forKey: .tag)
        try container.encodeIfPresent(reason, forKey: .reason)
    }
}

public struct AICopilotItemRemovalDto: Codable, Identifiable, Hashable {
    public let id: UUID
    public let itemId: UUID?
    public let title: String
    public let section: String
    public let reason: String?

    public init(
        id: UUID = UUID(),
        itemId: UUID? = nil,
        title: String,
        section: String,
        reason: String? = nil
    ) {
        self.id = id
        self.itemId = itemId
        self.title = title
        self.section = section
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case id, itemId, title, section, reason
        case idPascal = "Id"
        case itemIdPascal = "ItemId"
        case titlePascal = "Title"
        case sectionPascal = "Section"
        case reasonPascal = "Reason"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try? container.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = decodedId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .id), let uuid = UUID(uuidString: idStr) {
            self.id = uuid
        } else if let decodedId = try? container.decodeIfPresent(UUID.self, forKey: .idPascal) {
            self.id = decodedId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .idPascal), let uuid = UUID(uuidString: idStr) {
            self.id = uuid
        } else {
            self.id = UUID()
        }
        if let decodedItemId = try? container.decodeIfPresent(UUID.self, forKey: .itemId) {
            self.itemId = decodedItemId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .itemId), let uuid = UUID(uuidString: idStr) {
            self.itemId = uuid
        } else if let decodedItemId = try? container.decodeIfPresent(UUID.self, forKey: .itemIdPascal) {
            self.itemId = decodedItemId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .itemIdPascal), let uuid = UUID(uuidString: idStr) {
            self.itemId = uuid
        } else {
            self.itemId = nil
        }
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .titlePascal)
            ?? ""
        self.section = try container.decodeIfPresent(String.self, forKey: .section)
            ?? container.decodeIfPresent(String.self, forKey: .sectionPascal)
            ?? ""
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
            ?? container.decodeIfPresent(String.self, forKey: .reasonPascal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(itemId, forKey: .itemId)
        try container.encode(title, forKey: .title)
        try container.encode(section, forKey: .section)
        try container.encodeIfPresent(reason, forKey: .reason)
    }
}

public struct AICopilotItemModificationDto: Codable, Identifiable, Hashable {
    public let id: UUID
    public let itemId: UUID?
    public let title: String
    public let section: String
    public let currentQuantity: Int?
    public let newQuantity: Int
    public let newTag: String?
    public let reason: String?

    public init(
        id: UUID = UUID(),
        itemId: UUID? = nil,
        title: String,
        section: String,
        currentQuantity: Int? = nil,
        newQuantity: Int = 1,
        newTag: String? = nil,
        reason: String? = nil
    ) {
        self.id = id
        self.itemId = itemId
        self.title = title
        self.section = section
        self.currentQuantity = currentQuantity
        self.newQuantity = newQuantity
        self.newTag = newTag
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case id, itemId, title, section, currentQuantity, newQuantity, newTag, reason
        case idPascal = "Id"
        case itemIdPascal = "ItemId"
        case titlePascal = "Title"
        case sectionPascal = "Section"
        case currentQuantityPascal = "CurrentQuantity"
        case newQuantityPascal = "NewQuantity"
        case newTagPascal = "NewTag"
        case reasonPascal = "Reason"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try? container.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = decodedId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .id), let uuid = UUID(uuidString: idStr) {
            self.id = uuid
        } else if let decodedId = try? container.decodeIfPresent(UUID.self, forKey: .idPascal) {
            self.id = decodedId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .idPascal), let uuid = UUID(uuidString: idStr) {
            self.id = uuid
        } else {
            self.id = UUID()
        }
        if let decodedItemId = try? container.decodeIfPresent(UUID.self, forKey: .itemId) {
            self.itemId = decodedItemId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .itemId), let uuid = UUID(uuidString: idStr) {
            self.itemId = uuid
        } else if let decodedItemId = try? container.decodeIfPresent(UUID.self, forKey: .itemIdPascal) {
            self.itemId = decodedItemId
        } else if let idStr = try? container.decodeIfPresent(String.self, forKey: .itemIdPascal), let uuid = UUID(uuidString: idStr) {
            self.itemId = uuid
        } else {
            self.itemId = nil
        }
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .titlePascal)
            ?? ""
        self.section = try container.decodeIfPresent(String.self, forKey: .section)
            ?? container.decodeIfPresent(String.self, forKey: .sectionPascal)
            ?? ""
        self.currentQuantity = try container.decodeIfPresent(Int.self, forKey: .currentQuantity)
            ?? container.decodeIfPresent(Int.self, forKey: .currentQuantityPascal)
        self.newQuantity = try container.decodeIfPresent(Int.self, forKey: .newQuantity)
            ?? container.decodeIfPresent(Int.self, forKey: .newQuantityPascal)
            ?? 1
        self.newTag = try container.decodeIfPresent(String.self, forKey: .newTag)
            ?? container.decodeIfPresent(String.self, forKey: .newTagPascal)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
            ?? container.decodeIfPresent(String.self, forKey: .reasonPascal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(itemId, forKey: .itemId)
        try container.encode(title, forKey: .title)
        try container.encode(section, forKey: .section)
        try container.encodeIfPresent(currentQuantity, forKey: .currentQuantity)
        try container.encode(newQuantity, forKey: .newQuantity)
        try container.encodeIfPresent(newTag, forKey: .newTag)
        try container.encodeIfPresent(reason, forKey: .reason)
    }
}

public struct AIPackingCopilotResponse: Codable {
    public let success: Bool
    public let explanation: String?
    public let additions: [AICopilotItemAdditionDto]?
    public let removals: [AICopilotItemRemovalDto]?
    public let modifications: [AICopilotItemModificationDto]?
    public let nextActions: [String]?
    public let errorMessage: String?

    public init(
        success: Bool,
        explanation: String? = nil,
        additions: [AICopilotItemAdditionDto]? = nil,
        removals: [AICopilotItemRemovalDto]? = nil,
        modifications: [AICopilotItemModificationDto]? = nil,
        nextActions: [String]? = nil,
        errorMessage: String? = nil
    ) {
        self.success = success
        self.explanation = explanation
        self.additions = additions
        self.removals = removals
        self.modifications = modifications
        self.nextActions = nextActions
        self.errorMessage = errorMessage
    }

    enum CodingKeys: String, CodingKey {
        case success, explanation, additions, removals, modifications, nextActions, errorMessage
        case successPascal = "Success"
        case explanationPascal = "Explanation"
        case additionsPascal = "Additions"
        case removalsPascal = "Removals"
        case modificationsPascal = "Modifications"
        case nextActionsPascal = "NextActions"
        case errorMessagePascal = "ErrorMessage"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let errorMsg = try container.decodeIfPresent(String.self, forKey: .errorMessage)
            ?? container.decodeIfPresent(String.self, forKey: .errorMessagePascal)
        let rawSuccess = try container.decodeIfPresent(Bool.self, forKey: .success)
            ?? container.decodeIfPresent(Bool.self, forKey: .successPascal)
        self.errorMessage = errorMsg
        self.success = rawSuccess ?? (errorMsg == nil)
        self.explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
            ?? container.decodeIfPresent(String.self, forKey: .explanationPascal)
        self.additions = try container.decodeIfPresent([AICopilotItemAdditionDto].self, forKey: .additions)
            ?? container.decodeIfPresent([AICopilotItemAdditionDto].self, forKey: .additionsPascal)
        self.removals = try container.decodeIfPresent([AICopilotItemRemovalDto].self, forKey: .removals)
            ?? container.decodeIfPresent([AICopilotItemRemovalDto].self, forKey: .removalsPascal)
        self.modifications = try container.decodeIfPresent([AICopilotItemModificationDto].self, forKey: .modifications)
            ?? container.decodeIfPresent([AICopilotItemModificationDto].self, forKey: .modificationsPascal)
        self.nextActions = try container.decodeIfPresent([String].self, forKey: .nextActions)
            ?? container.decodeIfPresent([String].self, forKey: .nextActionsPascal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(explanation, forKey: .explanation)
        try container.encodeIfPresent(additions, forKey: .additions)
        try container.encodeIfPresent(removals, forKey: .removals)
        try container.encodeIfPresent(modifications, forKey: .modifications)
        try container.encodeIfPresent(nextActions, forKey: .nextActions)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
    }
}
