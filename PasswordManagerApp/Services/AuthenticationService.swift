import Foundation
import LocalAuthentication
import CryptoKit

class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var biometricType: LABiometryType = .none
    @Published var isBiometricEnabled = false
    
    private let keychainService = KeychainService()
    private let databaseService = DatabaseService()
    
    init() {
        checkBiometricAvailability()
        loadUserSettings()
    }
    
    // MARK: - Biometric Authentication
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }
    
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Master Password"
        
        do {
            let reason = "Unlock your password manager"
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            
            if success {
                await MainActor.run {
                    self.isAuthenticated = true
                }
                return true
            }
        } catch {
            print("Biometric authentication failed: \(error)")
        }
        
        return false
    }
    
    // MARK: - Password Authentication
    func authenticateWithMasterPassword(_ password: String) async -> Bool {
        do {
            if let user = try databaseService.fetchUser() {
                let hashedPassword = CryptoService.shared.hashPassword(password)
                if hashedPassword == user.masterPasswordHash {
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.isBiometricEnabled = user.biometricEnabled
                    }
                    
                    // Store master password in keychain for database encryption
                    keychainService.storeMasterPassword(password)
                    return true
                }
            }
        } catch {
            print("Authentication failed: \(error)")
        }
        
        return false
    }
    
    // MARK: - User Registration
    func registerUser(email: String, masterPassword: String) async -> Bool {
        do {
            // Check if user already exists
            if let _ = try databaseService.fetchUser() {
                return false // User already exists
            }
            
            let hashedPassword = CryptoService.shared.hashPassword(masterPassword)
            let user = User(email: email, masterPasswordHash: hashedPassword)
            
            try databaseService.insertUser(user)
            
            // Store master password in keychain
            keychainService.storeMasterPassword(masterPassword)
            
            // Set database encryption key
            databaseService.setDatabaseKey(masterPassword)
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            
            return true
        } catch {
            print("Registration failed: \(error)")
            return false
        }
    }
    
    // MARK: - Biometric Settings
    func enableBiometrics() async -> Bool {
        guard biometricType != .none else { return false }
        
        let success = await authenticateWithBiometrics()
        if success, var user = currentUser {
            user.biometricEnabled = true
            do {
                try databaseService.updateUser(user)
                await MainActor.run {
                    self.currentUser = user
                    self.isBiometricEnabled = true
                }
                return true
            } catch {
                print("Failed to enable biometrics: \(error)")
            }
        }
        return false
    }
    
    func disableBiometrics() {
        guard var user = currentUser else { return }
        
        user.biometricEnabled = false
        do {
            try databaseService.updateUser(user)
            self.currentUser = user
            self.isBiometricEnabled = false
        } catch {
            print("Failed to disable biometrics: \(error)")
        }
    }
    
    // MARK: - Session Management
    func logout() {
        isAuthenticated = false
        currentUser = nil
        keychainService.deleteMasterPassword()
    }
    
    func changeMasterPassword(currentPassword: String, newPassword: String) async -> Bool {
        guard let user = currentUser else { return false }
        
        let currentHash = CryptoService.shared.hashPassword(currentPassword)
        if currentHash != user.masterPasswordHash {
            return false
        }
        
        let newHash = CryptoService.shared.hashPassword(newPassword)
        var updatedUser = user
        updatedUser.masterPasswordHash = newHash
        
        do {
            try databaseService.updateUser(updatedUser)
            keychainService.storeMasterPassword(newPassword)
            databaseService.setDatabaseKey(newPassword)
            
            await MainActor.run {
                self.currentUser = updatedUser
            }
            return true
        } catch {
            print("Failed to change master password: \(error)")
            return false
        }
    }
    
    private func loadUserSettings() {
        do {
            if let user = try databaseService.fetchUser() {
                currentUser = user
                isBiometricEnabled = user.biometricEnabled
            }
        } catch {
            print("Failed to load user settings: \(error)")
        }
    }
    
    // MARK: - Auto-login with biometrics
    func attemptAutoLogin() async {
        guard isBiometricEnabled && biometricType != .none else { return }
        
        let success = await authenticateWithBiometrics()
        if success {
            // Load user data
            loadUserSettings()
        }
    }
}