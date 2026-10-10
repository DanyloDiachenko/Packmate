import Foundation
import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    static let shared = AppContainer()

    let config: AppConfig
    let tokenStorage: TokenStorageProtocol
    let networkClient: NetworkClientProtocol
    let authService: AuthService
    let tripService: TripService
    let tripItemService: TripItemService
    let destinationService: DestinationService
    let weatherService: WeatherService
    let aiService: AIService

    init(
        config: AppConfig = .shared,
        tokenStorage: TokenStorageProtocol = KeychainStorage.shared,
        networkClient: NetworkClientProtocol? = nil
    ) {
        self.config = config
        self.tokenStorage = tokenStorage
        
        let client = networkClient ?? URLSessionNetworkClient(tokenProvider: tokenStorage, config: config)
        self.networkClient = client
        
        let auth = AuthService(config: config, networkClient: client, tokenStorage: tokenStorage)
        self.authService = auth
        
        self.tripService = TripService(networkClient: client)
        self.tripItemService = TripItemService(networkClient: client)
        self.destinationService = DestinationService(networkClient: client)
        self.weatherService = WeatherService(networkClient: client)
        self.aiService = AIService(networkClient: client)
    }
}
