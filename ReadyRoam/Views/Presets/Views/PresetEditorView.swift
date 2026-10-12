import SwiftUI

struct PresetEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let presetId: UUID?
    let initialPreset: PresetDto?
    var onSaved: ((PresetDto) -> Void)? = nil

    @State private var name: String = ""
    @State private var descriptionText: String = ""
    @State private var itemsByCategory: [String: [PresetItemDto]] = [:]
    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingErrorAlert: Bool = false

    @State private var showingAddItemDialog: Bool = false
    @State private var addingSection: String = "Clothes & Footwear"
    @State private var newItemTitle: String = ""
    @State private var newItemQuantity: Int = 1
    @State private var newItemTag: ItemTag = .essential

    private let presetService: any PresetServiceProtocol = AppContainer.shared.presetService

    private let availableSections: [String] = [
        "Essentials & Documents",
        "Clothes & Footwear",
        "Electronics & Tech",
        "Toiletries & Health",
        "Misc & Gear"
    ]

    init(
        presetId: UUID? = nil,
        initialPreset: PresetDto? = nil,
        onSaved: ((PresetDto) -> Void)? = nil
    ) {
        self.presetId = presetId
        self.initialPreset = initialPreset
        self.onSaved = onSaved
    }

    var totalItemsCount: Int {
        itemsByCategory.values.reduce(0) { $0 + $1.count }
    }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && totalItemsCount > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.darkBackground
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(AppTheme.skyCyan)
                        .scaleEffect(1.2)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            presetInfoCard

                            categoriesSection

                            Spacer().frame(height: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                    }
                }
            }
            .navigationTitle(presetId == nil ? "New Preset" : "Edit Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: savePreset) {
                        if isSaving {
                            ProgressView()
                                .tint(AppTheme.skyCyan)
                        } else {
                            Text("Save")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(isFormValid ? AppTheme.skyCyan : AppTheme.textMuted)
                        }
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            .preferredColorScheme(.dark)
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unexpected error occurred.")
            }
            .sheet(isPresented: $showingAddItemDialog) {
                addItemSheet
            }
            .task {
                await loadInitialData()
            }
        }
    }

    private var presetInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("PRESET NAME")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.textSecondary)

                TextField(
                    "",
                    text: $name,
                    prompt: Text("e.g. Summer Vacation, Weekend Getaway").foregroundColor(AppTheme.textMuted)
                )
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppTheme.inputBorder.opacity(0.6), lineWidth: 1)
                        )
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("DESCRIPTION (OPTIONAL)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.textSecondary)

                TextField(
                    "",
                    text: $descriptionText,
                    prompt: Text("Short note about when to use this preset").foregroundColor(AppTheme.textMuted)
                )
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppTheme.inputBorder.opacity(0.6), lineWidth: 1)
                        )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var allDisplayedSections: [String] {
        var sections = availableSections
        for key in itemsByCategory.keys {
            if !sections.contains(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                sections.append(key)
            }
        }
        return sections
    }

    private func items(for section: String) -> [PresetItemDto] {
        if let direct = itemsByCategory[section] {
            return direct
        }
        if let match = itemsByCategory.first(where: { $0.key.caseInsensitiveCompare(section) == .orderedSame }) {
            return match.value
        }
        return []
    }

    private func updateItems(_ newItems: [PresetItemDto], for section: String) {
        let matchingKey = itemsByCategory.keys.first(where: { $0.caseInsensitiveCompare(section) == .orderedSame }) ?? section
        itemsByCategory[matchingKey] = newItems
    }

    private var categoriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("PACKING ITEMS (\(totalItemsCount))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.skyCyan)

                Spacer()
            }

            ForEach(allDisplayedSections, id: \.self) { section in
                categoryCard(section: section)
            }
        }
    }

    private func categoryCard(section: String) -> some View {
        let currentItems = items(for: section)
        let info = ChecklistCategory.categoryInfo(for: section)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: info.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(info.color)

                    Text(info.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                Spacer()

                Button(action: {
                    addingSection = section
                    newItemTitle = ""
                    newItemQuantity = 1
                    newItemTag = .essential
                    showingAddItemDialog = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.skyCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.skyCyan.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            if currentItems.isEmpty {
                Text("No items in this section")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 8) {
                    ForEach(currentItems.indices, id: \.self) { index in
                        let item = currentItems[index]
                        itemRow(item: item, section: section, index: index)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func itemRow(item: PresetItemDto, section: String, index: Int) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                if let tag = item.tag, !tag.isEmpty {
                    Text(tag)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ItemTag(rawValue: tag)?.tagColor ?? AppTheme.textMuted)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: {
                    if item.quantity > 1 {
                        var updated = items(for: section)
                        if updated.indices.contains(index) {
                            updated[index].quantity -= 1
                            updateItems(updated, for: section)
                        }
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(item.quantity > 1 ? .white : AppTheme.textMuted)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(item.quantity > 1 ? 0.08 : 0.03))
                        .clipShape(Circle())
                }
                .disabled(item.quantity <= 1)

                Text("\(item.quantity)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(minWidth: 18)

                Button(action: {
                    var updated = items(for: section)
                    if updated.indices.contains(index) {
                        updated[index].quantity += 1
                        updateItems(updated, for: section)
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    var updated = items(for: section)
                    if updated.indices.contains(index) {
                        updated.remove(at: index)
                        updateItems(updated, for: section)
                    }
                }
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "EF4444"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "EF4444").opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "181C26"))
        )
    }

    private var addItemSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.darkBackground
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ITEM NAME")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundColor(AppTheme.textSecondary)

                        TextField("", text: $newItemTitle, prompt: Text("e.g. Swimsuit, Adapter").foregroundColor(AppTheme.textMuted))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.inputBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(AppTheme.inputBorder.opacity(0.6), lineWidth: 1)
                                    )
                            )
                    }

                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("QUANTITY")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundColor(AppTheme.textSecondary)

                            HStack(spacing: 10) {
                                Button(action: {
                                    if newItemQuantity > 1 { newItemQuantity -= 1 }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(newItemQuantity > 1 ? .white : AppTheme.textMuted)
                                        .frame(width: 28, height: 28)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Circle())
                                }
                                .disabled(newItemQuantity <= 1)

                                Text("\(newItemQuantity)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(minWidth: 24)

                                Button(action: { newItemQuantity += 1 }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Circle())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.inputBackground)
                            )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("PRIORITY")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundColor(AppTheme.textSecondary)

                            Menu {
                                ForEach(ItemTag.allCases, id: \.self) { tag in
                                    Button(action: { newItemTag = tag }) {
                                        Text(tag.rawValue)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(newItemTag.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(newItemTag.tagColor)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textMuted)
                                }
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AppTheme.inputBackground)
                                )
                            }
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Add to \(addingSection)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddItemDialog = false
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let newItem = PresetItemDto(
                            id: UUID(),
                            section: addingSection,
                            title: trimmed,
                            quantity: newItemQuantity,
                            tag: newItemTag.rawValue
                        )
                        var list = items(for: addingSection)
                        list.append(newItem)
                        updateItems(list, for: addingSection)
                        showingAddItemDialog = false
                    }
                    .foregroundColor(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.textMuted : AppTheme.skyCyan)
                    .disabled(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .presentationDetents([.height(300)])
            .preferredColorScheme(.dark)
        }
    }

    private func normalizeCategories(_ raw: [String: [PresetItemDto]]) -> [String: [PresetItemDto]] {
        var normalized: [String: [PresetItemDto]] = [:]
        for (rawSection, items) in raw {
            let trimmedSection = rawSection.trimmingCharacters(in: .whitespacesAndNewlines)
            let canonical = availableSections.first(where: {
                $0.caseInsensitiveCompare(trimmedSection) == .orderedSame
            }) ?? trimmedSection
            let updatedItems = items.map { item -> PresetItemDto in
                var copy = item
                copy.section = canonical
                return copy
            }
            normalized[canonical, default: []].append(contentsOf: updatedItems)
        }
        return normalized
    }

    private func loadInitialData() async {
        if let initial = initialPreset {
            self.name = initial.name
            self.descriptionText = initial.description ?? ""
            self.itemsByCategory = normalizeCategories(initial.categories)
            return
        }

        if let id = presetId {
            isLoading = true
            defer { isLoading = false }
            do {
                let fetched = try await presetService.fetchPreset(id: id)
                guard !Task.isCancelled else { return }
                self.name = fetched.name
                self.descriptionText = fetched.description ?? ""
                self.itemsByCategory = normalizeCategories(fetched.categories)
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = error.localizedDescription
                self.showingErrorAlert = true
            }
        } else {
            self.name = "My Packing Preset"
            self.descriptionText = "Standard essentials and clothes for travel"
            var dict: [String: [PresetItemDto]] = [:]
            for item in PresetItemDto.defaultItems {
                var copy = item
                copy.id = UUID()
                dict[item.section, default: []].append(copy)
            }
            self.itemsByCategory = normalizeCategories(dict)
        }
    }

    private func savePreset() {
        guard isFormValid && !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let descValue = trimmedDesc.isEmpty ? nil : trimmedDesc
        let payloadCategories = normalizeCategories(itemsByCategory)

        Task {
            do {
                if let id = presetId {
                    let request = UpdatePresetRequest(
                        name: trimmedName,
                        description: descValue,
                        categories: payloadCategories
                    )
                    let updated = try await presetService.updatePreset(id: id, request: request)
                    await MainActor.run {
                        onSaved?(updated)
                        dismiss()
                    }
                } else {
                    let request = CreatePresetRequest(
                        name: trimmedName,
                        description: descValue,
                        categories: payloadCategories
                    )
                    let created = try await presetService.createPreset(request: request)
                    await MainActor.run {
                        onSaved?(created)
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingErrorAlert = true
                }
            }
        }
    }
}
