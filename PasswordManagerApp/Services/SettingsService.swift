import Foundation
import Combine

class SettingsService: ObservableObject {
    static var shared: SettingsService?
    
    @Published var apiURL: String = ""
    @Published var apiKey: String = ""
    @Published var syncEnabled: Bool = false
    @Published var biometricEnabled: Bool = false
    @Published var isDarkMode: Bool = false
    @Published var autoSync: Bool = false
    @Published var syncInterval: TimeInterval = 3600 // 1 hour
    @Published var passwordGeneratorLength: Int = 16
    @Published var passwordIncludeUppercase: Bool = true
    @Published var passwordIncludeLowercase: Bool = true
    @Published var passwordIncludeNumbers: Bool = true
    @Published var passwordIncludeSymbols: Bool = true
    @Published var autoLockTimeout: TimeInterval = 300 // 5 minutes
    @Published var showPasswordsByDefault: Bool = false
    @Published var enableClipboardClear: Bool = true
    @Published var clipboardClearTimeout: TimeInterval = 30
    
    private let userDefaults = UserDefaults.standard
    private let keychainService = KeychainService()
    
    init() {
        SettingsService.shared = self
        loadSettings()
        setupAutoSync()
    }
    
    // MARK: - Settings Persistence
    private func loadSettings() {
        apiURL = userDefaults.string(forKey: "apiURL") ?? ""
        syncEnabled = userDefaults.bool(forKey: "syncEnabled")
        isDarkMode = userDefaults.bool(forKey: "isDarkMode")
        autoSync = userDefaults.bool(forKey: "autoSync")
        syncInterval = userDefaults.double(forKey: "syncInterval").isZero ? 3600 : userDefaults.double(forKey: "syncInterval")
        passwordGeneratorLength = userDefaults.integer(forKey: "passwordGeneratorLength").isZero ? 16 : userDefaults.integer(forKey: "passwordGeneratorLength")
        passwordIncludeUppercase = userDefaults.object(forKey: "passwordIncludeUppercase") as? Bool ?? true
        passwordIncludeLowercase = userDefaults.object(forKey: "passwordIncludeLowercase") as? Bool ?? true
        passwordIncludeNumbers = userDefaults.object(forKey: "passwordIncludeNumbers") as? Bool ?? true
        passwordIncludeSymbols = userDefaults.object(forKey: "passwordIncludeSymbols") as? Bool ?? true
        autoLockTimeout = userDefaults.double(forKey: "autoLockTimeout").isZero ? 300 : userDefaults.double(forKey: "autoLockTimeout")
        showPasswordsByDefault = userDefaults.bool(forKey: "showPasswordsByDefault")
        enableClipboardClear = userDefaults.object(forKey: "enableClipboardClear") as? Bool ?? true
        clipboardClearTimeout = userDefaults.double(forKey: "clipboardClearTimeout").isZero ? 30 : userDefaults.double(forKey: "clipboardClearTimeout")
        
        // Load API key from keychain
        if let apiKeyData = keychainService.retrieveData(for: "apiKey") {
            apiKey = String(data: apiKeyData, encoding: .utf8) ?? ""
        }
    }
    
    private func saveSettings() {
        userDefaults.set(apiURL, forKey: "apiURL")
        userDefaults.set(syncEnabled, forKey: "syncEnabled")
        userDefaults.set(isDarkMode, forKey: "isDarkMode")
        userDefaults.set(autoSync, forKey: "autoSync")
        userDefaults.set(syncInterval, forKey: "syncInterval")
        userDefaults.set(passwordGeneratorLength, forKey: "passwordGeneratorLength")
        userDefaults.set(passwordIncludeUppercase, forKey: "passwordIncludeUppercase")
        userDefaults.set(passwordIncludeLowercase, forKey: "passwordIncludeLowercase")
        userDefaults.set(passwordIncludeNumbers, forKey: "passwordIncludeNumbers")
        userDefaults.set(passwordIncludeSymbols, forKey: "passwordIncludeSymbols")
        userDefaults.set(autoLockTimeout, forKey: "autoLockTimeout")
        userDefaults.set(showPasswordsByDefault, forKey: "showPasswordsByDefault")
        userDefaults.set(enableClipboardClear, forKey: "enableClipboardClear")
        userDefaults.set(clipboardClearTimeout, forKey: "clipboardClearTimeout")
        
        // Save API key to keychain
        if !apiKey.isEmpty {
            keychainService.storeData(Data(apiKey.utf8), for: "apiKey")
        }
    }
    
    // MARK: - API Configuration
    func updateAPISettings(url: String, key: String) {
        apiURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        saveSettings()
    }
    
    var isAPIConfigured: Bool {
        return !apiURL.isEmpty && !apiKey.isEmpty
    }
    
    func testAPIConnection() async -> Bool {
        guard isAPIConfigured else { return false }
        return await APIService.shared.testConnection()
    }
    
    // MARK: - Sync Settings
    func enableSync() {
        syncEnabled = true
        saveSettings()
        setupAutoSync()
    }
    
    func disableSync() {
        syncEnabled = false
        autoSync = false
        saveSettings()
        cancelAutoSync()
    }
    
    // MARK: - Auto Sync
    private var autoSyncTimer: Timer?
    
    private func setupAutoSync() {
        cancelAutoSync()
        
        guard autoSync && syncEnabled && isAPIConfigured else { return }
        
        autoSyncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { _ in
            Task {
                if let passwordService = try? PasswordService() {
                    await passwordService.syncWithServer()
                }
            }
        }
    }
    
    private func cancelAutoSync() {
        autoSyncTimer?.invalidate()
        autoSyncTimer = nil
    }
    
    func updateAutoSync(enabled: Bool, interval: TimeInterval) {
        autoSync = enabled
        syncInterval = interval
        saveSettings()
        
        if enabled {
            setupAutoSync()
        } else {
            cancelAutoSync()
        }
    }
    
    // MARK: - App Appearance
    func toggleDarkMode() {
        isDarkMode.toggle()
        saveSettings()
    }
    
    func setDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
        saveSettings()
    }
    
    // MARK: - Security Settings
    func updateAutoLockTimeout(_ timeout: TimeInterval) {
        autoLockTimeout = timeout
        saveSettings()
    }
    
    func updateBiometricSettings(_ enabled: Bool) {
        biometricEnabled = enabled
        saveSettings()
    }
    
    // MARK: - Password Generator Settings
    func updatePasswordGeneratorSettings(length: Int, uppercase: Bool, lowercase: Bool, numbers: Bool, symbols: Bool) {
        passwordGeneratorLength = max(4, min(128, length))
        passwordIncludeUppercase = uppercase
        passwordIncludeLowercase = lowercase
        passwordIncludeNumbers = numbers
        passwordIncludeSymbols = symbols
        saveSettings()
    }
    
    // MARK: - Clipboard Settings
    func updateClipboardSettings(enabled: Bool, timeout: TimeInterval) {
        enableClipboardClear = enabled
        clipboardClearTimeout = timeout
        saveSettings()
    }
    
    // MARK: - Privacy Settings
    func updateShowPasswordsDefault(_ show: Bool) {
        showPasswordsByDefault = show
        saveSettings()
    }
    
    // MARK: - Export/Import Settings
    func exportSettings() -> Data? {
        let settings: [String: Any] = [
            "apiURL": apiURL,
            "syncEnabled": syncEnabled,
            "isDarkMode": isDarkMode,
            "autoSync": autoSync,
            "syncInterval": syncInterval,
            "passwordGeneratorLength": passwordGeneratorLength,
            "passwordIncludeUppercase": passwordIncludeUppercase,
            "passwordIncludeLowercase": passwordIncludeLowercase,
            "passwordIncludeNumbers": passwordIncludeNumbers,
            "passwordIncludeSymbols": passwordIncludeSymbols,
            "autoLockTimeout": autoLockTimeout,
            "showPasswordsByDefault": showPasswordsByDefault,
            "enableClipboardClear": enableClipboardClear,
            "clipboardClearTimeout": clipboardClearTimeout
        ]
        
        do {
            return try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
        } catch {
            print("Failed to export settings: \(error)")
            return nil
        }
    }
    
    func importSettings(from data: Data) -> Bool {
        do {
            guard let settings = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return false
            }
            
            // Import non-sensitive settings only
            if let url = settings["apiURL"] as? String { apiURL = url }
            if let sync = settings["syncEnabled"] as? Bool { syncEnabled = sync }
            if let dark = settings["isDarkMode"] as? Bool { isDarkMode = dark }
            if let autoSyncValue = settings["autoSync"] as? Bool { autoSync = autoSyncValue }
            if let interval = settings["syncInterval"] as? TimeInterval { syncInterval = interval }
            if let length = settings["passwordGeneratorLength"] as? Int { passwordGeneratorLength = length }
            if let uppercase = settings["passwordIncludeUppercase"] as? Bool { passwordIncludeUppercase = uppercase }
            if let lowercase = settings["passwordIncludeLowercase"] as? Bool { passwordIncludeLowercase = lowercase }
            if let numbers = settings["passwordIncludeNumbers"] as? Bool { passwordIncludeNumbers = numbers }
            if let symbols = settings["passwordIncludeSymbols"] as? Bool { passwordIncludeSymbols = symbols }
            if let timeout = settings["autoLockTimeout"] as? TimeInterval { autoLockTimeout = timeout }
            if let showPasswords = settings["showPasswordsByDefault"] as? Bool { showPasswordsByDefault = showPasswords }
            if let clipboardClear = settings["enableClipboardClear"] as? Bool { enableClipboardClear = clipboardClear }
            if let clipboardTimeout = settings["clipboardClearTimeout"] as? TimeInterval { clipboardClearTimeout = clipboardTimeout }
            
            saveSettings()
            return true
        } catch {
            print("Failed to import settings: \(error)")
            return false
        }
    }
    
    // MARK: - Reset Settings
    func resetToDefaults() {
        // Clear sensitive data
        keychainService.deleteData(for: "apiKey")
        
        // Reset to defaults
        apiURL = ""
        apiKey = ""
        syncEnabled = false
        isDarkMode = false
        autoSync = false
        syncInterval = 3600
        passwordGeneratorLength = 16
        passwordIncludeUppercase = true
        passwordIncludeLowercase = true
        passwordIncludeNumbers = true
        passwordIncludeSymbols = true
        autoLockTimeout = 300
        showPasswordsByDefault = false
        enableClipboardClear = true
        clipboardClearTimeout = 30
        
        saveSettings()
        cancelAutoSync()
    }
    
    deinit {
        cancelAutoSync()
    }
}