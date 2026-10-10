import Foundation
import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    static let shared = AppContainer()

    let config: AppConfig
    let networkClient: NetworkClientProtocol
    let authService: AuthService
    let tripService: TripService
    let tripItemService: TripItemService
    let destinationService: DestinationService
    let weatherService: WeatherService
    let aiService: AIService

    init(
        config: AppConfig = .shared,
        networkClient: NetworkClientProtocol? = nil
    ) {
        self.config = config
        let auth = AuthService.shared
        let client = networkClient ?? URLSessionNetworkClient(tokenProvider: auth, config: config)
        self.networkClient = client
        self.authService = auth
        self.tripService = TripService(networkClient: client)
        self.tripItemService = TripItemService(networkClient: client)
        self.destinationService = DestinationService(networkClient: client)
        self.weatherService = WeatherService(networkClient: client)
        self.aiService = AIService(networkClient: client)
    }
}
