import Foundation

// API Models for sync operations
struct APIPassword: Codable {
    let id: String
    let title: String
    let username: String
    let password: String
    let website: String
    let notes: String
    let categoryId: String?
    let isFavorite: Bool
    let createdAt: String
    let modifiedAt: String
    
    func toPassword() -> Password {
        var password = Password(
            title: title,
            username: username,
            password: self.password,
            website: website,
            notes: notes,
            categoryId: categoryId != nil ? UUID(uuidString: categoryId!) : nil,
            isFavorite: isFavorite
        )
        
        // Parse dates
        let formatter = ISO8601DateFormatter()
        if let createdDate = formatter.date(from: createdAt) {
            password.createdAt = createdDate
        }
        if let modifiedDate = formatter.date(from: modifiedAt) {
            password.modifiedAt = modifiedDate
        }
        
        return password
    }
}

struct APICategory: Codable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let createdAt: String
    let modifiedAt: String
    
    func toCategory() -> Category {
        var category = Category(name: name, icon: icon, color: color)
        
        // Parse dates
        let formatter = ISO8601DateFormatter()
        if let createdDate = formatter.date(from: createdAt) {
            category.createdAt = createdDate
        }
        if let modifiedDate = formatter.date(from: modifiedAt) {
            category.modifiedAt = modifiedDate
        }
        
        return category
    }
}

struct SyncRequest: Codable {
    let passwords: [APIPassword]
    let categories: [APICategory]
    let lastSyncAt: String?
}

struct SyncResponse: Codable {
    let passwords: [APIPassword]
    let categories: [APICategory]
    let serverTimestamp: String
}

extension Password {
    func toAPIPassword() -> APIPassword {
        let formatter = ISO8601DateFormatter()
        return APIPassword(
            id: id.uuidString,
            title: title,
            username: username,
            password: password,
            website: website,
            notes: notes,
            categoryId: categoryId?.uuidString,
            isFavorite: isFavorite,
            createdAt: formatter.string(from: createdAt),
            modifiedAt: formatter.string(from: modifiedAt)
        )
    }
}

extension Category {
    func toAPICategory() -> APICategory {
        let formatter = ISO8601DateFormatter()
        return APICategory(
            id: id.uuidString,
            name: name,
            icon: icon,
            color: color,
            createdAt: formatter.string(from: createdAt),
            modifiedAt: formatter.string(from: modifiedAt)
        )
    }
}