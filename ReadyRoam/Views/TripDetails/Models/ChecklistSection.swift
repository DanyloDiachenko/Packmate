import Foundation

public enum ChecklistSection: String, CaseIterable, Codable, Hashable {
    case clothesAndFootwear = "Clothes & Footwear"
    case documentsAndMoney = "Documents & Money"
    case electronicsAndTech = "Electronics & Tech"
    case toiletriesAndHealth = "Toiletries & Health"
    case miscAndGear = "Misc & Gear"

    public var displayName: String {
        rawValue
    }
}
