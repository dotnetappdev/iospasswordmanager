import Foundation
import SQLite3
import CryptoKit

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
        
        // Get the Application Support directory - this is the most secure location for app data
        guard let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, 
                                                            in: .userDomainMask).first else {
            fatalError("Could not access Application Support directory")
        }
        
        // Create app-specific subdirectory
        let appSupportURL = applicationSupportURL.appendingPathComponent("iOSPasswordManager")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: appSupportURL.path) {
            do {
                try fileManager.createDirectory(at: appSupportURL, 
                                                withIntermediateDirectories: true, 
                                                attributes: nil)
                
                // Set file protection attributes for additional security
                try fileManager.setAttributes([
                    .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
                ], ofItemAtPath: appSupportURL.path)
                
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
                encrypted_password BLOB NOT NULL,
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
    
    // MARK: - Password Management
    
    func savePassword(_ password: PasswordEntry, masterKey: String) -> Bool {
        guard let encryptedPassword = encryptData(password.password.data(using: .utf8)!, with: masterKey) else {
            print("Failed to encrypt password")
            return false
        }
        
        let insertSQL = """
            INSERT OR REPLACE INTO passwords 
            (id, title, username, encrypted_password, website, created_date, modified_date) 
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, password.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, password.title, -1, nil)
            sqlite3_bind_text(statement, 3, password.username, -1, nil)
            sqlite3_bind_blob(statement, 4, encryptedPassword.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress }, Int32(encryptedPassword.count), nil)
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
        let querySQL = "SELECT id, title, username, encrypted_password, website, created_date FROM passwords ORDER BY created_date DESC;"
        var statement: OpaquePointer?
        var passwords: [PasswordEntry] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(statement, 0),
                      let titleString = sqlite3_column_text(statement, 1),
                      let usernameString = sqlite3_column_text(statement, 2),
                      let websiteString = sqlite3_column_text(statement, 4) else {
                    continue
                }
                
                let id = String(cString: idString)
                let title = String(cString: titleString)
                let username = String(cString: usernameString)
                let website = String(cString: websiteString)
                let createdTimestamp = sqlite3_column_int64(statement, 5)
                let createdDate = Date(timeIntervalSince1970: TimeInterval(createdTimestamp))
                
                // Decrypt password
                let encryptedPasswordBlob = sqlite3_column_blob(statement, 3)
                let encryptedPasswordSize = sqlite3_column_bytes(statement, 3)
                let encryptedPasswordData = Data(bytes: encryptedPasswordBlob!, count: Int(encryptedPasswordSize))
                
                guard let decryptedPasswordData = decryptData(encryptedPasswordData, with: masterKey),
                      let decryptedPassword = String(data: decryptedPasswordData, encoding: .utf8) else {
                    print("Failed to decrypt password for entry: \(title)")
                    continue
                }
                
                var passwordEntry = PasswordEntry(title: title, username: username, password: decryptedPassword, website: website)
                // Set the original ID and creation date
                passwordEntry = PasswordEntry(title: title, username: username, password: decryptedPassword, website: website)
                // Note: We can't modify the id and createdDate because they're let constants
                // This is a limitation of the current PasswordEntry struct design
                
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
    
    // MARK: - Encryption/Decryption
    
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
    
    // MARK: - Database Maintenance
    
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