import Foundation
import Alamofire

class APIService {
    static let shared = APIService()
    
    private init() {}
    
    private var baseURL: String {
        return SettingsService.shared?.apiURL ?? ""
    }
    
    private var apiKey: String {
        return SettingsService.shared?.apiKey ?? ""
    }
    
    private var headers: HTTPHeaders {
        return [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
    }
    
    // MARK: - Sync Operations
    func syncData(passwords: [APIPassword], categories: [APICategory]) async -> Bool {
        guard !baseURL.isEmpty, !apiKey.isEmpty else {
            print("API configuration missing")
            return false
        }
        
        let syncRequest = SyncRequest(
            passwords: passwords,
            categories: categories,
            lastSyncAt: getLastSyncTimestamp()
        )
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/sync",
                method: .post,
                parameters: syncRequest,
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate()
            .responseDecodable(of: SyncResponse.self) { response in
                switch response.result {
                case .success(let syncResponse):
                    Task {
                        await self.processSyncResponse(syncResponse)
                        self.saveLastSyncTimestamp(syncResponse.serverTimestamp)
                        continuation.resume(returning: true)
                    }
                case .failure(let error):
                    print("Sync failed: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func processSyncResponse(_ response: SyncResponse) async {
        let databaseService = DatabaseService()
        
        // Process categories first (passwords might reference them)
        for apiCategory in response.categories {
            let category = apiCategory.toCategory()
            do {
                try databaseService.insertCategory(category)
            } catch {
                // If insert fails, try update
                do {
                    try databaseService.updateCategory(category)
                } catch {
                    print("Failed to process category: \(error)")
                }
            }
        }
        
        // Process passwords
        for apiPassword in response.passwords {
            let password = apiPassword.toPassword()
            do {
                try databaseService.insertPassword(password)
            } catch {
                // If insert fails, try update
                do {
                    try databaseService.updatePassword(password)
                } catch {
                    print("Failed to process password: \(error)")
                }
            }
        }
    }
    
    // MARK: - Individual Operations
    func createPassword(_ password: APIPassword) async -> Bool {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return false }
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/passwords",
                method: .post,
                parameters: password,
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate()
            .response { response in
                continuation.resume(returning: response.error == nil)
            }
        }
    }
    
    func updatePassword(_ password: APIPassword) async -> Bool {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return false }
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/passwords/\(password.id)",
                method: .put,
                parameters: password,
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate()
            .response { response in
                continuation.resume(returning: response.error == nil)
            }
        }
    }
    
    func deletePassword(_ passwordId: String) async -> Bool {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return false }
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/passwords/\(passwordId)",
                method: .delete,
                headers: headers
            )
            .validate()
            .response { response in
                continuation.resume(returning: response.error == nil)
            }
        }
    }
    
    func createCategory(_ category: APICategory) async -> Bool {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return false }
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/categories",
                method: .post,
                parameters: category,
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate()
            .response { response in
                continuation.resume(returning: response.error == nil)
            }
        }
    }
    
    func updateCategory(_ category: APICategory) async -> Bool {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return false }
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/categories/\(category.id)",
                method: .put,
                parameters: category,
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate()
            .response { response in
                continuation.resume(returning: response.error == nil)
            }
        }
    }
    
    func deleteCategory(_ categoryId: String) async -> Bool {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return false }
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/categories/\(categoryId)",
                method: .delete,
                headers: headers
            )
            .validate()
            .response { response in
                continuation.resume(returning: response.error == nil)
            }
        }
    }
    
    // MARK: - Data Fetching
    func fetchAllPasswords() async -> [APIPassword]? {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return nil }
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/passwords",
                method: .get,
                headers: headers
            )
            .validate()
            .responseDecodable(of: [APIPassword].self) { response in
                switch response.result {
                case .success(let passwords):
                    continuation.resume(returning: passwords)
                case .failure(let error):
                    print("Failed to fetch passwords: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func fetchAllCategories() async -> [APICategory]? {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return nil }
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/categories",
                method: .get,
                headers: headers
            )
            .validate()
            .responseDecodable(of: [APICategory].self) { response in
                switch response.result {
                case .success(let categories):
                    continuation.resume(returning: categories)
                case .failure(let error):
                    print("Failed to fetch categories: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - Connection Testing
    func testConnection() async -> Bool {
        guard !baseURL.isEmpty, !apiKey.isEmpty else { return false }
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/health",
                method: .get,
                headers: headers
            )
            .validate()
            .response { response in
                continuation.resume(returning: response.error == nil)
            }
        }
    }
    
    // MARK: - User Authentication
    func authenticateUser(email: String, password: String) async -> String? {
        guard !baseURL.isEmpty else { return nil }
        
        let loginRequest = [
            "email": email,
            "password": password
        ]
        
        return await withCheckedContinuation { continuation in
            AF.request(
                "\(baseURL)/api/auth/login",
                method: .post,
                parameters: loginRequest,
                encoder: JSONParameterEncoder.default
            )
            .validate()
            .responseDecodable(of: [String: String].self) { response in
                switch response.result {
                case .success(let result):
                    continuation.resume(returning: result["token"])
                case .failure(let error):
                    print("Authentication failed: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - Timestamp Management
    private func getLastSyncTimestamp() -> String? {
        let key = "lastSyncTimestamp"
        return UserDefaults.standard.string(forKey: key)
    }
    
    private func saveLastSyncTimestamp(_ timestamp: String) {
        let key = "lastSyncTimestamp"
        UserDefaults.standard.set(timestamp, forKey: key)
    }
    
    // MARK: - Error Handling
    private func handleAPIError(_ error: AFError) {
        if let statusCode = error.responseCode {
            switch statusCode {
            case 401:
                print("Unauthorized - check API key")
                // Could trigger re-authentication flow
            case 403:
                print("Forbidden - insufficient permissions")
            case 404:
                print("Not found - check API URL")
            case 429:
                print("Rate limited - too many requests")
            case 500...599:
                print("Server error - try again later")
            default:
                print("API error: \(statusCode)")
            }
        }
    }
}