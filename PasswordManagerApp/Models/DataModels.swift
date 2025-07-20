import Foundation

struct Password: Identifiable, Codable {
    let id: UUID
    var title: String
    var username: String
    var password: String
    var website: String
    var notes: String
    var categoryId: UUID?
    var isFavorite: Bool
    var createdAt: Date
    var modifiedAt: Date
    var syncedAt: Date?
    
    init(title: String, username: String, password: String, website: String = "", notes: String = "", categoryId: UUID? = nil, isFavorite: Bool = false) {
        self.id = UUID()
        self.title = title
        self.username = username
        self.password = password
        self.website = website
        self.notes = notes
        self.categoryId = categoryId
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.syncedAt = nil
    }
    
    mutating func updatePassword(_ newPassword: String) {
        self.password = newPassword
        self.modifiedAt = Date()
        self.syncedAt = nil
    }
    
    mutating func update(title: String? = nil, username: String? = nil, password: String? = nil, website: String? = nil, notes: String? = nil, categoryId: UUID? = nil, isFavorite: Bool? = nil) {
        if let title = title { self.title = title }
        if let username = username { self.username = username }
        if let password = password { self.password = password }
        if let website = website { self.website = website }
        if let notes = notes { self.notes = notes }
        if let categoryId = categoryId { self.categoryId = categoryId }
        if let isFavorite = isFavorite { self.isFavorite = isFavorite }
        self.modifiedAt = Date()
        self.syncedAt = nil
    }
}

struct Category: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var createdAt: Date
    var modifiedAt: Date
    var syncedAt: Date?
    
    init(name: String, icon: String = "folder", color: String = "blue") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.syncedAt = nil
    }
    
    mutating func update(name: String? = nil, icon: String? = nil, color: String? = nil) {
        if let name = name { self.name = name }
        if let icon = icon { self.icon = icon }
        if let color = color { self.color = color }
        self.modifiedAt = Date()
        self.syncedAt = nil
    }
}

struct User: Codable {
    let id: UUID
    var email: String
    var masterPasswordHash: String
    var biometricEnabled: Bool
    var syncEnabled: Bool
    var lastSyncAt: Date?
    
    init(email: String, masterPasswordHash: String) {
        self.id = UUID()
        self.email = email
        self.masterPasswordHash = masterPasswordHash
        self.biometricEnabled = false
        self.syncEnabled = false
        self.lastSyncAt = nil
    }
}