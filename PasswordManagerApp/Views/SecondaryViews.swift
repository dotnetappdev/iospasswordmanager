import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var passwordService: PasswordService
    @State private var selectedPassword: Password?
    @State private var showingAddPassword = false
    
    var body: some View {
        NavigationView {
            Group {
                if passwordService.favoritePasswords.isEmpty {
                    emptyStateView
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddPassword = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPassword) {
                AddEditPasswordView()
            }
            .sheet(item: $selectedPassword) { password in
                PasswordDetailView(password: password)
            }
        }
    }
    
    private var favoritesList: some View {
        List {
            ForEach(passwordService.favoritePasswords) { password in
                PasswordRowView(password: password) {
                    selectedPassword = password
                }
            }
            .onDelete(perform: removeFavorites)
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Favorites")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            Text("Tap the heart icon on any password to add it to your favorites")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func removeFavorites(offsets: IndexSet) {
        for index in offsets {
            var password = passwordService.favoritePasswords[index]
            password.isFavorite = false
            passwordService.updatePassword(password)
        }
    }
}

struct CategoriesView: View {
    @EnvironmentObject var passwordService: PasswordService
    @State private var showingAddCategory = false
    @State private var selectedCategory: Category?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category?
    
    var body: some View {
        NavigationView {
            Group {
                if passwordService.categories.isEmpty {
                    emptyStateView
                } else {
                    categoriesList
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddEditCategoryView()
            }
            .sheet(item: $selectedCategory) { category in
                AddEditCategoryView(category: category)
            }
            .alert("Delete Category", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let category = categoryToDelete {
                        passwordService.deleteCategory(category)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this category? Passwords in this category will not be deleted.")
            }
        }
    }
    
    private var categoriesList: some View {
        List {
            ForEach(passwordService.categories) { category in
                CategoryRowView(category: category) {
                    selectedCategory = category
                }
            }
            .onDelete(perform: deleteCategories)
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Categories")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            Text("Create categories to organize your passwords")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Add Category") {
                showingAddCategory = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteCategories(offsets: IndexSet) {
        for index in offsets {
            categoryToDelete = passwordService.categories[index]
            showingDeleteAlert = true
        }
    }
}

struct CategoryRowView: View {
    let category: Category
    let onTap: () -> Void
    @EnvironmentObject var passwordService: PasswordService
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(Color(category.color))
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color(category.color).opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(passwordService.passwordsCount(for: category)) passwords")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct GeneratorView: View {
    @EnvironmentObject var settingsService: SettingsService
    @State private var length: Double = 16
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var generatedPassword = ""
    @State private var showingCopiedAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Password Length")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(length))")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Slider(value: $length, in: 4...128, step: 1)
                        .onChange(of: length) { _, _ in generatePassword() }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Character Types")
                        .font(.headline)
                    
                    Toggle("Uppercase Letters (A-Z)", isOn: $includeUppercase)
                        .onChange(of: includeUppercase) { _, _ in generatePassword() }
                    
                    Toggle("Lowercase Letters (a-z)", isOn: $includeLowercase)
                        .onChange(of: includeLowercase) { _, _ in generatePassword() }
                    
                    Toggle("Numbers (0-9)", isOn: $includeNumbers)
                        .onChange(of: includeNumbers) { _, _ in generatePassword() }
                    
                    Toggle("Symbols (!@#$...)", isOn: $includeSymbols)
                        .onChange(of: includeSymbols) { _, _ in generatePassword() }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Generated Password")
                            .font(.headline)
                        Spacer()
                        Button("Regenerate") {
                            generatePassword()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text(generatedPassword)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                            
                            Button(action: copyPassword) {
                                Image(systemName: "doc.on.doc")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if !generatedPassword.isEmpty {
                            PasswordStrengthMeter(password: generatedPassword)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Password Generator")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadSettings()
            generatePassword()
        }
        .alert("Password Copied", isPresented: $showingCopiedAlert) {
            Button("OK") { }
        } message: {
            Text("The password has been copied to your clipboard")
        }
    }
    
    private func loadSettings() {
        length = Double(settingsService.passwordGeneratorLength)
        includeUppercase = settingsService.passwordIncludeUppercase
        includeLowercase = settingsService.passwordIncludeLowercase
        includeNumbers = settingsService.passwordIncludeNumbers
        includeSymbols = settingsService.passwordIncludeSymbols
    }
    
    private func generatePassword() {
        // Ensure at least one character type is selected
        if !includeUppercase && !includeLowercase && !includeNumbers && !includeSymbols {
            includeLowercase = true
        }
        
        generatedPassword = CryptoService.shared.generatePassword(
            length: Int(length),
            includeUppercase: includeUppercase,
            includeLowercase: includeLowercase,
            includeNumbers: includeNumbers,
            includeSymbols: includeSymbols
        )
        
        // Save settings
        settingsService.updatePasswordGeneratorSettings(
            length: Int(length),
            uppercase: includeUppercase,
            lowercase: includeLowercase,
            numbers: includeNumbers,
            symbols: includeSymbols
        )
    }
    
    private func copyPassword() {
        UIPasteboard.general.string = generatedPassword
        showingCopiedAlert = true
        
        // Clear clipboard after timeout if enabled
        if settingsService.enableClipboardClear {
            DispatchQueue.main.asyncAfter(deadline: .now() + settingsService.clipboardClearTimeout) {
                if UIPasteboard.general.string == generatedPassword {
                    UIPasteboard.general.string = ""
                }
            }
        }
    }
}

struct SearchView: View {
    @EnvironmentObject var passwordService: PasswordService
    @State private var searchText = ""
    @State private var selectedPassword: Password?
    
    var body: some View {
        NavigationView {
            VStack {
                if filteredPasswords.isEmpty && !searchText.isEmpty {
                    emptySearchView
                } else if searchText.isEmpty {
                    initialSearchView
                } else {
                    searchResults
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search passwords, usernames, websites...")
            .onChange(of: searchText) { _, newValue in
                passwordService.searchText = newValue
            }
            .sheet(item: $selectedPassword) { password in
                PasswordDetailView(password: password)
            }
        }
    }
    
    private var filteredPasswords: [Password] {
        if searchText.isEmpty {
            return []
        }
        return passwordService.passwords.filter { password in
            password.title.localizedCaseInsensitiveContains(searchText) ||
            password.username.localizedCaseInsensitiveContains(searchText) ||
            password.website.localizedCaseInsensitiveContains(searchText) ||
            password.notes.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var searchResults: some View {
        List {
            Section("\(filteredPasswords.count) results") {
                ForEach(filteredPasswords) { password in
                    PasswordRowView(password: password) {
                        selectedPassword = password
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var initialSearchView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Search Your Passwords")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            Text("Enter a search term to find passwords, usernames, websites, or notes")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            Text("Try different search terms or check your spelling")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Favorites") {
    FavoritesView()
        .environmentObject(PasswordService())
}

#Preview("Categories") {
    CategoriesView()
        .environmentObject(PasswordService())
}

#Preview("Generator") {
    GeneratorView()
        .environmentObject(SettingsService())
}

#Preview("Search") {
    SearchView()
        .environmentObject(PasswordService())
}