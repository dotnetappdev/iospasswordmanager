import XCTest
@testable import iOSPasswordManager

final class DatabaseServiceTests: XCTestCase {
    var databaseService: DatabaseService!
    let testMasterKey = "TestMasterKey123!"
    
    override func setUp() {
        super.setUp()
        databaseService = DatabaseService.shared
        // Clear any existing test data
        _ = databaseService.clearAllPasswords()
    }
    
    override func tearDown() {
        // Clean up after tests
        _ = databaseService.clearAllPasswords()
        super.tearDown()
    }
    
    func testDatabaseCreation() {
        let info = databaseService.getDatabaseInfo()
        XCTAssertTrue(info["exists"] as? Bool ?? false, "Database should exist")
        XCTAssertEqual(info["password_count"] as? Int32 ?? -1, 0, "Database should be empty initially")
    }
    
    func testPasswordSaveAndLoad() {
        let testPassword = PasswordEntry(
            title: "Test Site",
            username: "testuser",
            password: "testpassword123",
            website: "https://test.com"
        )
        
        // Save password
        let saveResult = databaseService.savePassword(testPassword, masterKey: testMasterKey)
        XCTAssertTrue(saveResult, "Password should be saved successfully")
        
        // Load passwords
        let loadedPasswords = databaseService.loadAllPasswords(masterKey: testMasterKey)
        XCTAssertEqual(loadedPasswords.count, 1, "Should load exactly one password")
        
        let loadedPassword = loadedPasswords.first!
        XCTAssertEqual(loadedPassword.title, testPassword.title)
        XCTAssertEqual(loadedPassword.username, testPassword.username)
        XCTAssertEqual(loadedPassword.password, testPassword.password)
        XCTAssertEqual(loadedPassword.website, testPassword.website)
    }
    
    func testPasswordDelete() {
        let testPassword = PasswordEntry(
            title: "Test Site",
            username: "testuser",
            password: "testpassword123"
        )
        
        // Save password
        _ = databaseService.savePassword(testPassword, masterKey: testMasterKey)
        
        // Verify it's saved
        var passwords = databaseService.loadAllPasswords(masterKey: testMasterKey)
        XCTAssertEqual(passwords.count, 1)
        
        // Delete password
        let deleteResult = databaseService.deletePassword(id: testPassword.id.uuidString)
        XCTAssertTrue(deleteResult, "Password should be deleted successfully")
        
        // Verify it's deleted
        passwords = databaseService.loadAllPasswords(masterKey: testMasterKey)
        XCTAssertEqual(passwords.count, 0, "Password should be deleted")
    }
    
    func testMultiplePasswords() {
        let passwords = [
            PasswordEntry(title: "Site 1", username: "user1", password: "pass1"),
            PasswordEntry(title: "Site 2", username: "user2", password: "pass2"),
            PasswordEntry(title: "Site 3", username: "user3", password: "pass3")
        ]
        
        // Save all passwords
        for password in passwords {
            let result = databaseService.savePassword(password, masterKey: testMasterKey)
            XCTAssertTrue(result, "All passwords should be saved")
        }
        
        // Load all passwords
        let loadedPasswords = databaseService.loadAllPasswords(masterKey: testMasterKey)
        XCTAssertEqual(loadedPasswords.count, 3, "Should load all three passwords")
    }
    
    func testEncryptionWithWrongKey() {
        let testPassword = PasswordEntry(
            title: "Test Site",
            username: "testuser",
            password: "secretpassword"
        )
        
        // Save with correct key
        _ = databaseService.savePassword(testPassword, masterKey: testMasterKey)
        
        // Try to load with wrong key
        let wrongKeyPasswords = databaseService.loadAllPasswords(masterKey: "WrongKey123!")
        
        // Should not be able to decrypt with wrong key
        // The method should return empty array or passwords with failed decryption
        // (implementation might vary, but we shouldn't get the original password)
        for password in wrongKeyPasswords {
            XCTAssertNotEqual(password.password, "secretpassword", "Should not decrypt with wrong key")
        }
    }
}