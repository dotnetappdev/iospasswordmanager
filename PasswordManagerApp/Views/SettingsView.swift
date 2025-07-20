import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var passwordService: PasswordService
    @EnvironmentObject var accessibilityStateManager: AccessibilityStateManager
    @State private var showingAPISettings = false
    @State private var showingSecuritySettings = false
    @State private var showingPasswordGeneratorSettings = false
    @State private var showingAbout = false
    @State private var showingSignOutAlert = false
    @State private var isTestingConnection = false
    @State private var connectionTestResult: String?
    
    var body: some View {
        NavigationView {
            List {
                // User Section
                Section("Account") {
                    if let user = authService.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .accessibleFont(.title2)
                                .foregroundColor(.blue)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading) {
                                Text(user.email)
                                    .accessibleFont(.headline)
                                Text("Signed in")
                                    .accessibleFont(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Account: \(user.email), signed in")
                    }
                    
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                    .accessibilityButton(
                        "Sign Out",
                        hint: "Sign out of your account"
                    )
                    .accessibleTapTarget()
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Account section")
                
                // Sync & API Section
                Section("Sync & Backup") {
                    NavigationLink(destination: APISettingsView()) {
                        Label("API Configuration", systemImage: "server.rack")
                            .badge(settingsService.isAPIConfigured ? "✓" : "!")
                    }
                    .accessibilityButton(
                        "API Configuration" + (settingsService.isAPIConfigured ? ", configured" : ", not configured"),
                        hint: "Configure server sync settings"
                    )
                    
                    if settingsService.isAPIConfigured {
                        HStack {
                            Label("Sync Status", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .accessibilityLabel("Testing connection")
                            } else {
                                Button("Test Connection") {
                                    testConnection()
                                }
                                .accessibleFont(.caption)
                                .accessibilityButton(
                                    "Test Connection",
                                    hint: "Test connection to sync server"
                                )
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Sync status with test connection button")
                        
                        if let result = connectionTestResult {
                            Text(result)
                                .accessibleFont(.caption)
                                .foregroundColor(result.contains("Success") ? .green : .red)
                                .accessibilityLabel("Connection test result: \(result)")
                        }
                        
                        Toggle("Enable Auto Sync", isOn: $settingsService.autoSync)
                            .accessibilityToggle(
                                "Enable Auto Sync",
                                isOn: settingsService.autoSync,
                                hint: "Automatically sync passwords with server"
                            )
                        
                        if settingsService.autoSync {
                            HStack {
                                Text("Sync Interval")
                                Spacer()
                                Picker("Sync Interval", selection: $settingsService.syncInterval) {
                                    Text("15 minutes").tag(TimeInterval(900))
                                    Text("30 minutes").tag(TimeInterval(1800))
                                    Text("1 hour").tag(TimeInterval(3600))
                                    Text("6 hours").tag(TimeInterval(21600))
                                    Text("24 hours").tag(TimeInterval(86400))
                                }
                                .accessibilityLabel("Sync interval picker")
                                .accessibilityHint("Choose how often to sync with server")
                            }
                        }
                        
                        Button("Sync Now") {
                            syncNow()
                        }
                        .accessibilityButton(
                            "Sync Now",
                            hint: "Immediately sync passwords with server"
                        )
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Sync and backup section")
                
                // Security Section
                Section("Security") {
                    NavigationLink(destination: SecuritySettingsView()) {
                        Label("Security Settings", systemImage: "shield.fill")
                    }
                    .accessibilityButton(
                        "Security Settings",
                        hint: "Configure authentication and security options"
                    )
                    
                    if authService.biometricType != .none {
                        Toggle("Enable \(biometricText)", isOn: $authService.isBiometricEnabled)
                            .onChange(of: authService.isBiometricEnabled) { _, newValue in
                                if newValue {
                                    Task {
                                        await authService.enableBiometrics()
                                    }
                                } else {
                                    authService.disableBiometrics()
                                }
                                let announcement = newValue ? 
                                    "\(biometricText) enabled" : 
                                    "\(biometricText) disabled"
                                UIAccessibility.post(notification: .announcement, argument: announcement)
                            }
                            .accessibilityToggle(
                                "Enable \(biometricText)",
                                isOn: authService.isBiometricEnabled,
                                hint: "Use \(biometricText) to unlock the app"
                            )
                    }
                    
                    HStack {
                        Label("Auto-Lock", systemImage: "lock.rotation")
                        Spacer()
                        Picker("Auto-Lock", selection: $settingsService.autoLockTimeout) {
                            Text("Immediately").tag(TimeInterval(0))
                            Text("1 minute").tag(TimeInterval(60))
                            Text("5 minutes").tag(TimeInterval(300))
                            Text("15 minutes").tag(TimeInterval(900))
                            Text("Never").tag(TimeInterval(-1))
                        }
                        .accessibilityLabel("Auto-lock timeout picker")
                        .accessibilityHint("Choose when to automatically lock the app")
                        .accessibilityValue(autoLockDescription)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Security section")
                
                // Appearance Section
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $settingsService.isDarkMode)
                        .onChange(of: settingsService.isDarkMode) { _, newValue in
                            let announcement = newValue ? "Dark mode enabled" : "Light mode enabled"
                            UIAccessibility.post(notification: .announcement, argument: announcement)
                        }
                        .accessibilityToggle(
                            "Dark Mode",
                            isOn: settingsService.isDarkMode,
                            hint: "Switch between light and dark app appearance"
                        )
                    
                    Toggle("Show Passwords by Default", isOn: $settingsService.showPasswordsByDefault)
                        .accessibilityToggle(
                            "Show Passwords by Default",
                            isOn: settingsService.showPasswordsByDefault,
                            hint: "Show passwords without tapping the reveal button"
                        )
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Appearance section")
                
                // Password Generator Section
                Section("Password Generator") {
                    NavigationLink(destination: PasswordGeneratorSettingsView()) {
                        Label("Generator Settings", systemImage: "wand.and.stars")
                    }
                    .accessibilityButton(
                        "Generator Settings",
                        hint: "Configure default password generation options"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Password generator section")
                
                // Privacy Section
                Section("Privacy") {
                    Toggle("Auto-Clear Clipboard", isOn: $settingsService.enableClipboardClear)
                        .accessibilityToggle(
                            "Auto-Clear Clipboard",
                            isOn: settingsService.enableClipboardClear,
                            hint: "Automatically clear clipboard after copying passwords"
                        )
                    
                    if settingsService.enableClipboardClear {
                        HStack {
                            Text("Clear After")
                            Spacer()
                            Picker("Clear After", selection: $settingsService.clipboardClearTimeout) {
                                Text("10 seconds").tag(TimeInterval(10))
                                Text("30 seconds").tag(TimeInterval(30))
                                Text("1 minute").tag(TimeInterval(60))
                                Text("5 minutes").tag(TimeInterval(300))
                            }
                            .accessibilityLabel("Clipboard clear timeout picker")
                            .accessibilityHint("Choose when to clear clipboard after copying")
                            .accessibilityValue(clipboardTimeoutDescription)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Privacy section")
                
                // Data Section
                Section("Data") {
                    HStack {
                        Label("Passwords", systemImage: "key.fill")
                        Spacer()
                        Text("\(passwordService.passwordCount)")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Passwords: \(passwordService.passwordCount) saved")
                    
                    HStack {
                        Label("Categories", systemImage: "folder.fill")
                        Spacer()
                        Text("\(passwordService.categoryCount)")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Categories: \(passwordService.categoryCount) created")
                    
                    HStack {
                        Label("Favorites", systemImage: "heart.fill")
                        Spacer()
                        Text("\(passwordService.favoriteCount)")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Favorites: \(passwordService.favoriteCount) marked")
                    
                    Button("Export Data") {
                        exportData()
                    }
                    .accessibilityButton(
                        "Export Data",
                        hint: "Export your passwords to a file"
                    )
                    
                    Button("Import Data") {
                        importData()
                    }
                    .accessibilityButton(
                        "Import Data",
                        hint: "Import passwords from a file"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Data section with statistics and import export options")
                
                // About Section
                Section("About") {
                    NavigationLink(destination: AboutView()) {
                        Label("About Password Manager", systemImage: "info.circle")
                    }
                    .accessibilityButton(
                        "About Password Manager",
                        hint: "View app information and features"
                    )
                    
                    HStack {
                        Label("Version", systemImage: "number")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("App version: 1.0.0")
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("About section")
                
                // Danger Zone
                Section("Danger Zone") {
                    Button("Reset All Settings") {
                        resetSettings()
                    }
                    .foregroundColor(.orange)
                    .accessibilityButton(
                        "Reset All Settings",
                        hint: "Warning: This will reset all app settings to defaults"
                    )
                    
                    Button("Delete All Data") {
                        deleteAllData()
                    }
                    .foregroundColor(.red)
                    .accessibilityButton(
                        "Delete All Data",
                        hint: "Warning: This will permanently delete all your passwords"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Danger zone section with destructive actions")
            }
            .navigationTitle(AccessibilityConstants.Navigation.settingsTab)
            .navigationBarTitleDisplayMode(.large)
            .accessibilityHeading(AccessibilityConstants.Navigation.settingsTab)
            .onAppear {
                UIAccessibility.post(notification: .screenChanged, argument: "Settings screen")
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button(AccessibilityConstants.Labels.cancel, role: .cancel) { 
                UIAccessibility.post(notification: .announcement, argument: "Sign out cancelled")
            }
            .accessibilityButton(AccessibilityConstants.Labels.cancel)
            
            Button("Sign Out", role: .destructive) {
                authService.logout()
                UIAccessibility.post(notification: .announcement, argument: "Signed out successfully")
            }
            .accessibilityButton("Sign Out")
        } message: {
            Text("Are you sure you want to sign out?")
                .accessibilityLabel("Confirmation: Are you sure you want to sign out?")
        }
        .accessibilityElement(children: .contain)
    }
    
    private var biometricText: String {
        switch authService.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometrics"
        }
    }
    
    private var autoLockDescription: String {
        switch settingsService.autoLockTimeout {
        case 0: return "Immediately"
        case 60: return "1 minute"
        case 300: return "5 minutes"
        case 900: return "15 minutes"
        case -1: return "Never"
        default: return "Custom"
        }
    }
    
    private var clipboardTimeoutDescription: String {
        switch settingsService.clipboardClearTimeout {
        case 10: return "10 seconds"
        case 30: return "30 seconds"
        case 60: return "1 minute"
        case 300: return "5 minutes"
        default: return "Custom"
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        UIAccessibility.post(notification: .announcement, argument: "Testing connection")
        
        Task {
            let success = await settingsService.testAPIConnection()
            
            await MainActor.run {
                isTestingConnection = false
                connectionTestResult = success ? "Connection successful" : "Connection failed"
                UIAccessibility.post(notification: .announcement, argument: connectionTestResult!)
            }
        }
    }
    
    private func syncNow() {
        UIAccessibility.post(notification: .announcement, argument: "Starting sync")
        Task {
            await passwordService.syncWithServer()
            UIAccessibility.post(notification: .announcement, 
                               argument: AccessibilityConstants.Announcements.syncCompleted)
        }
    }
    
    private func exportData() {
        UIAccessibility.post(notification: .announcement, argument: "Exporting data")
        // Implementation for data export
    }
    
    private func importData() {
        UIAccessibility.post(notification: .announcement, argument: "Importing data")
        // Implementation for data import
    }
    
    private func resetSettings() {
        settingsService.resetToDefaults()
        UIAccessibility.post(notification: .announcement, argument: "Settings reset to defaults")
    }
    
    private func deleteAllData() {
        passwordService.deleteAllPasswords()
        UIAccessibility.post(notification: .announcement, argument: "All data deleted")
    }
}

struct APISettingsView: View {
    @EnvironmentObject var settingsService: SettingsService
    @State private var apiURL = ""
    @State private var apiKey = ""
    @State private var isTestingConnection = false
    @State private var connectionResult = ""
    @State private var showingResult = false
    
    var body: some View {
        Form {
            Section("API Configuration") {
                TextField("API URL", text: $apiURL)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .accessibilityTextField(
                        "API URL",
                        hint: "Enter the server URL for syncing",
                        value: apiURL.isEmpty ? "Not set" : "Set"
                    )
                    .accessibilityId("apiURLField")
                
                SecureField("API Key", text: $apiKey)
                    .accessibilityTextField(
                        "API Key",
                        hint: "Enter your API key for authentication",
                        value: apiKey.isEmpty ? "Not set" : "Set"
                    )
                    .accessibilityId("apiKeyField")
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("API configuration section")
            
            Section("Connection Test") {
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(apiURL.isEmpty || apiKey.isEmpty || isTestingConnection)
                .accessibilityButton(
                    "Test Connection",
                    hint: apiURL.isEmpty || apiKey.isEmpty ? 
                        "Enter API URL and key first" : 
                        "Test connection to sync server"
                )
                
                if isTestingConnection {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .accessibilityHidden(true)
                        Text("Testing connection...")
                    }
                    .accessibilityLabel("Testing connection, please wait")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Connection test section")
            
            Section("Actions") {
                Button(AccessibilityConstants.Labels.save + " Settings") {
                    saveSettings()
                }
                .disabled(apiURL.isEmpty || apiKey.isEmpty)
                .accessibilityButton(
                    AccessibilityConstants.Labels.save + " Settings",
                    hint: apiURL.isEmpty || apiKey.isEmpty ? 
                        "Enter API URL and key first" :
                        "Save the API configuration"
                )
                
                Button("Clear Settings") {
                    clearSettings()
                }
                .foregroundColor(.red)
                .accessibilityButton(
                    "Clear Settings",
                    hint: "Remove all API configuration"
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Actions section")
        }
        .navigationTitle("API Settings")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityHeading("API Settings")
        .onAppear {
            loadSettings()
            UIAccessibility.post(notification: .screenChanged, argument: "API Settings")
        }
        .alert("Connection Test", isPresented: $showingResult) {
            Button("OK") { 
                UIAccessibility.post(notification: .announcement, argument: "Alert dismissed")
            }
            .accessibilityButton("OK")
        } message: {
            Text(connectionResult)
                .accessibilityLabel("Connection test result: \(connectionResult)")
        }
    }
    
    private func loadSettings() {
        apiURL = settingsService.apiURL
        apiKey = settingsService.apiKey
    }
    
    private func saveSettings() {
        settingsService.updateAPISettings(url: apiURL, key: apiKey)
        UIAccessibility.post(notification: .announcement, argument: "API settings saved")
    }
    
    private func clearSettings() {
        apiURL = ""
        apiKey = ""
        settingsService.updateAPISettings(url: "", key: "")
        UIAccessibility.post(notification: .announcement, argument: "API settings cleared")
    }
    
    private func testConnection() {
        isTestingConnection = true
        UIAccessibility.post(notification: .announcement, argument: "Testing connection")
        
        // Temporarily update settings for test
        settingsService.updateAPISettings(url: apiURL, key: apiKey)
        
        Task {
            let success = await settingsService.testAPIConnection()
            
            await MainActor.run {
                isTestingConnection = false
                connectionResult = success ? "Connection successful!" : "Connection failed. Please check your URL and API key."
                showingResult = true
                UIAccessibility.post(notification: .announcement, argument: connectionResult)
            }
        }
    }
}

struct SecuritySettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var settingsService: SettingsService
    @State private var showingChangePassword = false
    
    var body: some View {
        Form {
            Section("Authentication") {
                if authService.biometricType != .none {
                    Toggle("Enable \(biometricText)", isOn: $authService.isBiometricEnabled)
                        .onChange(of: authService.isBiometricEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    await authService.enableBiometrics()
                                }
                            } else {
                                authService.disableBiometrics()
                            }
                            let announcement = newValue ? 
                                "\(biometricText) enabled" : 
                                "\(biometricText) disabled"
                            UIAccessibility.post(notification: .announcement, argument: announcement)
                        }
                        .accessibilityToggle(
                            "Enable \(biometricText)",
                            isOn: authService.isBiometricEnabled,
                            hint: "Use \(biometricText) for app authentication"
                        )
                }
                
                Button("Change Master Password") {
                    showingChangePassword = true
                }
                .accessibilityButton(
                    "Change Master Password",
                    hint: "Update your master password"
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Authentication section")
            
            Section("Auto-Lock") {
                Picker("Auto-Lock Timeout", selection: $settingsService.autoLockTimeout) {
                    Text("Immediately").tag(TimeInterval(0))
                    Text("1 minute").tag(TimeInterval(60))
                    Text("5 minutes").tag(TimeInterval(300))
                    Text("15 minutes").tag(TimeInterval(900))
                    Text("30 minutes").tag(TimeInterval(1800))
                    Text("Never").tag(TimeInterval(-1))
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Auto-lock timeout")
                .accessibilityHint("Choose when to automatically lock the app")
                .accessibilityValue(autoLockDescription)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Auto-lock section")
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityHeading("Security")
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView()
        }
        .onAppear {
            UIAccessibility.post(notification: .screenChanged, argument: "Security Settings")
        }
    }
    
    private var biometricText: String {
        switch authService.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometrics"
        }
    }
    
    private var autoLockDescription: String {
        switch settingsService.autoLockTimeout {
        case 0: return "Immediately"
        case 60: return "1 minute"
        case 300: return "5 minutes"
        case 900: return "15 minutes"
        case 1800: return "30 minutes"
        case -1: return "Never"
        default: return "Custom"
        }
    }
}

struct PasswordGeneratorSettingsView: View {
    @EnvironmentObject var settingsService: SettingsService
    
    var body: some View {
        Form {
            Section("Default Settings") {
                HStack {
                    Text("Password Length")
                    Spacer()
                    Stepper("\(settingsService.passwordGeneratorLength)", value: $settingsService.passwordGeneratorLength, in: 4...128)
                        .accessibilityLabel("Password length")
                        .accessibilityValue("\(settingsService.passwordGeneratorLength) characters")
                        .accessibilityHint("Adjust the default password length")
                }
                
                Toggle("Uppercase Letters", isOn: $settingsService.passwordIncludeUppercase)
                    .accessibilityToggle(
                        "Uppercase Letters",
                        isOn: settingsService.passwordIncludeUppercase,
                        hint: "Include uppercase letters A-Z in generated passwords"
                    )
                
                Toggle("Lowercase Letters", isOn: $settingsService.passwordIncludeLowercase)
                    .accessibilityToggle(
                        "Lowercase Letters",
                        isOn: settingsService.passwordIncludeLowercase,
                        hint: "Include lowercase letters a-z in generated passwords"
                    )
                
                Toggle("Numbers", isOn: $settingsService.passwordIncludeNumbers)
                    .accessibilityToggle(
                        "Numbers",
                        isOn: settingsService.passwordIncludeNumbers,
                        hint: "Include numbers 0-9 in generated passwords"
                    )
                
                Toggle("Symbols", isOn: $settingsService.passwordIncludeSymbols)
                    .accessibilityToggle(
                        "Symbols",
                        isOn: settingsService.passwordIncludeSymbols,
                        hint: "Include special symbols in generated passwords"
                    )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Password generator default settings")
        }
        .navigationTitle("Generator Settings")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityHeading("Generator Settings")
        .onChange(of: settingsService.passwordGeneratorLength) { _, _ in 
            saveSettings()
            UIAccessibility.post(notification: .announcement, 
                               argument: "Password length set to \(settingsService.passwordGeneratorLength)")
        }
        .onChange(of: settingsService.passwordIncludeUppercase) { _, newValue in 
            saveSettings()
            UIAccessibility.post(notification: .announcement, 
                               argument: "Uppercase letters \(newValue ? "enabled" : "disabled")")
        }
        .onChange(of: settingsService.passwordIncludeLowercase) { _, newValue in 
            saveSettings()
            UIAccessibility.post(notification: .announcement, 
                               argument: "Lowercase letters \(newValue ? "enabled" : "disabled")")
        }
        .onChange(of: settingsService.passwordIncludeNumbers) { _, newValue in 
            saveSettings()
            UIAccessibility.post(notification: .announcement, 
                               argument: "Numbers \(newValue ? "enabled" : "disabled")")
        }
        .onChange(of: settingsService.passwordIncludeSymbols) { _, newValue in 
            saveSettings()
            UIAccessibility.post(notification: .announcement, 
                               argument: "Symbols \(newValue ? "enabled" : "disabled")")
        }
        .onAppear {
            UIAccessibility.post(notification: .screenChanged, argument: "Password Generator Settings")
        }
    }
    
    private func saveSettings() {
        settingsService.updatePasswordGeneratorSettings(
            length: settingsService.passwordGeneratorLength,
            uppercase: settingsService.passwordIncludeUppercase,
            lowercase: settingsService.passwordIncludeLowercase,
            numbers: settingsService.passwordIncludeNumbers,
            symbols: settingsService.passwordIncludeSymbols
        )
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Current Password") {
                    SecureField("Current Password", text: $currentPassword)
                        .accessibilityTextField(
                            "Current Password",
                            hint: "Enter your current master password",
                            value: currentPassword.isEmpty ? "Not entered" : "Entered"
                        )
                        .accessibilityId("currentPasswordField")
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Current password section")
                
                Section("New Password") {
                    SecureField("New Password", text: $newPassword)
                        .accessibilityTextField(
                            "New Password",
                            hint: "Enter your new master password, minimum 8 characters",
                            value: newPassword.isEmpty ? "Not entered" : "Entered"
                        )
                        .accessibilityId("newPasswordField")
                    
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .accessibilityTextField(
                            "Confirm New Password",
                            hint: "Re-enter your new password to confirm",
                            value: confirmPassword.isEmpty ? "Not entered" : "Entered"
                        )
                        .accessibilityId("confirmNewPasswordField")
                    
                    if !newPassword.isEmpty {
                        PasswordStrengthMeter(password: newPassword)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("New password section")
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityHeading("Change Password")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AccessibilityConstants.Labels.cancel) {
                        dismiss()
                    }
                    .accessibilityButton(
                        AccessibilityConstants.Labels.cancel,
                        hint: "Cancel password change"
                    )
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AccessibilityConstants.Labels.save) {
                        changePassword()
                    }
                    .disabled(!isValid || isLoading)
                    .accessibilityButton(
                        isLoading ? "Saving password" : AccessibilityConstants.Labels.save,
                        hint: !isValid ? "Complete all fields with valid information first" : "Save your new password"
                    )
                }
            }
            .onAppear {
                UIAccessibility.post(notification: .screenChanged, argument: "Change Password")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { 
                UIAccessibility.post(notification: .announcement, argument: "Error dismissed")
            }
            .accessibilityButton("OK")
        } message: {
            Text(errorMessage)
                .accessibilityLabel("Error: \(errorMessage)")
        }
    }
    
    private var isValid: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword
    }
    
    private func changePassword() {
        isLoading = true
        UIAccessibility.post(notification: .announcement, argument: "Changing password")
        
        Task {
            let success = await authService.changeMasterPassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            await MainActor.run {
                isLoading = false
                if success {
                    UIAccessibility.post(notification: .announcement, argument: "Password changed successfully")
                    dismiss()
                } else {
                    errorMessage = "Failed to change password. Please check your current password."
                    showError = true
                    UIAccessibility.post(notification: .announcement, argument: AccessibilityConstants.Announcements.errorOccurred)
                }
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .accessibleFont(size: 80)
                    .foregroundColor(.blue)
                    .accessibilityLabel("Password Manager app icon")
                
                Text("Password Manager")
                    .accessibleFont(.largeTitle, weight: .bold)
                    .accessibilityHeading("Password Manager")
                
                Text("Version 1.0.0")
                    .accessibleFont(.headline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Version 1.0.0")
                
                Text("A secure, cross-platform password manager built with SwiftUI. Your passwords are encrypted locally and synced securely across your devices.")
                    .accessibleFont(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .accessibilityLabel("App description: A secure, cross-platform password manager built with SwiftUI. Your passwords are encrypted locally and synced securely across your devices.")
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "lock.shield.fill", title: "End-to-End Encryption", description: "Your data is encrypted with AES-256")
                    FeatureRow(icon: "faceid", title: "Biometric Authentication", description: "Unlock with Face ID or Touch ID")
                    FeatureRow(icon: "icloud.fill", title: "Secure Sync", description: "Sync across all your devices")
                    FeatureRow(icon: "wand.and.stars", title: "Password Generator", description: "Generate strong, unique passwords")
                }
                .padding()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("App features list")
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityHeading("About")
        .onAppear {
            UIAccessibility.post(notification: .screenChanged, argument: "About Password Manager")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .accessibleFont(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .accessibleFont(.headline)
                Text(description)
                    .accessibleFont(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsService())
        .environmentObject(AuthenticationService())
        .environmentObject(PasswordService())
        .environmentObject(AccessibilityStateManager())
}