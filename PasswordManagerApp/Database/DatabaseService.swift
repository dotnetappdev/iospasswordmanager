import Foundation
import SQLite

class DatabaseService: ObservableObject {
    private var db: Connection?
    private let passwords = Table("passwords")
    private let categories = Table("categories")
    private let user = Table("user")
    
    // Password table columns
    private let passwordId = Expression<String>("id")
    private let passwordTitle = Expression<String>("title")
    private let passwordUsername = Expression<String>("username")
    private let passwordPassword = Expression<String>("password")
    private let passwordWebsite = Expression<String>("website")
    private let passwordNotes = Expression<String>("notes")
    private let passwordCategoryId = Expression<String?>("category_id")
    private let passwordIsFavorite = Expression<Bool>("is_favorite")
    private let passwordCreatedAt = Expression<Date>("created_at")
    private let passwordModifiedAt = Expression<Date>("modified_at")
    private let passwordSyncedAt = Expression<Date?>("synced_at")
    
    // Category table columns
    private let categoryId = Expression<String>("id")
    private let categoryName = Expression<String>("name")
    private let categoryIcon = Expression<String>("icon")
    private let categoryColor = Expression<String>("color")
    private let categoryCreatedAt = Expression<Date>("created_at")
    private let categoryModifiedAt = Expression<Date>("modified_at")
    private let categorySyncedAt = Expression<Date?>("synced_at")
    
    // User table columns
    private let userId = Expression<String>("id")
    private let userEmail = Expression<String>("email")
    private let userMasterPasswordHash = Expression<String>("master_password_hash")
    private let userBiometricEnabled = Expression<Bool>("biometric_enabled")
    private let userSyncEnabled = Expression<Bool>("sync_enabled")
    private let userLastSyncAt = Expression<Date?>("last_sync_at")
    
    init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = documentsPath.appendingPathComponent("PasswordManager.sqlite3").path
            
            // Initialize connection with SQLCipher
            db = try Connection(dbPath)
            
            // Enable SQLCipher with a key derived from device keychain
            let encryptionKey = CryptoService.shared.getDatabaseKey()
            try db?.execute("PRAGMA key = '\(encryptionKey)'")
            
            // Test the database connection
            try db?.execute("SELECT count(*) FROM sqlite_master")
            
            createTables()
        } catch {
            print("Database connection failed: \(error)")
        }
    }
    
    func setDatabaseKey(_ key: String) {
        do {
            try db?.execute("PRAGMA rekey = '\(key)'")
        } catch {
            print("Failed to set database key: \(error)")
        }
    }
    
    private func createTables() {
        do {
            // Create categories table
            try db?.run(categories.create(ifNotExists: true) { t in
                t.column(categoryId, primaryKey: true)
                t.column(categoryName)
                t.column(categoryIcon)
                t.column(categoryColor)
                t.column(categoryCreatedAt)
                t.column(categoryModifiedAt)
                t.column(categorySyncedAt)
            })
            
            // Create passwords table
            try db?.run(passwords.create(ifNotExists: true) { t in
                t.column(passwordId, primaryKey: true)
                t.column(passwordTitle)
                t.column(passwordUsername)
                t.column(passwordPassword)
                t.column(passwordWebsite)
                t.column(passwordNotes)
                t.column(passwordCategoryId)
                t.column(passwordIsFavorite)
                t.column(passwordCreatedAt)
                t.column(passwordModifiedAt)
                t.column(passwordSyncedAt)
                t.foreignKey(passwordCategoryId, references: categories, categoryId)
            })
            
            // Create user table
            try db?.run(user.create(ifNotExists: true) { t in
                t.column(userId, primaryKey: true)
                t.column(userEmail)
                t.column(userMasterPasswordHash)
                t.column(userBiometricEnabled)
                t.column(userSyncEnabled)
                t.column(userLastSyncAt)
            })
            
        } catch {
            print("Create tables failed: \(error)")
        }
    }
    
    // MARK: - Category Operations
    func insertCategory(_ category: Category) throws {
        try db?.run(categories.insert(
            categoryId <- category.id.uuidString,
            categoryName <- category.name,
            categoryIcon <- category.icon,
            categoryColor <- category.color,
            categoryCreatedAt <- category.createdAt,
            categoryModifiedAt <- category.modifiedAt,
            categorySyncedAt <- category.syncedAt
        ))
    }
    
    func updateCategory(_ category: Category) throws {
        let categoryFilter = categories.filter(categoryId == category.id.uuidString)
        try db?.run(categoryFilter.update(
            categoryName <- category.name,
            categoryIcon <- category.icon,
            categoryColor <- category.color,
            categoryModifiedAt <- category.modifiedAt,
            categorySyncedAt <- category.syncedAt
        ))
    }
    
    func deleteCategory(_ categoryId: UUID) throws {
        let categoryFilter = categories.filter(self.categoryId == categoryId.uuidString)
        try db?.run(categoryFilter.delete())
    }
    
    func fetchCategories() throws -> [Category] {
        guard let db = db else { return [] }
        
        var categoriesList: [Category] = []
        for row in try db.prepare(categories) {
            var category = Category(
                name: row[categoryName],
                icon: row[categoryIcon],
                color: row[categoryColor]
            )
            category.createdAt = row[categoryCreatedAt]
            category.modifiedAt = row[categoryModifiedAt]
            category.syncedAt = row[categorySyncedAt]
            categoriesList.append(category)
        }
        return categoriesList
    }
    
    // MARK: - Password Operations
    func insertPassword(_ password: Password) throws {
        try db?.run(passwords.insert(
            passwordId <- password.id.uuidString,
            passwordTitle <- password.title,
            passwordUsername <- password.username,
            passwordPassword <- password.password,
            passwordWebsite <- password.website,
            passwordNotes <- password.notes,
            passwordCategoryId <- password.categoryId?.uuidString,
            passwordIsFavorite <- password.isFavorite,
            passwordCreatedAt <- password.createdAt,
            passwordModifiedAt <- password.modifiedAt,
            passwordSyncedAt <- password.syncedAt
        ))
    }
    
    func updatePassword(_ password: Password) throws {
        let passwordFilter = passwords.filter(passwordId == password.id.uuidString)
        try db?.run(passwordFilter.update(
            passwordTitle <- password.title,
            passwordUsername <- password.username,
            passwordPassword <- password.password,
            passwordWebsite <- password.website,
            passwordNotes <- password.notes,
            passwordCategoryId <- password.categoryId?.uuidString,
            passwordIsFavorite <- password.isFavorite,
            passwordModifiedAt <- password.modifiedAt,
            passwordSyncedAt <- password.syncedAt
        ))
    }
    
    func deletePassword(_ passwordId: UUID) throws {
        let passwordFilter = passwords.filter(self.passwordId == passwordId.uuidString)
        try db?.run(passwordFilter.delete())
    }
    
    func fetchPasswords() throws -> [Password] {
        guard let db = db else { return [] }
        
        var passwordsList: [Password] = []
        for row in try db.prepare(passwords) {
            var password = Password(
                title: row[passwordTitle],
                username: row[passwordUsername],
                password: row[passwordPassword],
                website: row[passwordWebsite],
                notes: row[passwordNotes],
                categoryId: row[passwordCategoryId] != nil ? UUID(uuidString: row[passwordCategoryId]!) : nil,
                isFavorite: row[passwordIsFavorite]
            )
            password.createdAt = row[passwordCreatedAt]
            password.modifiedAt = row[passwordModifiedAt]
            password.syncedAt = row[passwordSyncedAt]
            passwordsList.append(password)
        }
        return passwordsList
    }
    
    func searchPasswords(_ query: String) throws -> [Password] {
        guard let db = db else { return [] }
        
        let searchFilter = passwords.filter(
            passwordTitle.like("%\(query)%") ||
            passwordUsername.like("%\(query)%") ||
            passwordWebsite.like("%\(query)%")
        )
        
        var passwordsList: [Password] = []
        for row in try db.prepare(searchFilter) {
            var password = Password(
                title: row[passwordTitle],
                username: row[passwordUsername],
                password: row[passwordPassword],
                website: row[passwordWebsite],
                notes: row[passwordNotes],
                categoryId: row[passwordCategoryId] != nil ? UUID(uuidString: row[passwordCategoryId]!) : nil,
                isFavorite: row[passwordIsFavorite]
            )
            password.createdAt = row[passwordCreatedAt]
            password.modifiedAt = row[passwordModifiedAt]
            password.syncedAt = row[passwordSyncedAt]
            passwordsList.append(password)
        }
        return passwordsList
    }
    
    // MARK: - User Operations
    func insertUser(_ user: User) throws {
        try db?.run(self.user.insert(
            userId <- user.id.uuidString,
            userEmail <- user.email,
            userMasterPasswordHash <- user.masterPasswordHash,
            userBiometricEnabled <- user.biometricEnabled,
            userSyncEnabled <- user.syncEnabled,
            userLastSyncAt <- user.lastSyncAt
        ))
    }
    
    func updateUser(_ user: User) throws {
        let userFilter = self.user.filter(userId == user.id.uuidString)
        try db?.run(userFilter.update(
            userEmail <- user.email,
            userMasterPasswordHash <- user.masterPasswordHash,
            userBiometricEnabled <- user.biometricEnabled,
            userSyncEnabled <- user.syncEnabled,
            userLastSyncAt <- user.lastSyncAt
        ))
    }
    
    func fetchUser() throws -> User? {
        guard let db = db else { return nil }
        
        for row in try db.prepare(user.limit(1)) {
            return User(
                email: row[userEmail],
                masterPasswordHash: row[userMasterPasswordHash]
            )
        }
        return nil
    }
}