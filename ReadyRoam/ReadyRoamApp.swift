import SwiftUI

@main
struct ReadyRoamApp: App {
    @StateObject private var container = AppContainer.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environmentObject(container.config)
                .environmentObject(container.authService)
        }
    }
}
