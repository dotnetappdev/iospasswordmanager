import SwiftUI

@main
struct PasswordManagerAppApp: App {
    @StateObject private var authenticationService = AuthenticationService()
    @StateObject private var passwordService = PasswordService()
    @StateObject private var settingsService = SettingsService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationService)
                .environmentObject(passwordService)
                .environmentObject(settingsService)
                .preferredColorScheme(settingsService.isDarkMode ? .dark : .light)
        }
    }
}