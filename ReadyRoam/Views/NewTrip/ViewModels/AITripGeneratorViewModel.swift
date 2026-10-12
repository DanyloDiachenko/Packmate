import Foundation
import SwiftUI

@MainActor
final class AITripGeneratorViewModel: ObservableObject {
    @Published var promptText: String = ""
    @Published var isGenerating: Bool = false
    @Published var isCreatingTrip: Bool = false
    @Published var generationResponse: TripGeneratorResponse? = nil
    @Published var missingFields: [String] = []
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    @Published var showingErrorAlert: Bool = false
    @Published var selectedItemIds: Set<UUID> = []
    @Published var editableItems: [AISkeletonItemDto] = []

    private let aiService: any AIServiceProtocol
    private let tripService: any TripServiceProtocol
    private let tripItemService: any TripItemServiceProtocol

    let samplePrompts: [String] = [
        "Nov 8-13 in Budapest, Hungary. Going to business and City Break.",
        "Weekend getaway to Paris, France in May for sightseeing and food",
        "10 days in Tokyo, Japan in October for culture and tech",
        "1 week beach vacation in Barcelona, Spain in July"
    ]

    init(
        aiService: any AIServiceProtocol = AppContainer.shared.aiService,
        tripService: any TripServiceProtocol = AppContainer.shared.tripService,
        tripItemService: any TripItemServiceProtocol = AppContainer.shared.tripItemService,
        initialPrompt: String = ""
    ) {
        self.aiService = aiService
        self.tripService = tripService
        self.tripItemService = tripItemService
        self.promptText = initialPrompt
    }

    var skeleton: TripSkeletonDto? {
        generationResponse?.skeleton
    }

    var hasSuccessfulSkeleton: Bool {
        generationResponse?.success == true && skeleton != nil
    }

    var selectedItemsCount: Int {
        selectedItemIds.count
    }

    func generateTrip(overridePrompt: String? = nil) async {
        let text = (overridePrompt ?? promptText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isGenerating = true
        errorMessage = nil
        successMessage = nil
        missingFields = []
        defer { isGenerating = false }

        let currentSkeleton: TripSkeletonDto? = skeleton != nil ? TripSkeletonDto(
            city: skeleton!.city,
            country: skeleton!.country,
            countryFlag: skeleton!.countryFlag,
            bannerImage: skeleton!.bannerImage,
            departDate: skeleton!.departDate,
            returnDate: skeleton!.returnDate,
            durationDays: skeleton!.durationDays,
            tags: skeleton!.tags,
            weatherSummary: skeleton!.weatherSummary,
            currentSeason: skeleton!.currentSeason,
            items: editableItems
        ) : nil

        do {
            let response = try await aiService.generateTrip(message: text, skeleton: currentSkeleton)
            guard !Task.isCancelled else { return }
            self.generationResponse = response

            if response.success, let skel = response.skeleton {
                self.editableItems = skel.items
                self.selectedItemIds = Set(skel.items.map { $0.id })
                self.errorMessage = nil
                self.missingFields = []
                self.promptText = ""
                self.successMessage = response.successMessage
            } else {
                self.editableItems = []
                self.selectedItemIds = []
                self.successMessage = nil
                if let err = response.errorMessage {
                    self.errorMessage = sanitizeErrorMessage(err)
                } else {
                    self.errorMessage = nil
                }
                self.missingFields = response.missingFields ?? []
            }
        } catch {
            guard !Task.isCancelled else { return }
            self.successMessage = nil
            self.errorMessage = sanitizeErrorMessage(error.localizedDescription)
            self.showingErrorAlert = false
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

    func applyNextAction(_ action: String) async {
        let trimmedAction = action.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAction.isEmpty else { return }
        await generateTrip(overridePrompt: trimmedAction)
    }

    func toggleItem(_ id: UUID) {
        if selectedItemIds.contains(id) {
            selectedItemIds.remove(id)
        } else {
            selectedItemIds.insert(id)
        }
    }

    func selectAllItems() {
        selectedItemIds = Set(editableItems.map { $0.id })
    }

    func deselectAllItems() {
        selectedItemIds.removeAll()
    }

    func confirmAndCreateTrip(onSuccess: @escaping (Trip) -> Void) async {
        guard let skel = skeleton, !isCreatingTrip else { return }
        isCreatingTrip = true
        defer { isCreatingTrip = false }

        let destDto = TripDestinationDto(
            country: skel.country,
            countryFlag: skel.countryFlag ?? "🌍",
            city: skel.city,
            bannerImage: skel.bannerImage,
            weatherToday: skel.weatherSummary,
            currentSeason: skel.currentSeason
        )

        let reqDto = CreateTripRequestDto(
            destination: destDto,
            departDate: skel.departDate,
            returnDate: skel.returnDate,
            tags: skel.tags
        )

        do {
            let createdTripDto = try await tripService.createTrip(request: reqDto, presetId: nil)

            let chosenItems = editableItems.filter { selectedItemIds.contains($0.id) }
            if !chosenItems.isEmpty {
                let createRequests = chosenItems.map { item -> CreateTripItemRequest in
                    let mappedSection = ChecklistCategory.categoryInfo(for: item.section).title
                    let mappedTag = item.tag?.capitalized ?? "Essential"
                    return CreateTripItemRequest(
                        section: mappedSection,
                        title: item.title,
                        quantity: item.quantity,
                        tag: mappedTag
                    )
                }

                do {
                    _ = try await tripItemService.bulkCreateTripItems(tripId: createdTripDto.id, items: createRequests)
                } catch {
                    for req in createRequests {
                        _ = try? await tripItemService.createTripItem(tripId: createdTripDto.id, request: req)
                    }
                }
            }

            let tripToEmit = Trip(
                from: createdTripDto,
                packedItems: 0,
                totalItems: chosenItems.count
            )

            await MainActor.run {
                onSuccess(tripToEmit)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = sanitizeErrorMessage(error.localizedDescription)
                self.showingErrorAlert = false
            }
        }
    }

    func reset() {
        promptText = ""
        isGenerating = false
        isCreatingTrip = false
        generationResponse = nil
        missingFields = []
        errorMessage = nil
        successMessage = nil
        showingErrorAlert = false
        selectedItemIds = []
        editableItems = []
    }
}
