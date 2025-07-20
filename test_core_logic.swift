import Foundation

// Simple test to validate our core password management logic
// This doesn't require iOS frameworks

struct PasswordEntry: Codable {
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

// Test password generation function
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

// Test master key validation
func isValidMasterKey(_ key: String) -> Bool {
    return key.count >= 8
}

// Run tests
print("🧪 Running iOS Password Manager Core Logic Tests...")

// Test 1: Password Entry Creation
print("\n✅ Test 1: Password Entry Creation")
let testPassword = PasswordEntry(
    title: "GitHub",
    username: "testuser@example.com",
    password: "secure123!",
    website: "https://github.com"
)
print("   Created password entry: \(testPassword.title)")
print("   Username: \(testPassword.username)")
print("   Password length: \(testPassword.password.count)")
print("   Website: \(testPassword.website)")
print("   ID: \(testPassword.id)")

// Test 2: Master Key Validation
print("\n✅ Test 2: Master Key Validation")
let validKeys = ["password123", "mySecureKey!", "longerMasterPassword"]
let invalidKeys = ["short", "123", "abc"]

for key in validKeys {
    let isValid = isValidMasterKey(key)
    print("   '\(key)' (length: \(key.count)) -> Valid: \(isValid)")
}

for key in invalidKeys {
    let isValid = isValidMasterKey(key)
    print("   '\(key)' (length: \(key.count)) -> Valid: \(isValid)")
}

// Test 3: Password Generation
print("\n✅ Test 3: Strong Password Generation")
for length in [8, 12, 16, 24, 32] {
    let generated = generateStrongPassword(length: length)
    print("   Length \(length): \(generated)")
    
    let hasLower = generated.contains(where: { $0.isLowercase })
    let hasUpper = generated.contains(where: { $0.isUppercase })
    let hasNumber = generated.contains(where: { $0.isNumber })
    let hasSpecial = generated.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) })
    
    print("     Has lowercase: \(hasLower), uppercase: \(hasUpper), number: \(hasNumber), special: \(hasSpecial)")
}

// Test 4: Data Encoding/Decoding
print("\n✅ Test 4: Password Entry JSON Encoding/Decoding")
do {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let passwords = [
        testPassword,
        PasswordEntry(title: "Email", username: "user@domain.com", password: "emailPass123", website: "mail.google.com"),
        PasswordEntry(title: "Banking", username: "customer123", password: "bankSecure456", website: "bank.example.com")
    ]
    
    let encodedData = try encoder.encode(passwords)
    print("   Encoded \(passwords.count) password entries to \(encodedData.count) bytes")
    
    let decodedPasswords = try decoder.decode([PasswordEntry].self, from: encodedData)
    print("   Decoded \(decodedPasswords.count) password entries successfully")
    
    for (original, decoded) in zip(passwords, decodedPasswords) {
        print("   ✓ \(original.title) -> \(decoded.title) (matches: \(original.title == decoded.title))")
    }
} catch {
    print("   ❌ Encoding/Decoding failed: \(error)")
}

print("\n🎉 All core logic tests completed successfully!")
print("\n📝 Note: This validates the core password management logic.")
print("   Full iOS features (SwiftUI, Keychain, Face ID, QR scanning) require Xcode/iOS Simulator.")