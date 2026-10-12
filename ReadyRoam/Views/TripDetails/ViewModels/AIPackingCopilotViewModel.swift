import Foundation
import SwiftUI

@MainActor
final class AIPackingCopilotViewModel: ObservableObject {
    @Published var promptText: String = ""
    @Published var isRefining: Bool = false
    @Published var isApplyingChanges: Bool = false
    @Published var copilotResponse: AIPackingCopilotResponse? = nil
    @Published var errorMessage: String? = nil
    @Published var selectedAdditionIds: Set<UUID> = []
    @Published var selectedRemovalIds: Set<UUID> = []
    @Published var selectedModificationIds: Set<UUID> = []
    @Published var appliedSuccessNotice: String? = nil
    @Published var dynamicNextActions: [String] = []

    private let aiService: any AIServiceProtocol
    private let tripItemService: any TripItemServiceProtocol

    let presetPrompts: [String] = [
        "Add things for hiking.",
        "Remove things I don't need.",
        "I'm going to have laundry.",
        "Make this fit into carry-on.",
        "What am I missing?",
        "Make it lighter."
    ]

    var displayedQuickRefinements: [String] {
        if !dynamicNextActions.isEmpty {
            return dynamicNextActions
        }
        return presetPrompts
    }

    var isShowingDynamicNextActions: Bool {
        !dynamicNextActions.isEmpty
    }

    func resetToDefaultPresets() {
        dynamicNextActions = []
    }

    init(
        aiService: any AIServiceProtocol = AppContainer.shared.aiService,
        tripItemService: any TripItemServiceProtocol = AppContainer.shared.tripItemService
    ) {
        self.aiService = aiService
        self.tripItemService = tripItemService
    }

    var hasActiveProposedChanges: Bool {
        guard let resp = copilotResponse, resp.success else { return false }
        let additionsCount = resp.additions?.count ?? 0
        let removalsCount = resp.removals?.count ?? 0
        let modificationsCount = resp.modifications?.count ?? 0
        return additionsCount + removalsCount + modificationsCount > 0
    }

    var totalSelectedChangesCount: Int {
        selectedAdditionIds.count + selectedRemovalIds.count + selectedModificationIds.count
    }

    func refinePacking(promptOverride: String? = nil, tripDetailsViewModel: TripDetailsViewModel) async {
        let text = (promptOverride ?? promptText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard let tripId = tripDetailsViewModel.tripId else { return }

        isRefining = true
        errorMessage = nil
        appliedSuccessNotice = nil
        defer { isRefining = false }

        let currentExisting: [AICopilotExistingItemDto] = tripDetailsViewModel.categories.flatMap { cat in
            cat.items.map { item in
                AICopilotExistingItemDto(
                    id: item.id,
                    title: item.title,
                    section: cat.title,
                    quantity: item.quantity,
                    isPacked: item.isPacked,
                    tag: item.tag.rawValue
                )
            }
        }

        let request = AIPackingCopilotRequest(
            tripId: tripId,
            prompt: text,
            destination: "\(tripDetailsViewModel.city), \(tripDetailsViewModel.country)",
            dateRange: tripDetailsViewModel.dateRange,
            nightsCount: tripDetailsViewModel.nightsCount,
            existingItems: currentExisting
        )

        do {
            let response = try await aiService.refinePackingWithCopilot(request: request)
            guard !Task.isCancelled else { return }
            self.copilotResponse = response

            if response.success {
                let addIds = response.additions?.map { $0.id } ?? []
                let remIds = response.removals?.map { $0.id } ?? []
                let modIds = response.modifications?.map { $0.id } ?? []

                self.selectedAdditionIds = Set(addIds)
                self.selectedRemovalIds = Set(remIds)
                self.selectedModificationIds = Set(modIds)
                self.promptText = ""
                self.errorMessage = nil
            } else {
                self.errorMessage = sanitizeErrorMessage(response.errorMessage ?? "Failed to refine packing items.")
            }
        } catch {
            guard !Task.isCancelled else { return }
            self.errorMessage = sanitizeErrorMessage(error.localizedDescription)
        }
    }

    private func sanitizeErrorMessage(_ raw: String) -> String {
        if raw.contains("429")
            || raw.localizedCaseInsensitiveContains("TooManyRequests")
            || raw.localizedCaseInsensitiveContains("RESOURCE_EXHAUSTED")
            || raw.localizedCaseInsensitiveContains("Quota exceeded") {
            return "Too many requests, try again later"
        }
        if raw.contains("502")
            || raw.contains("503")
            || raw.localizedCaseInsensitiveContains("ServiceUnavailable")
            || raw.localizedCaseInsensitiveContains("BadGateway") {
            return "AI Service is currently experiencing high demand. Please try again in a moment."
        }
        return raw
    }

    func toggleAddition(_ id: UUID) {
        if selectedAdditionIds.contains(id) {
            selectedAdditionIds.remove(id)
        } else {
            selectedAdditionIds.insert(id)
        }
    }

    func toggleRemoval(_ id: UUID) {
        if selectedRemovalIds.contains(id) {
            selectedRemovalIds.remove(id)
        } else {
            selectedRemovalIds.insert(id)
        }
    }

    func toggleModification(_ id: UUID) {
        if selectedModificationIds.contains(id) {
            selectedModificationIds.remove(id)
        } else {
            selectedModificationIds.insert(id)
        }
    }

    func discardProposedChanges() {
        if let actions = copilotResponse?.nextActions, !actions.isEmpty {
            self.dynamicNextActions = Array(actions.prefix(3))
        }
        copilotResponse = nil
        selectedAdditionIds.removeAll()
        selectedRemovalIds.removeAll()
        selectedModificationIds.removeAll()
        errorMessage = nil
    }

    func applySelectedChanges(tripDetailsViewModel: TripDetailsViewModel) async {
        guard let resp = copilotResponse, resp.success else { return }
        guard let tripId = tripDetailsViewModel.tripId else { return }

        isApplyingChanges = true
        defer { isApplyingChanges = false }

        var appliedCount = 0

        if let additions = resp.additions {
            for addition in additions where selectedAdditionIds.contains(addition.id) {
                let req = CreateTripItemRequest(
                    section: addition.section,
                    title: addition.title,
                    quantity: addition.quantity,
                    tag: addition.tag
                )
                tripDetailsViewModel.handleAddItem(request: req)
                appliedCount += 1
            }
        }

        if let removals = resp.removals {
            for removal in removals where selectedRemovalIds.contains(removal.id) {
                if let matchedCategory = tripDetailsViewModel.categories.first(where: { cat in
                    cat.items.contains(where: { it in
                        if let mid = removal.itemId, it.id == mid { return true }
                        return it.title.caseInsensitiveCompare(removal.title) == .orderedSame
                    })
                }),
                let matchedItem = matchedCategory.items.first(where: { it in
                    if let mid = removal.itemId, it.id == mid { return true }
                    return it.title.caseInsensitiveCompare(removal.title) == .orderedSame
                }) {
                    tripDetailsViewModel.handleDeleteItem(item: matchedItem, categoryId: matchedCategory.id)
                    appliedCount += 1
                }
            }
        }

        if let modifications = resp.modifications {
            for mod in modifications where selectedModificationIds.contains(mod.id) {
                for cIdx in tripDetailsViewModel.categories.indices {
                    if let iIdx = tripDetailsViewModel.categories[cIdx].items.firstIndex(where: { it in
                        if let mid = mod.itemId, it.id == mid { return true }
                        return it.title.caseInsensitiveCompare(mod.title) == .orderedSame
                    }) {
                        let item = tripDetailsViewModel.categories[cIdx].items[iIdx]
                        let newQty = mod.newQuantity
                        withAnimation {
                            tripDetailsViewModel.categories[cIdx].items[iIdx].quantity = newQty
                            tripDetailsViewModel.categories[cIdx].items[iIdx].countBadge = "\(newQty)x"
                        }
                        Task {
                            _ = try? await tripItemService.updateTripItem(
                                id: item.id,
                                request: UpdateTripItemRequest(quantity: newQty, isTaken: item.isPacked)
                            )
                        }
                        appliedCount += 1
                    }
                }
            }
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            appliedSuccessNotice = "Applied \(appliedCount) updates to trip packing list"
            discardProposedChanges()
        }
    }
}
