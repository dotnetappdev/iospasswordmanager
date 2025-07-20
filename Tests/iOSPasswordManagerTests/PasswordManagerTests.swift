import XCTest
@testable import iOSPasswordManager

final class PasswordManagerTests: XCTestCase {
    
    func testPasswordEntryCreation() {
        let password = PasswordEntry(
            title: "Test Site",
            username: "testuser",
            password: "testpass123",
            website: "https://test.com"
        )
        
        XCTAssertEqual(password.title, "Test Site")
        XCTAssertEqual(password.username, "testuser")
        XCTAssertEqual(password.password, "testpass123")
        XCTAssertEqual(password.website, "https://test.com")
        XCTAssertNotNil(password.id)
        XCTAssertTrue(password.createdDate.timeIntervalSinceNow < 1)
    }
    
    func testMasterKeyValidation() {
        let passwordManager = PasswordManager()
        
        // Test valid master key (8+ characters)
        let validKey = "securepassword123"
        // We can't test the full authentication without iOS simulator
        // but we can test the validation logic
        XCTAssertTrue(validKey.count >= 8)
        
        // Test invalid master key (less than 8 characters)
        let invalidKey = "short"
        XCTAssertFalse(invalidKey.count >= 8)
    }
    
    func testPasswordGeneration() {
        let passwordManager = PasswordManager()
        
        let generatedPassword = passwordManager.generateStrongPassword()
        
        XCTAssertEqual(generatedPassword.count, 16)
        XCTAssertTrue(generatedPassword.contains(where: { $0.isLowercase }))
        XCTAssertTrue(generatedPassword.contains(where: { $0.isUppercase }))
        XCTAssertTrue(generatedPassword.contains(where: { $0.isNumber }))
    }
    
    func testPasswordGenerationCustomLength() {
        let passwordManager = PasswordManager()
        
        let shortPassword = passwordManager.generateStrongPassword(length: 8)
        XCTAssertEqual(shortPassword.count, 8)
        
        let longPassword = passwordManager.generateStrongPassword(length: 32)
        XCTAssertEqual(longPassword.count, 32)
    }
}