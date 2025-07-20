import SwiftUI

@main
struct PasswordManagerAppApp: App {
    @StateObject private var authenticationService = AuthenticationService()
    @StateObject private var passwordService = PasswordService()
    @StateObject private var settingsService = SettingsService()
    @StateObject private var accessibilityStateManager = AccessibilityStateManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationService)
                .environmentObject(passwordService)
                .environmentObject(settingsService)
                .environmentObject(accessibilityStateManager)
                .preferredColorScheme(settingsService.isDarkMode ? .dark : .light)
                .dynamicTypeSize(.small...DynamicTypeSize.accessibility5)
                .onAppear {
                    setupAccessibility()
                }
        }
    }
    
    private func setupAccessibility() {
        // Configure app-wide accessibility settings
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
}