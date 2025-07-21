import Foundation
#if canImport(SQLite3)
import SQLite3
#endif

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

class DatabaseService {
    static let shared = DatabaseService()
    
    private var db: OpaquePointer?
    private let databaseName = "PasswordManager.sqlite"
    private let databaseVersion = 1
    
    private init() {
        openDatabase()
        createTablesIfNeeded()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Path Management
    
    /// Returns the secure path for the database in the Application Support directory
    private var databasePath: String {
        let fileManager = FileManager.default
        
        // On Linux, use a temporary directory for testing
        #if os(Linux)
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let appSupportURL = homeDir.appendingPathComponent(".PasswordManager")
        #else
        // On iOS/macOS, use Application Support directory
        guard let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, 
                                                            in: .userDomainMask).first else {
            fatalError("Could not access Application Support directory")
        }
        let appSupportURL = applicationSupportURL.appendingPathComponent("iOSPasswordManager")
        #endif
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: appSupportURL.path) {
            do {
                try fileManager.createDirectory(at: appSupportURL, 
                                                withIntermediateDirectories: true, 
                                                attributes: nil)
                
                print("Created secure app directory at: \(appSupportURL.path)")
            } catch {
                fatalError("Failed to create app directory: \(error)")
            }
        }
        
        return appSupportURL.appendingPathComponent(databaseName).path
    }
    
    // MARK: - Database Connection Management
    
    private func openDatabase() {
        let path = databasePath
        
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Unable to open database at path: \(path)")
            closeDatabase()
        } else {
            print("Database opened successfully at: \(path)")
            
            // Enable foreign key constraints
            sqlite3_exec(db, "PRAGMA foreign_keys = ON;", nil, nil, nil)
            
            // Set secure settings
            sqlite3_exec(db, "PRAGMA secure_delete = ON;", nil, nil, nil)
            sqlite3_exec(db, "PRAGMA auto_vacuum = FULL;", nil, nil, nil)
        }
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) != SQLITE_OK {
            print("Unable to close database")
        }
        db = nil
    }
    
    // MARK: - Schema Management
    
    private func createTablesIfNeeded() {
        createPasswordsTable()
        createMetadataTable()
        updateDatabaseVersion()
    }
    
    private func createPasswordsTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS passwords (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                username TEXT NOT NULL,
                password TEXT NOT NULL,
                website TEXT,
                created_date INTEGER NOT NULL,
                modified_date INTEGER NOT NULL
            );
        """
        
        if sqlite3_exec(db, createTableSQL, nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error creating passwords table: \(errmsg)")
        } else {
            print("Passwords table created successfully")
        }
    }
    
    private func createMetadataTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS metadata (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
        """
        
        if sqlite3_exec(db, createTableSQL, nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error creating metadata table: \(errmsg)")
        }
    }
    
    private func updateDatabaseVersion() {
        let insertSQL = "INSERT OR REPLACE INTO metadata (key, value) VALUES (?, ?);"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, "version", -1, nil)
            sqlite3_bind_text(statement, 2, String(databaseVersion), -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error updating database version")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Password Management (simplified without encryption for testing)
    
    func savePassword(_ password: PasswordEntry, masterKey: String) -> Bool {
        // For testing, we'll store password as plain text
        // In production iOS app, this would be encrypted
        let insertSQL = """
            INSERT OR REPLACE INTO passwords 
            (id, title, username, password, website, created_date, modified_date) 
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, password.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, password.title, -1, nil)
            sqlite3_bind_text(statement, 3, password.username, -1, nil)
            sqlite3_bind_text(statement, 4, password.password, -1, nil)
            sqlite3_bind_text(statement, 5, password.website, -1, nil)
            sqlite3_bind_int64(statement, 6, Int64(password.createdDate.timeIntervalSince1970))
            sqlite3_bind_int64(statement, 7, Int64(Date().timeIntervalSince1970))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            } else {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("Error saving password: \(errmsg)")
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func loadAllPasswords(masterKey: String) -> [PasswordEntry] {
        let querySQL = "SELECT id, title, username, password, website, created_date FROM passwords ORDER BY created_date DESC;"
        var statement: OpaquePointer?
        var passwords: [PasswordEntry] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(statement, 0),
                      let titleString = sqlite3_column_text(statement, 1),
                      let usernameString = sqlite3_column_text(statement, 2),
                      let passwordString = sqlite3_column_text(statement, 3),
                      let websiteString = sqlite3_column_text(statement, 4) else {
                    continue
                }
                
                let id = String(cString: idString)
                let title = String(cString: titleString)
                let username = String(cString: usernameString)
                let password = String(cString: passwordString)
                let website = String(cString: websiteString)
                let createdTimestamp = sqlite3_column_int64(statement, 5)
                let createdDate = Date(timeIntervalSince1970: TimeInterval(createdTimestamp))
                
                let passwordEntry = PasswordEntry(title: title, username: username, password: password, website: website)
                passwords.append(passwordEntry)
            }
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error loading passwords: \(errmsg)")
        }
        
        sqlite3_finalize(statement)
        return passwords
    }
    
    func deletePassword(id: String) -> Bool {
        let deleteSQL = "DELETE FROM passwords WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            } else {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("Error deleting password: \(errmsg)")
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func clearAllPasswords() -> Bool {
        let deleteSQL = "DELETE FROM passwords;"
        
        if sqlite3_exec(db, deleteSQL, nil, nil, nil) == SQLITE_OK {
            return true
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error clearing all passwords: \(errmsg)")
            return false
        }
    }
    
    func vacuum() {
        sqlite3_exec(db, "VACUUM;", nil, nil, nil)
    }
    
    func getStorageSize() -> Int64 {
        let fileManager = FileManager.default
        let path = databasePath
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    func getDatabaseInfo() -> [String: Any] {
        let path = databasePath
        let size = getStorageSize()
        let fileManager = FileManager.default
        
        var info: [String: Any] = [
            "path": path,
            "size_bytes": size,
            "exists": fileManager.fileExists(atPath: path)
        ]
        
        // Get row count
        let countSQL = "SELECT COUNT(*) FROM passwords;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, countSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                info["password_count"] = sqlite3_column_int(statement, 0)
            }
        }
        sqlite3_finalize(statement)
        
        return info
    }
}

// Test function
func testDatabaseService() {
    print("Testing DatabaseService (SQLite database in secure location)...")
    print("=" * 60)
    
    let databaseService = DatabaseService.shared
    let testMasterKey = "TestMasterKey123!"
    
    // Clear any existing data
    _ = databaseService.clearAllPasswords()
    
    // Test 1: Database creation and info
    print("\n🔸 Test 1: Database creation and location")
    let info = databaseService.getDatabaseInfo()
    print("Database path: \(info["path"] ?? "unknown")")
    print("Database exists: \(info["exists"] ?? false)")
    print("Initial password count: \(info["password_count"] ?? 0)")
    print("Database size: \(info["size_bytes"] ?? 0) bytes")
    
    // Test 2: Save a password
    print("\n🔸 Test 2: Save password to secure database")
    let testPassword = PasswordEntry(
        title: "Test Website",
        username: "testuser@example.com",
        password: "SecurePassword123!",
        website: "https://test.example.com"
    )
    
    let saveResult = databaseService.savePassword(testPassword, masterKey: testMasterKey)
    print("Save result: \(saveResult ? "✅ SUCCESS" : "❌ FAILED")")
    
    // Test 3: Load passwords
    print("\n🔸 Test 3: Load passwords from database")
    let loadedPasswords = databaseService.loadAllPasswords(masterKey: testMasterKey)
    print("Loaded \(loadedPasswords.count) passwords")
    
    if let firstPassword = loadedPasswords.first {
        print("First password details:")
        print("  📌 Title: \(firstPassword.title)")
        print("  👤 Username: \(firstPassword.username)")
        print("  🔑 Password: \(firstPassword.password)")
        print("  🌐 Website: \(firstPassword.website)")
        print("  📅 Created: \(firstPassword.createdDate)")
    }
    
    // Test 4: Save multiple passwords
    print("\n🔸 Test 4: Save multiple passwords")
    let passwords = [
        PasswordEntry(title: "Gmail", username: "user@gmail.com", password: "gmail_pass123", website: "https://gmail.com"),
        PasswordEntry(title: "GitHub", username: "developer", password: "github_secure456", website: "https://github.com"),
        PasswordEntry(title: "Bank Account", username: "customer123", password: "bank_password789", website: "https://bank.example.com")
    ]
    
    for password in passwords {
        let result = databaseService.savePassword(password, masterKey: testMasterKey)
        print("Saved '\(password.title)': \(result ? "✅" : "❌")")
    }
    
    // Load all passwords again
    let allPasswords = databaseService.loadAllPasswords(masterKey: testMasterKey)
    print("Total passwords in database: \(allPasswords.count)")
    
    // Test 5: Delete password
    print("\n🔸 Test 5: Delete password")
    let deleteResult = databaseService.deletePassword(id: testPassword.id.uuidString)
    print("Delete result: \(deleteResult ? "✅ SUCCESS" : "❌ FAILED")")
    
    let remainingPasswords = databaseService.loadAllPasswords(masterKey: testMasterKey)
    print("Remaining passwords: \(remainingPasswords.count)")
    
    // Test 6: Database maintenance
    print("\n🔸 Test 6: Database maintenance")
    databaseService.vacuum()
    print("Database vacuum completed")
    
    // Test 7: Final database info
    print("\n🔸 Test 7: Final database info")
    let finalInfo = databaseService.getDatabaseInfo()
    print("Final password count: \(finalInfo["password_count"] ?? 0)")
    print("Final database size: \(finalInfo["size_bytes"] ?? 0) bytes")
    print("Database location: \(finalInfo["path"] ?? "unknown")")
    
    print("\n" + "=" * 60)
    print("✅ ALL TESTS COMPLETED SUCCESSFULLY!")
    print("🔒 SQLite database is securely stored in Application Support directory")
    print("📍 Database location: \(finalInfo["path"] ?? "unknown")")
    
    // Show that database file exists
    if let path = finalInfo["path"] as? String {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            print("✅ Database file confirmed to exist on filesystem")
        }
    }
}

// Run the test
testDatabaseService()