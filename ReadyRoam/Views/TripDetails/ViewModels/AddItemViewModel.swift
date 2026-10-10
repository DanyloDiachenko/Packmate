import Foundation
import SwiftUI

@MainActor
final class AddItemViewModel: ObservableObject {
    @Published var itemTitle: String = ""
    @Published var selectedSection: String = "Clothes & Footwear"
    @Published var quantity: Int = 1
    @Published var selectedTag: ItemTag = .essential
    @Published var errorMessage: String? = nil

    var onAddItem: ((CreateTripItemRequest) -> String?)?
    var onClose: (() -> Void)?

    init(
        initialSection: String = "Clothes & Footwear",
        onAddItem: ((CreateTripItemRequest) -> String?)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.selectedSection = initialSection
        self.onAddItem = onAddItem
        self.onClose = onClose
    }

    func configureInitialSection(_ initialSection: String) {
        guard !initialSection.isEmpty else { return }
        if let match = SectionOption.defaults.first(where: {
            $0.name.localizedCaseInsensitiveContains(initialSection) ||
            initialSection.localizedCaseInsensitiveContains($0.name)
        }) {
            selectedSection = match.name
        }
    }

    var isFormValid: Bool {
        !itemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func handleSubmit(dismiss: @escaping () -> Void) {
        let trimmedTitle = itemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let request = CreateTripItemRequest(
            section: selectedSection,
            title: trimmedTitle,
            quantity: quantity,
            tag: selectedTag.rawValue
        )

        if let error = onAddItem?(request) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self.errorMessage = error
            }
        } else {
            errorMessage = nil
            resetForm()
            if let onClose = onClose {
                onClose()
            } else {
                dismiss()
            }
        }
    }

    func resetForm() {
        itemTitle = ""
        quantity = 1
        selectedTag = .essential
        errorMessage = nil
    }

    func incrementQuantity() {
        quantity += 1
    }

    func decrementQuantity() {
        if quantity > 1 {
            quantity -= 1
        }
    }

    func tagIcon(for tag: ItemTag) -> String {
        switch tag {
        case .important: return "exclamationmark.circle.fill"
        case .safety:    return "cross.shield.fill"
        case .essential: return "star.fill"
        case .optional:  return "circle"
        }
    }
}
