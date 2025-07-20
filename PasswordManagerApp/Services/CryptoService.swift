import Foundation
import CryptoKit
import Security

class CryptoService {
    static let shared = CryptoService()
    
    private init() {}
    
    // MARK: - Password Hashing
    func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hash = SHA256.hash(data: inputData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Database Encryption Key
    func getDatabaseKey() -> String {
        // Generate or retrieve a consistent key for database encryption
        let keyIdentifier = "com.passwordmanager.database.key"
        
        if let existingKey = KeychainService().retrieveData(for: keyIdentifier) {
            return String(data: existingKey, encoding: .utf8) ?? generateNewDatabaseKey()
        } else {
            let newKey = generateNewDatabaseKey()
            KeychainService().storeData(Data(newKey.utf8), for: keyIdentifier)
            return newKey
        }
    }
    
    private func generateNewDatabaseKey() -> String {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0).base64EncodedString() }
    }
    
    // MARK: - Password Generation
    func generatePassword(length: Int = 16, includeUppercase: Bool = true, includeLowercase: Bool = true, includeNumbers: Bool = true, includeSymbols: Bool = true) -> String {
        var characters = ""
        
        if includeUppercase {
            characters += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        }
        if includeLowercase {
            characters += "abcdefghijklmnopqrstuvwxyz"
        }
        if includeNumbers {
            characters += "0123456789"
        }
        if includeSymbols {
            characters += "!@#$%^&*()_+-=[]{}|;:,.<>?"
        }
        
        guard !characters.isEmpty else { return "" }
        
        var password = ""
        for _ in 0..<length {
            let randomIndex = Int.random(in: 0..<characters.count)
            let character = characters[characters.index(characters.startIndex, offsetBy: randomIndex)]
            password.append(character)
        }
        
        return password
    }
    
    // MARK: - Data Encryption/Decryption
    func encrypt(_ data: Data, using password: String) throws -> Data {
        let key = SymmetricKey(data: SHA256.hash(data: Data(password.utf8)))
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decrypt(_ encryptedData: Data, using password: String) throws -> Data {
        let key = SymmetricKey(data: SHA256.hash(data: Data(password.utf8)))
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Password Strength Analysis
    func calculatePasswordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        var feedback: [String] = []
        
        // Length check
        if password.count >= 12 {
            score += 2
        } else if password.count >= 8 {
            score += 1
        } else {
            feedback.append("Use at least 8 characters")
        }
        
        // Character variety checks
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumbers = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSymbols = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        if hasUppercase { score += 1 } else { feedback.append("Add uppercase letters") }
        if hasLowercase { score += 1 } else { feedback.append("Add lowercase letters") }
        if hasNumbers { score += 1 } else { feedback.append("Add numbers") }
        if hasSymbols { score += 1 } else { feedback.append("Add symbols") }
        
        // Common patterns check
        if isCommonPassword(password) {
            score -= 2
            feedback.append("Avoid common passwords")
        }
        
        // Determine strength level
        let strength: PasswordStrengthLevel
        switch score {
        case 0...2:
            strength = .weak
        case 3...4:
            strength = .fair
        case 5...6:
            strength = .good
        default:
            strength = .strong
        }
        
        return PasswordStrength(level: strength, score: score, feedback: feedback)
    }
    
    private func isCommonPassword(_ password: String) -> Bool {
        let commonPasswords = [
            "password", "123456", "123456789", "qwerty", "abc123",
            "password123", "admin", "letmein", "welcome", "monkey"
        ]
        return commonPasswords.contains(password.lowercased())
    }
}

struct PasswordStrength {
    let level: PasswordStrengthLevel
    let score: Int
    let feedback: [String]
}

enum PasswordStrengthLevel: CaseIterable {
    case weak, fair, good, strong
    
    var color: String {
        switch self {
        case .weak: return "red"
        case .fair: return "orange"
        case .good: return "yellow"
        case .strong: return "green"
        }
    }
    
    var description: String {
        switch self {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }
}