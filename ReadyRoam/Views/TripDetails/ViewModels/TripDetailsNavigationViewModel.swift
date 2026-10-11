import Foundation
import SwiftUI

extension TripDetailsViewModel {
    func handleDeleteTrip(dismiss: @escaping () -> Void) async {
        guard !isDeletingTrip else { return }
        guard let id = tripId else {
            dismiss()
            return
        }
        isDeletingTrip = true
        defer { isDeletingTrip = false }

        do {
            try await tripService.deleteTrip(id: id)
            await MainActor.run {
                NotificationCenter.default.post(name: .didDeleteTrip, object: id)
                onTripDeleted?(id)
                dismiss()
            }
        } catch {
            await MainActor.run {
                itemErrorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }

    func handleBackNavigation(dismiss: @escaping () -> Void) {
        if let onBack = onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    func openAIDrawer(isShowingAIDrawerBinding: Binding<Bool>) {
        withAnimation(drawerAnimation) {
            activeDrawer = .aiSuggestions
            isShowingAIDrawerBinding.wrappedValue = true
            dragOffset = 0
            addItemDragOffset = 0
        }
    }

    func openAddItemDrawer(for section: String? = nil, isShowingAIDrawerBinding: Binding<Bool>) {
        if let s = section, let enumSection = ChecklistSection(rawValue: s) {
            selectedInitialSection = enumSection
        } else if let expandedId = expandedCategoryIds.first,
                  let cat = categories.first(where: { $0.id == expandedId }),
                  let enumSection = ChecklistSection(rawValue: cat.title) {
            selectedInitialSection = enumSection
        }
        withAnimation(drawerAnimation) {
            activeDrawer = .addItem
            isShowingAIDrawerBinding.wrappedValue = true
            addItemDragOffset = 0
            dragOffset = 0
        }
    }

    func closeDrawer(isShowingAIDrawerBinding: Binding<Bool>? = nil) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation(drawerAnimation) {
            activeDrawer = .none
            isShowingAIDrawerBinding?.wrappedValue = false
            dragOffset = 0
            addItemDragOffset = 0
        }
    }

    func closeAIDrawer(isShowingAIDrawerBinding: Binding<Bool>) {
        closeDrawer(isShowingAIDrawerBinding: isShowingAIDrawerBinding)
    }

    func closeAddItemDrawer(isShowingAIDrawerBinding: Binding<Bool>) {
        closeDrawer(isShowingAIDrawerBinding: isShowingAIDrawerBinding)
    }

    func resetDrawerOffset() {
        withAnimation(drawerAnimation) {
            dragOffset = 0
            addItemDragOffset = 0
        }
    }
}
