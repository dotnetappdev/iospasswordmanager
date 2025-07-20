import Foundation
import Combine

class PasswordService: ObservableObject {
    @Published var passwords: [Password] = []
    @Published var categories: [Category] = []
    @Published var searchText = ""
    @Published var selectedCategory: UUID?
    @Published var isLoading = false
    
    private let databaseService = DatabaseService()
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadData()
        setupSearchSubscription()
    }
    
    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        
        Task {
            do {
                let loadedPasswords = try databaseService.fetchPasswords()
                let loadedCategories = try databaseService.fetchCategories()
                
                await MainActor.run {
                    self.passwords = loadedPasswords
                    self.categories = loadedCategories
                    self.isLoading = false
                }
            } catch {
                print("Failed to load data: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Password Operations
    func addPassword(_ password: Password) {
        Task {
            do {
                try databaseService.insertPassword(password)
                await MainActor.run {
                    self.passwords.append(password)
                }
            } catch {
                print("Failed to add password: \(error)")
            }
        }
    }
    
    func updatePassword(_ password: Password) {
        Task {
            do {
                try databaseService.updatePassword(password)
                await MainActor.run {
                    if let index = self.passwords.firstIndex(where: { $0.id == password.id }) {
                        self.passwords[index] = password
                    }
                }
            } catch {
                print("Failed to update password: \(error)")
            }
        }
    }
    
    func deletePassword(_ password: Password) {
        Task {
            do {
                try databaseService.deletePassword(password.id)
                await MainActor.run {
                    self.passwords.removeAll { $0.id == password.id }
                }
            } catch {
                print("Failed to delete password: \(error)")
            }
        }
    }
    
    func toggleFavorite(_ password: Password) {
        var updatedPassword = password
        updatedPassword.isFavorite.toggle()
        updatePassword(updatedPassword)
    }
    
    // MARK: - Category Operations
    func addCategory(_ category: Category) {
        Task {
            do {
                try databaseService.insertCategory(category)
                await MainActor.run {
                    self.categories.append(category)
                }
            } catch {
                print("Failed to add category: \(error)")
            }
        }
    }
    
    func updateCategory(_ category: Category) {
        Task {
            do {
                try databaseService.updateCategory(category)
                await MainActor.run {
                    if let index = self.categories.firstIndex(where: { $0.id == category.id }) {
                        self.categories[index] = category
                    }
                }
            } catch {
                print("Failed to update category: \(error)")
            }
        }
    }
    
    func deleteCategory(_ category: Category) {
        Task {
            do {
                try databaseService.deleteCategory(category.id)
                await MainActor.run {
                    self.categories.removeAll { $0.id == category.id }
                    // Remove category from passwords
                    for i in 0..<self.passwords.count {
                        if self.passwords[i].categoryId == category.id {
                            self.passwords[i].categoryId = nil
                        }
                    }
                }
            } catch {
                print("Failed to delete category: \(error)")
            }
        }
    }
    
    // MARK: - Search and Filtering
    private func performSearch() {
        if searchText.isEmpty {
            loadData()
        } else {
            Task {
                do {
                    let searchResults = try databaseService.searchPasswords(searchText)
                    await MainActor.run {
                        self.passwords = searchResults
                    }
                } catch {
                    print("Search failed: \(error)")
                }
            }
        }
    }
    
    var filteredPasswords: [Password] {
        var filtered = passwords
        
        if let categoryId = selectedCategory {
            filtered = filtered.filter { $0.categoryId == categoryId }
        }
        
        return filtered.sorted { password1, password2 in
            if password1.isFavorite != password2.isFavorite {
                return password1.isFavorite
            }
            return password1.title.localizedCaseInsensitiveCompare(password2.title) == .orderedAscending
        }
    }
    
    var favoritePasswords: [Password] {
        passwords.filter { $0.isFavorite }
    }
    
    var recentPasswords: [Password] {
        passwords.sorted { $0.modifiedAt > $1.modifiedAt }.prefix(10).map { $0 }
    }
    
    // MARK: - Statistics
    var passwordCount: Int {
        passwords.count
    }
    
    var categoryCount: Int {
        categories.count
    }
    
    var favoriteCount: Int {
        favoritePasswords.count
    }
    
    func passwordsCount(for category: Category) -> Int {
        passwords.filter { $0.categoryId == category.id }.count
    }
    
    // MARK: - Password Generation
    func generateSecurePassword(length: Int = 16, includeUppercase: Bool = true, includeLowercase: Bool = true, includeNumbers: Bool = true, includeSymbols: Bool = true) -> String {
        return CryptoService.shared.generatePassword(
            length: length,
            includeUppercase: includeUppercase,
            includeLowercase: includeLowercase,
            includeNumbers: includeNumbers,
            includeSymbols: includeSymbols
        )
    }
    
    func analyzePasswordStrength(_ password: String) -> PasswordStrength {
        return CryptoService.shared.calculatePasswordStrength(password)
    }
    
    // MARK: - Sync Operations
    func syncWithServer() async -> Bool {
        guard let settingsService = SettingsService.shared,
              settingsService.isAPIConfigured else {
            print("API not configured")
            return false
        }
        
        isLoading = true
        
        do {
            // Prepare data for sync
            let apiPasswords = passwords.map { $0.toAPIPassword() }
            let apiCategories = categories.map { $0.toAPICategory() }
            
            let success = await apiService.syncData(passwords: apiPasswords, categories: apiCategories)
            
            if success {
                // Reload data after successful sync
                loadData()
            }
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return success
        } catch {
            print("Sync failed: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Bulk Operations
    func deleteAllPasswords() {
        Task {
            for password in passwords {
                do {
                    try databaseService.deletePassword(password.id)
                } catch {
                    print("Failed to delete password: \(error)")
                }
            }
            
            await MainActor.run {
                self.passwords.removeAll()
            }
        }
    }
    
    func exportPasswords() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(passwords)
        } catch {
            print("Failed to export passwords: \(error)")
            return nil
        }
    }
    
    func importPasswords(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedPasswords = try decoder.decode([Password].self, from: data)
            
            for password in importedPasswords {
                addPassword(password)
            }
            
            return true
        } catch {
            print("Failed to import passwords: \(error)")
            return false
        }
    }
}