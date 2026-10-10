import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @StateObject private var router = AppRouter()

    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView(onLogout: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        authService.logout()
                    }
                })
            } else {
                AuthView(onAuthenticated: {})
            }
        }
        .environmentObject(router)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
