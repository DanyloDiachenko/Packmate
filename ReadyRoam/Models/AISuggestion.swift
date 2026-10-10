import SwiftUI

struct AISuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconEmoji: String
    let sectionTitle: String
    let sectionAccentColor: Color
    let importance: ItemTag
    var isAdded: Bool = false
}
