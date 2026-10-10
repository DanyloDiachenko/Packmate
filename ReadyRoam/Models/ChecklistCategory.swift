import SwiftUI

enum ItemTag: String, CaseIterable {
    case important = "Important"
    case safety = "Safety"
    case essential = "Essential"
    case optional = "Optional"

    var tagColor: Color {
        switch self {
        case .important: return Color(hex: "EF4444")
        case .safety:    return Color(hex: "10B981")
        case .essential: return Color(hex: "F59E0B")
        case .optional:  return Color(hex: "94A3B8")
        }
    }

    var backgroundColor: Color {
        tagColor.opacity(0.18)
    }

    var iconName: String? {
        switch self {
        case .important: return "exclamationmark.circle.fill"
        case .safety:    return "cross.shield.fill"
        case .essential: return "star.fill"
        case .optional:  return "circle"
        }
    }
}

struct ChecklistItem: Identifiable, Equatable {
    var id: UUID
    var title: String
    var isPacked: Bool
    var countBadge: String?
    var tag: ItemTag
    var quantity: Int

    init(
        id: UUID = UUID(),
        title: String,
        isPacked: Bool,
        countBadge: String? = nil,
        tag: ItemTag = .essential,
        quantity: Int = 1
    ) {
        self.id = id
        self.title = title
        self.isPacked = isPacked
        self.countBadge = countBadge ?? "\(quantity)x"
        self.tag = tag
        self.quantity = quantity
    }

    init(from response: TripItemResponse) {
        self.id = response.id
        self.title = response.title
        self.isPacked = response.isTaken
        self.countBadge = "\(response.quantity)x"
        self.tag = ItemTag(rawValue: response.tag?.capitalized ?? "") ?? .essential
        self.quantity = response.quantity
    }
}

struct ChecklistCategory: Identifiable, Equatable {
    var id: UUID = UUID()
    let title: String
    let iconName: String
    let accentColor: Color
    var items: [ChecklistItem]

    var packedCount: Int {
        items.filter { $0.isPacked }.count
    }

    var totalCount: Int {
        items.count
    }

    var percentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(packedCount) / Double(totalCount)) * 100)
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(packedCount) / Double(totalCount)
    }

    static func categoryInfo(for sectionName: String) -> (title: String, icon: String, color: Color) {
        let lower = sectionName.lowercased()
        if lower.contains("doc") || lower.contains("money") {
            return ("Documents & Money", "doc.fill", Color(hex: "F59E0B"))
        } else if lower.contains("cloth") || lower.contains("wear") {
            return ("Clothes & Footwear", "tshirt.fill", Color(hex: "10B981"))
        } else if lower.contains("tech") || lower.contains("electr") {
            return ("Electronics & Tech", "laptopcomputer", Color(hex: "38BDF8"))
        } else if lower.contains("toil") || lower.contains("health") {
            return ("Toiletries & Health", "cross.case.fill", Color(hex: "C084FC"))
        } else if lower.contains("misc") || lower.contains("other") || lower.contains("gear") || lower.contains("own") || lower.contains("user") || lower.contains("tool") {
            return ("Misc & Gear", "bag.fill", Color(hex: "F43F5E"))
        } else {
            return (sectionName.capitalized, "cube.box.fill", Color(hex: "38BDF8"))
        }
    }

    static func defaultEmptyCategories() -> [ChecklistCategory] {
        [
            ChecklistCategory(title: "Documents & Money", iconName: "doc.fill", accentColor: Color(hex: "F59E0B"), items: []),
            ChecklistCategory(title: "Clothes & Footwear", iconName: "tshirt.fill", accentColor: Color(hex: "10B981"), items: []),
            ChecklistCategory(title: "Electronics & Tech", iconName: "laptopcomputer", accentColor: Color(hex: "38BDF8"), items: []),
            ChecklistCategory(title: "Toiletries & Health", iconName: "cross.case.fill", accentColor: Color(hex: "C084FC"), items: []),
            ChecklistCategory(title: "Misc & Gear", iconName: "bag.fill", accentColor: Color(hex: "F43F5E"), items: [])
        ]
    }
}

