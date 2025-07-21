import Foundation
import CryptoKit

struct PasswordEntry: Identifiable, Codable {
    let id = UUID()
    var title: String
    var username: String
    var password: String
    var website: String
    var createdDate: Date
    
    init(title: String, username: String, password: String, website: String = "") {
        self.title = title
        self.username = username
        self.password = password
        self.website = website
        self.createdDate = Date()
    }
}

@MainActor
class PasswordManager: ObservableObject {
    @Published var passwords: [PasswordEntry] = []
    @Published var isAuthenticated = false
    
    private var masterKey: String = ""
    private let keychainService = KeychainService.shared
    private let databaseService = DatabaseService.shared
    
    init() {
        // Initialize with empty state
    }
    
    func authenticateWithMasterKey(_ key: String) async -> Bool {
        // Validate master key format and strength
        guard isValidMasterKey(key) else {
            return false
        }
        
        // If this is the first time, store the master key
        if !keychainService.hasMasterKey() {
            keychainService.storeMasterKey(key)
        } else {
            // Verify against stored master key
            guard let storedKey = keychainService.getMasterKey(),
                  storedKey == key else {
                return false
            }
        }
        
        masterKey = key
        isAuthenticated = true
        
        // Load encrypted passwords
        await loadPasswords()
        
        return true
    }
    
    func addPassword(_ password: PasswordEntry) {
        if databaseService.savePassword(password, masterKey: masterKey) {
            passwords.append(password)
        } else {
            print("Failed to save password to database")
        }
    }
    
    func deletePassword(_ password: PasswordEntry) {
        if databaseService.deletePassword(id: password.id.uuidString) {
            passwords.removeAll { $0.id == password.id }
        } else {
            print("Failed to delete password from database")
        }
    }
    
    func updatePassword(_ password: PasswordEntry) {
        if databaseService.savePassword(password, masterKey: masterKey) {
            if let index = passwords.firstIndex(where: { $0.id == password.id }) {
                passwords[index] = password
            }
        } else {
            print("Failed to update password in database")
        }
    }
    
    func logout() {
        isAuthenticated = false
        masterKey = ""
        passwords.removeAll()
    }
    
    private func isValidMasterKey(_ key: String) -> Bool {
        // Basic validation - at least 8 characters
        return key.count >= 8
    }
    
    private func loadPasswords() async {
        // First try to migrate from Keychain if this is the first run with DatabaseService
        await migrateFromKeychainIfNeeded()
        
        // Load passwords from database
        passwords = databaseService.loadAllPasswords(masterKey: masterKey)
    }
    
    private func savePasswords() {
        // This method is no longer needed as passwords are saved directly to database
        // in addPassword, updatePassword methods. Keeping for backward compatibility.
        print("savePasswords() called - passwords are now saved directly to database")
    }
    
    private func encryptData(_ data: Data, with key: String) -> Data? {
        guard let keyData = key.data(using: .utf8) else { return nil }
        
        // Generate a symmetric key from the master key
        let hashedKey = SHA256.hash(data: keyData)
        let symmetricKey = SymmetricKey(data: hashedKey)
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    private func decryptData(_ encryptedData: Data, with key: String) -> Data? {
        guard let keyData = key.data(using: .utf8) else { return nil }
        
        // Generate the same symmetric key from the master key
        let hashedKey = SHA256.hash(data: keyData)
        let symmetricKey = SymmetricKey(data: hashedKey)
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Migration Methods
    
    private func migrateFromKeychainIfNeeded() async {
        // Check if we have data in Keychain but no data in database
        guard keychainService.getEncryptedPasswords() != nil else {
            return // No data to migrate
        }
        
        let databasePasswords = databaseService.loadAllPasswords(masterKey: masterKey)
        guard databasePasswords.isEmpty else {
            return // Database already has data, no migration needed
        }
        
        print("Migrating passwords from Keychain to Database...")
        
        // Load passwords from Keychain using the old method
        guard let encryptedData = keychainService.getEncryptedPasswords(),
              let decryptedData = decryptData(encryptedData, with: masterKey) else {
            print("Failed to decrypt Keychain data for migration")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let keychainPasswords = try decoder.decode([PasswordEntry].self, from: decryptedData)
            
            // Save each password to the database
            var migratedCount = 0
            for password in keychainPasswords {
                if databaseService.savePassword(password, masterKey: masterKey) {
                    migratedCount += 1
                }
            }
            
            if migratedCount == keychainPasswords.count {
                print("Successfully migrated \(migratedCount) passwords to database")
                // Clear the old Keychain data after successful migration
                keychainService.deleteEncryptedPasswords()
            } else {
                print("Migration incomplete: migrated \(migratedCount) of \(keychainPasswords.count) passwords")
            }
        } catch {
            print("Failed to decode Keychain passwords for migration: \(error)")
        }
    }
    
    // MARK: - Database Management
    
    func getDatabaseInfo() -> [String: Any] {
        return databaseService.getDatabaseInfo()
    }
    
    func vacuumDatabase() {
        databaseService.vacuum()
    }
    
    func clearAllData() {
        databaseService.clearAllPasswords()
        keychainService.clearAllData()
        passwords.removeAll()
        logout()
    }
    
    // MARK: - Utility Functions
    
    func generateStrongPassword(length: Int = 16) -> String {
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let special = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        
        let allCharacters = lowercase + uppercase + numbers + special
        
        var password = ""
        
        // Ensure at least one character from each category
        password += String(lowercase.randomElement()!)
        password += String(uppercase.randomElement()!)
        password += String(numbers.randomElement()!)
        password += String(special.randomElement()!)
        
        // Fill the rest randomly
        for _ in 4..<length {
            password += String(allCharacters.randomElement()!)
        }
        
        // Shuffle the password
        return String(password.shuffled())
    }
    
    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
}