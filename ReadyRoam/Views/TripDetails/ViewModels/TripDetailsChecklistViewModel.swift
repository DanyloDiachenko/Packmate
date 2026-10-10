import Foundation
import SwiftUI

extension TripDetailsViewModel {
    func toggleCategoryExpanded(_ id: UUID) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if expandedCategoryIds.contains(id) {
                expandedCategoryIds.remove(id)
            } else {
                expandedCategoryIds.insert(id)
            }
        }
    }

    func loadTripItems() async {
        guard let tripId = tripId else { return }
        if !hasLoadedItems {
            isLoadingItems = true
        }
        defer {
            isLoadingItems = false
        }

        do {
            let sectionGroups = try await tripItemService.fetchTripItems(tripId: tripId)
            guard !Task.isCancelled else { return }
            let defaults = ChecklistCategory.defaultEmptyCategories()
            let merged = Self.mergeCategories(groups: sectionGroups, defaults: defaults)

            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.categories = merged
                self.hasLoadedItems = true

                if self.expandedCategoryIds.isEmpty {
                    if let firstWithItems = merged.first(where: { !$0.items.isEmpty }) {
                        self.expandedCategoryIds.insert(firstWithItems.id)
                    } else if let first = merged.first {
                        self.expandedCategoryIds.insert(first.id)
                    }
                }
            }
        } catch {
            print("Failed to fetch trip items: \(error)")
            await MainActor.run {
                self.itemErrorMessage = error.localizedDescription
                self.showingErrorAlert = true
            }
        }
    }

    static func mergeCategories(
        groups: [TripSectionGroupResponse],
        defaults: [ChecklistCategory]
    ) -> [ChecklistCategory] {
        var mergedCategories: [ChecklistCategory] = []

        for group in groups {
            let info = ChecklistCategory.categoryInfo(for: group.section)
            let items = group.items.map { ChecklistItem(from: $0) }
            let category = ChecklistCategory(
                title: info.title,
                iconName: info.icon,
                accentColor: info.color,
                items: items
            )
            mergedCategories.append(category)
        }

        for defaultCat in defaults {
            if !mergedCategories.contains(where: { $0.title.caseInsensitiveCompare(defaultCat.title) == .orderedSame }) {
                mergedCategories.append(defaultCat)
            }
        }

        return mergedCategories
    }

    func handleToggleItem(item: ChecklistItem) {
        guard !isReadOnly, tripId != nil else { return }
        Task {
            do {
                _ = try await tripItemService.updateTripItem(
                    id: item.id,
                    request: UpdateTripItemRequest(isTaken: item.isPacked)
                )
            } catch {
                print("Failed to update trip item: \(error)")
                await MainActor.run {
                    self.itemErrorMessage = error.localizedDescription
                    self.showingErrorAlert = true
                }
            }
        }
    }

    func handleDeleteItem(item: ChecklistItem, categoryId: UUID) {
        guard !isReadOnly else { return }
        let previousCategories = categories
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            if let catIndex = categories.firstIndex(where: { $0.id == categoryId }) {
                categories[catIndex].items.removeAll(where: { $0.id == item.id })
            }
            if swipedItemId == item.id {
                swipedItemId = nil
            }
        }

        guard tripId != nil else { return }
        Task {
            do {
                try await tripItemService.deleteTripItem(id: item.id)
            } catch {
                print("Failed to delete trip item on server: \(error)")
                await MainActor.run {
                    withAnimation {
                        self.categories = previousCategories
                    }
                    self.itemErrorMessage = error.localizedDescription
                    self.showingErrorAlert = true
                }
            }
        }
    }

    func handleRemoveItem(title: String) {
        guard !isReadOnly else { return }
        for cat in categories {
            if let item = cat.items.first(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame }) {
                handleDeleteItem(item: item, categoryId: cat.id)
                break
            }
        }
    }

    @discardableResult
    func handleAddItem(request: CreateTripItemRequest) -> String? {
        let trimmedTitle = request.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        let isDuplicate = categories.flatMap { $0.items }.contains { item in
            item.title.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(trimmedTitle) == .orderedSame
        }

        if isDuplicate {
            return "An item named '\(trimmedTitle)' already exists in this trip."
        }

        let sectionName = request.section
        let tag = ItemTag(rawValue: request.tag?.capitalized ?? "Essential") ?? .essential
        var tempItem = ChecklistItem(
            id: UUID(),
            title: trimmedTitle,
            isPacked: false,
            countBadge: "\(request.quantity)x",
            tag: tag,
            quantity: request.quantity
        )

        let info = ChecklistCategory.categoryInfo(for: sectionName)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if let index = categories.firstIndex(where: {
                $0.title.caseInsensitiveCompare(info.title) == .orderedSame ||
                $0.title.caseInsensitiveCompare(sectionName) == .orderedSame
            }) {
                categories[index].items.append(tempItem)
                expandedCategoryIds.insert(categories[index].id)
            } else {
                let newCategory = ChecklistCategory(
                    title: info.title,
                    iconName: info.icon,
                    accentColor: info.color,
                    items: [tempItem]
                )
                categories.append(newCategory)
                expandedCategoryIds.insert(newCategory.id)
            }
        }

        if let tripId = tripId {
            Task {
                do {
                    let serverItem = try await tripItemService.createTripItem(tripId: tripId, request: request)
                    await MainActor.run {
                        for cIdx in categories.indices {
                            if let iIdx = categories[cIdx].items.firstIndex(where: { $0.id == tempItem.id }) {
                                categories[cIdx].items[iIdx].id = serverItem.id
                                break
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            for cIdx in categories.indices {
                                categories[cIdx].items.removeAll(where: { $0.id == tempItem.id })
                            }
                        }
                        self.itemErrorMessage = error.localizedDescription
                        self.showingErrorAlert = true
                    }
                }
            }
        }
        return nil
    }
}
