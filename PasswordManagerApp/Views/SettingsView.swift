import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var passwordService: PasswordService
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
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(user.email)
                                    .font(.headline)
                                Text("Signed in")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                // Sync & API Section
                Section("Sync & Backup") {
                    NavigationLink(destination: APISettingsView()) {
                        Label("API Configuration", systemImage: "server.rack")
                            .badge(settingsService.isAPIConfigured ? "✓" : "!")
                    }
                    
                    if settingsService.isAPIConfigured {
                        HStack {
                            Label("Sync Status", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Button("Test Connection") {
                                    testConnection()
                                }
                                .font(.caption)
                            }
                        }
                        
                        if let result = connectionTestResult {
                            Text(result)
                                .font(.caption)
                                .foregroundColor(result.contains("Success") ? .green : .red)
                        }
                        
                        Toggle("Enable Auto Sync", isOn: $settingsService.autoSync)
                        
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
                            }
                        }
                        
                        Button("Sync Now") {
                            syncNow()
                        }
                    }
                }
                
                // Security Section
                Section("Security") {
                    NavigationLink(destination: SecuritySettingsView()) {
                        Label("Security Settings", systemImage: "shield.fill")
                    }
                    
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
                            }
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
                    }
                }
                
                // Appearance Section
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $settingsService.isDarkMode)
                    
                    Toggle("Show Passwords by Default", isOn: $settingsService.showPasswordsByDefault)
                }
                
                // Password Generator Section
                Section("Password Generator") {
                    NavigationLink(destination: PasswordGeneratorSettingsView()) {
                        Label("Generator Settings", systemImage: "wand.and.stars")
                    }
                }
                
                // Privacy Section
                Section("Privacy") {
                    Toggle("Auto-Clear Clipboard", isOn: $settingsService.enableClipboardClear)
                    
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
                        }
                    }
                }
                
                // Data Section
                Section("Data") {
                    HStack {
                        Label("Passwords", systemImage: "key.fill")
                        Spacer()
                        Text("\(passwordService.passwordCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Categories", systemImage: "folder.fill")
                        Spacer()
                        Text("\(passwordService.categoryCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Favorites", systemImage: "heart.fill")
                        Spacer()
                        Text("\(passwordService.favoriteCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Export Data") {
                        exportData()
                    }
                    
                    Button("Import Data") {
                        importData()
                    }
                }
                
                // About Section
                Section("About") {
                    NavigationLink(destination: AboutView()) {
                        Label("About Password Manager", systemImage: "info.circle")
                    }
                    
                    HStack {
                        Label("Version", systemImage: "number")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Danger Zone
                Section("Danger Zone") {
                    Button("Reset All Settings") {
                        resetSettings()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Delete All Data") {
                        deleteAllData()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
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
    
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        
        Task {
            let success = await settingsService.testAPIConnection()
            
            await MainActor.run {
                isTestingConnection = false
                connectionTestResult = success ? "Connection successful" : "Connection failed"
            }
        }
    }
    
    private func syncNow() {
        Task {
            await passwordService.syncWithServer()
        }
    }
    
    private func exportData() {
        // Implementation for data export
    }
    
    private func importData() {
        // Implementation for data import
    }
    
    private func resetSettings() {
        settingsService.resetToDefaults()
    }
    
    private func deleteAllData() {
        passwordService.deleteAllPasswords()
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
                
                SecureField("API Key", text: $apiKey)
            }
            
            Section("Connection Test") {
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(apiURL.isEmpty || apiKey.isEmpty || isTestingConnection)
                
                if isTestingConnection {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Testing connection...")
                    }
                }
            }
            
            Section("Actions") {
                Button("Save Settings") {
                    saveSettings()
                }
                .disabled(apiURL.isEmpty || apiKey.isEmpty)
                
                Button("Clear Settings") {
                    clearSettings()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("API Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSettings()
        }
        .alert("Connection Test", isPresented: $showingResult) {
            Button("OK") { }
        } message: {
            Text(connectionResult)
        }
    }
    
    private func loadSettings() {
        apiURL = settingsService.apiURL
        apiKey = settingsService.apiKey
    }
    
    private func saveSettings() {
        settingsService.updateAPISettings(url: apiURL, key: apiKey)
    }
    
    private func clearSettings() {
        apiURL = ""
        apiKey = ""
        settingsService.updateAPISettings(url: "", key: "")
    }
    
    private func testConnection() {
        isTestingConnection = true
        
        // Temporarily update settings for test
        settingsService.updateAPISettings(url: apiURL, key: apiKey)
        
        Task {
            let success = await settingsService.testAPIConnection()
            
            await MainActor.run {
                isTestingConnection = false
                connectionResult = success ? "Connection successful!" : "Connection failed. Please check your URL and API key."
                showingResult = true
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
                        }
                }
                
                Button("Change Master Password") {
                    showingChangePassword = true
                }
            }
            
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
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView()
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
                }
                
                Toggle("Uppercase Letters", isOn: $settingsService.passwordIncludeUppercase)
                Toggle("Lowercase Letters", isOn: $settingsService.passwordIncludeLowercase)
                Toggle("Numbers", isOn: $settingsService.passwordIncludeNumbers)
                Toggle("Symbols", isOn: $settingsService.passwordIncludeSymbols)
            }
        }
        .navigationTitle("Generator Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settingsService.passwordGeneratorLength) { _, _ in saveSettings() }
        .onChange(of: settingsService.passwordIncludeUppercase) { _, _ in saveSettings() }
        .onChange(of: settingsService.passwordIncludeLowercase) { _, _ in saveSettings() }
        .onChange(of: settingsService.passwordIncludeNumbers) { _, _ in saveSettings() }
        .onChange(of: settingsService.passwordIncludeSymbols) { _, _ in saveSettings() }
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
                }
                
                Section("New Password") {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                    
                    if !newPassword.isEmpty {
                        PasswordStrengthMeter(password: newPassword)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        changePassword()
                    }
                    .disabled(!isValid || isLoading)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValid: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword
    }
    
    private func changePassword() {
        isLoading = true
        
        Task {
            let success = await authService.changeMasterPassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            await MainActor.run {
                isLoading = false
                if success {
                    dismiss()
                } else {
                    errorMessage = "Failed to change password. Please check your current password."
                    showError = true
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
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Password Manager")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("A secure, cross-platform password manager built with SwiftUI. Your passwords are encrypted locally and synced securely across your devices.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "lock.shield.fill", title: "End-to-End Encryption", description: "Your data is encrypted with AES-256")
                    FeatureRow(icon: "faceid", title: "Biometric Authentication", description: "Unlock with Face ID or Touch ID")
                    FeatureRow(icon: "icloud.fill", title: "Secure Sync", description: "Sync across all your devices")
                    FeatureRow(icon: "wand.and.stars", title: "Password Generator", description: "Generate strong, unique passwords")
                }
                .padding()
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsService())
        .environmentObject(AuthenticationService())
        .environmentObject(PasswordService())
}