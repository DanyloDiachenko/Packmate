import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView(onLogout: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        authService.logout()
                    }
                })
            } else {
                AuthView(onAuthenticated: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                    }
                })
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
