import Foundation

@MainActor
protocol AuthServiceProtocol: ObservableObject {
    var baseURL: URL { get set }
    var token: String? { get }
    var currentUser: UserProfile? { get }
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get set }

    func signUp(firstName: String, lastName: String, email: String, password: String) async throws -> SignUpSuccessResponse
    func signIn(email: String, password: String) async throws -> SignInResult
    func verifyLogin(email: String, code: String) async throws -> String
    func verifyLogin2FA(email: String, code: String) async throws -> String
    func confirmEmail(email: String, code: String) async throws
    func forgotPassword(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws -> String
    func resendCode(email: String, purpose: String) async throws -> String
    func fetchUserProfile() async throws -> UserProfile
    func updateProfile(firstName: String, lastName: String) async throws -> UserProfile
    func setCustomBaseURL(_ url: URL)
    func logout()
}

@MainActor
protocol TripServiceProtocol: ObservableObject {
    func fetchTrips(limit: Int, offset: Int, isArchived: Bool?) async throws -> PaginatedTripsResponseDto
    func createTrip(request dto: CreateTripRequestDto, presetId: UUID?) async throws -> TripResponseDto
    func archiveTrip(id: UUID) async throws -> TripResponseDto
    func unarchiveTrip(id: UUID) async throws -> TripResponseDto
    func deleteTrip(id: UUID) async throws
    func updateTrip(id: UUID, request dto: UpdateTripRequestDto) async throws -> TripResponseDto
}

extension TripServiceProtocol {
    func createTrip(request dto: CreateTripRequestDto) async throws -> TripResponseDto {
        try await createTrip(request: dto, presetId: nil)
    }
}

@MainActor
protocol TripItemServiceProtocol: ObservableObject {
    func fetchTripItems(tripId: UUID) async throws -> [TripSectionGroupResponse]
    func createTripItem(tripId: UUID, request: CreateTripItemRequest) async throws -> TripItemResponse
    func bulkCreateTripItems(tripId: UUID, items: [CreateTripItemRequest]) async throws -> [TripItemResponse]
    func updateTripItem(id: UUID, request: UpdateTripItemRequest) async throws -> TripItemResponse
    func deleteTripItem(id: UUID) async throws
    func seedDefaultItems(for tripId: UUID) async throws
}

@MainActor
protocol DestinationServiceProtocol: ObservableObject {
    func searchDestinations(query: String) async throws -> [DestinationDto]
    func getPopularDestinations() async throws -> [DestinationDto]
    func getDestinationByCity(city: String) async throws -> DestinationDto
}

@MainActor
protocol WeatherServiceProtocol: ObservableObject {
    func fetchLiveWeather(city: String, country: String) async throws -> WeatherResponse
    func fetchWeather(city: String, country: String, departDate: String, returnDate: String) async throws -> WeatherResponseDto
}

@MainActor
protocol AIServiceProtocol: ObservableObject {
    func fetchPackingSuggestions(cityName: String, country: String, season: String, temperature: String, tripDays: Int, tripType: String, existingItems: [String]) async throws -> [AISuggestion]
    func fetchRecommendations(city: String, country: String, tripDays: Int, tripType: String, weatherSummary: String?, currentSeason: String?, existingItems: [String]) async throws -> AIRecommendationResponse
    func generateTrip(message: String, skeleton: TripSkeletonDto?) async throws -> TripGeneratorResponse
    func refinePackingWithCopilot(request: AIPackingCopilotRequest) async throws -> AIPackingCopilotResponse
}

extension AIServiceProtocol {
    func generateTrip(message: String) async throws -> TripGeneratorResponse {
        try await generateTrip(message: message, skeleton: nil)
    }
}

@MainActor
protocol PresetServiceProtocol: ObservableObject {
    func fetchPresets() async throws -> [PresetSummaryDto]
    func fetchPreset(id: UUID) async throws -> PresetDto
    func createPreset(request: CreatePresetRequest) async throws -> PresetDto
    func updatePreset(id: UUID, request: UpdatePresetRequest) async throws -> PresetDto
    func deletePreset(id: UUID) async throws
}
