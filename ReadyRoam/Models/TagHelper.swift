import Foundation

public struct TagHelper {
    public static func icon(for tag: String) -> String {
        let lower = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch lower {
        case "vacation", "holiday", "flights", "flight", "plane":
            return "airplane"
        case "sightseeing", "museum", "museums", "culture", "tickets", "ticket":
            return "ticket.fill"
        case "foodie", "food", "dining", "culinary", "restaurant", "restaurants":
            return "fork.knife"
        case "beach", "sun", "sea", "summer", "ocean":
            return "sun.max.fill"
        case "business", "work", "office":
            return "briefcase.fill"
        case "hiking", "trekking", "nature", "mountains", "mountain":
            return "figure.hiking"
        case "city", "city break", "citybreak", "urban":
            return "building.2.fill"
        case "ski", "skiing", "snow", "winter":
            return "snowflake"
        case "safari", "wildlife", "animals", "animal":
            return "leaf.fill"
        case "hotel", "stay", "resort", "lodging":
            return "building.2.crop.circle.fill"
        case "shopping":
            return "bag.fill"
        case "relaxation", "spa", "wellness":
            return "sparkles"
        case "camping":
            return "tent.fill"
        case "roadtrip", "road trip", "car":
            return "car.fill"
        case "cruise", "sailing", "boat", "ship":
            return "ferry.fill"
        case "backpacking", "backpack":
            return "backpack.fill"
        case "festival", "events", "music", "party":
            return "music.note"
        default:
            return "tag.fill"
        }
    }
}
