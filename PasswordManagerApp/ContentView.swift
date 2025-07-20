import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var accessibilityStateManager: AccessibilityStateManager
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
                    .accessibilityLabel("Main application interface")
            } else {
                LoginView()
                    .accessibilityLabel("Login screen")
            }
        }
        .animation(accessibilityStateManager.shouldReduceAnimations ? .none : .easeInOut, 
                  value: authService.isAuthenticated)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
        .environmentObject(PasswordService())
        .environmentObject(SettingsService())
        .environmentObject(AccessibilityStateManager())
}