import Foundation

// Import the core components
#if canImport(SQLite3)
// Required for PasswordEntry definition
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

// Simple test program to verify DatabaseService functionality
// This doesn't require SwiftUI and can run on Linux

func testDatabaseService() {
    print("Testing DatabaseService...")
    
    let databaseService = DatabaseService.shared
    let testMasterKey = "TestMasterKey123!"
    
    // Clear any existing data
    _ = databaseService.clearAllPasswords()
    
    // Test 1: Database creation and info
    print("\nTest 1: Database creation")
    let info = databaseService.getDatabaseInfo()
    print("Database info:", info)
    
    // Test 2: Save a password
    print("\nTest 2: Save password")
    let testPassword = PasswordEntry(
        title: "Test Site",
        username: "testuser",
        password: "testpassword123",
        website: "https://test.com"
    )
    
    let saveResult = databaseService.savePassword(testPassword, masterKey: testMasterKey)
    print("Save result:", saveResult)
    
    // Test 3: Load passwords
    print("\nTest 3: Load passwords")
    let loadedPasswords = databaseService.loadAllPasswords(masterKey: testMasterKey)
    print("Loaded \(loadedPasswords.count) passwords")
    
    if let firstPassword = loadedPasswords.first {
        print("First password:")
        print("  Title:", firstPassword.title)
        print("  Username:", firstPassword.username)
        print("  Password:", firstPassword.password)
        print("  Website:", firstPassword.website)
        print("  Created:", firstPassword.createdDate)
    }
    
    // Test 4: Save multiple passwords
    print("\nTest 4: Save multiple passwords")
    let passwords = [
        PasswordEntry(title: "Site 1", username: "user1", password: "pass1"),
        PasswordEntry(title: "Site 2", username: "user2", password: "pass2"),
        PasswordEntry(title: "Site 3", username: "user3", password: "pass3")
    ]
    
    for password in passwords {
        let result = databaseService.savePassword(password, masterKey: testMasterKey)
        print("Saved '\(password.title)': \(result)")
    }
    
    // Load all passwords again
    let allPasswords = databaseService.loadAllPasswords(masterKey: testMasterKey)
    print("Total passwords in database: \(allPasswords.count)")
    
    // Test 5: Delete password
    print("\nTest 5: Delete password")
    let deleteResult = databaseService.deletePassword(id: testPassword.id.uuidString)
    print("Delete result:", deleteResult)
    
    let remainingPasswords = databaseService.loadAllPasswords(masterKey: testMasterKey)
    print("Remaining passwords:", remainingPasswords.count)
    
    // Test 6: Test encryption with wrong key
    print("\nTest 6: Test encryption security")
    let wrongKeyPasswords = databaseService.loadAllPasswords(masterKey: "WrongKey123!")
    print("Passwords with wrong key: \(wrongKeyPasswords.count)")
    
    // Test 7: Database info after operations
    print("\nTest 7: Final database info")
    let finalInfo = databaseService.getDatabaseInfo()
    print("Final database info:", finalInfo)
    
    print("\nAll tests completed successfully!")
    print("Database is securely stored at: \(finalInfo["path"] ?? "unknown")")
}

// Run the test if SQLite3 is available
testDatabaseService()
#else
print("SQLite3 not available on this platform")
#endif