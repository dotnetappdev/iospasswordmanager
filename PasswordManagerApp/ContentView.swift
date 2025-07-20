import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
        .environmentObject(PasswordService())
        .environmentObject(SettingsService())
}