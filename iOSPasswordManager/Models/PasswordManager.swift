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
        passwords.append(password)
        savePasswords()
    }
    
    func deletePassword(_ password: PasswordEntry) {
        passwords.removeAll { $0.id == password.id }
        savePasswords()
    }
    
    func updatePassword(_ password: PasswordEntry) {
        if let index = passwords.firstIndex(where: { $0.id == password.id }) {
            passwords[index] = password
            savePasswords()
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
        guard let encryptedData = keychainService.getEncryptedPasswords(),
              let decryptedData = decryptData(encryptedData, with: masterKey) else {
            // No passwords stored yet or decryption failed
            passwords = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            passwords = try decoder.decode([PasswordEntry].self, from: decryptedData)
        } catch {
            print("Failed to decode passwords: \(error)")
            passwords = []
        }
    }
    
    private func savePasswords() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(passwords)
            
            guard let encryptedData = encryptData(data, with: masterKey) else {
                print("Failed to encrypt passwords")
                return
            }
            
            keychainService.storeEncryptedPasswords(encryptedData)
        } catch {
            print("Failed to encode passwords: \(error)")
        }
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