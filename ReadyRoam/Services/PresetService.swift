import Foundation

@MainActor
final class PresetService: PresetServiceProtocol, ObservableObject {
    private let networkClient: NetworkClientProtocol

    public static let defaultItems: [PresetItemDto] = PresetItemDto.defaultItems

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func fetchPresets() async throws -> [PresetSummaryDto] {
        let endpoint = Endpoint(
            path: "presets",
            method: .get,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func fetchPreset(id: UUID) async throws -> PresetDto {
        let endpoint = Endpoint(
            path: "presets/\(id.uuidString.lowercased())",
            method: .get,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func createPreset(request: CreatePresetRequest) async throws -> PresetDto {
        let bodyData = try JSONEncoder().encode(request)
        let endpoint = Endpoint(
            path: "presets",
            method: .post,
            body: bodyData,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func updatePreset(id: UUID, request: UpdatePresetRequest) async throws -> PresetDto {
        let bodyData = try JSONEncoder().encode(request)
        let endpoint = Endpoint(
            path: "presets/\(id.uuidString.lowercased())",
            method: .put,
            body: bodyData,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }

    func deletePreset(id: UUID) async throws {
        let endpoint = Endpoint(
            path: "presets/\(id.uuidString.lowercased())",
            method: .delete,
            requiresAuth: true
        )
        try await networkClient.requestVoid(endpoint)
    }
}
