import Foundation
import SwiftUI

enum NewTripType: String, CaseIterable, Identifiable {
    case beach = "Beach"
    case cityBreak = "City Break"
    case hiking = "Hiking"
    case business = "Business"
    case ski = "Ski & Winter"
    case safari = "Safari"
    case camping = "Camping"
    case foodie = "Foodie"
    case roadtrip = "Road Trip"
    case wellness = "Spa & Wellness"
    case culture = "Culture"
    case cruise = "Cruise"
    case backpacking = "Backpacking"
    case festival = "Events & Festivals"
    case shopping = "Shopping"

    var id: String { rawValue }

    var tagKey: String {
        switch self {
        case .beach: return "beach"
        case .cityBreak: return "city"
        case .hiking: return "hiking"
        case .business: return "business"
        case .ski: return "ski"
        case .safari: return "safari"
        case .camping: return "camping"
        case .foodie: return "foodie"
        case .roadtrip: return "roadtrip"
        case .wellness: return "wellness"
        case .culture: return "culture"
        case .cruise: return "cruise"
        case .backpacking: return "backpacking"
        case .festival: return "festival"
        case .shopping: return "shopping"
        }
    }

    var icon: String {
        TagHelper.icon(for: tagKey)
    }
}
