import SwiftUI

struct PasswordListView: View {
    @EnvironmentObject var passwordService: PasswordService
    @EnvironmentObject var settingsService: SettingsService
    @State private var showingAddPassword = false
    @State private var showingSync = false
    @State private var selectedPassword: Password?
    @State private var searchText = ""
    @State private var selectedCategory: UUID?
    @State private var sortOption: SortOption = .title
    @State private var showingCategories = false
    
    enum SortOption: CaseIterable {
        case title, dateCreated, dateModified, category
        
        var displayName: String {
            switch self {
            case .title: return "Title"
            case .dateCreated: return "Date Created"
            case .dateModified: return "Date Modified"
            case .category: return "Category"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if passwordService.isLoading {
                    ProgressView("Loading passwords...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    passwordListContent
                }
            }
            .navigationTitle("Passwords")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Button(action: { showingCategories.toggle() }) {
                            Image(systemName: "folder")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Password") {
                            showingAddPassword = true
                        }
                        
                        if settingsService.isAPIConfigured {
                            Button("Sync Now") {
                                syncPasswords()
                            }
                        }
                        
                        Menu("Sort By") {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(option.displayName) {
                                    sortOption = option
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search passwords")
            .onChange(of: searchText) { _, newValue in
                passwordService.searchText = newValue
            }
            .sheet(isPresented: $showingAddPassword) {
                AddEditPasswordView()
            }
            .sheet(item: $selectedPassword) { password in
                PasswordDetailView(password: password)
            }
            .sheet(isPresented: $showingCategories) {
                CategoryFilterView(selectedCategory: $selectedCategory)
            }
        }
    }
    
    private var passwordListContent: some View {
        Group {
            if filteredPasswords.isEmpty {
                emptyStateView
            } else {
                passwordList
            }
        }
    }
    
    private var passwordList: some View {
        List {
            if !searchText.isEmpty {
                Section("Search Results") {
                    ForEach(filteredPasswords) { password in
                        PasswordRowView(password: password) {
                            selectedPassword = password
                        }
                    }
                    .onDelete(perform: deletePasswords)
                }
            } else {
                if !passwordService.favoritePasswords.isEmpty {
                    Section("Favorites") {
                        ForEach(passwordService.favoritePasswords) { password in
                            PasswordRowView(password: password) {
                                selectedPassword = password
                            }
                        }
                    }
                }
                
                if selectedCategory == nil {
                    Section("All Passwords") {
                        ForEach(filteredPasswords) { password in
                            PasswordRowView(password: password) {
                                selectedPassword = password
                            }
                        }
                        .onDelete(perform: deletePasswords)
                    }
                } else {
                    Section(categoryName) {
                        ForEach(filteredPasswords) { password in
                            PasswordRowView(password: password) {
                                selectedPassword = password
                            }
                        }
                        .onDelete(perform: deletePasswords)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            await refreshData()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Passwords Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            if searchText.isEmpty {
                Text("Tap the + button to add your first password")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button("Add Password") {
                    showingAddPassword = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Try adjusting your search terms")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var filteredPasswords: [Password] {
        var passwords = passwordService.filteredPasswords
        
        if let categoryId = selectedCategory {
            passwords = passwords.filter { $0.categoryId == categoryId }
        }
        
        // Apply sorting
        switch sortOption {
        case .title:
            passwords.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .dateCreated:
            passwords.sort { $0.createdAt > $1.createdAt }
        case .dateModified:
            passwords.sort { $0.modifiedAt > $1.modifiedAt }
        case .category:
            passwords.sort { password1, password2 in
                let category1 = categoryName(for: password1.categoryId)
                let category2 = categoryName(for: password2.categoryId)
                return category1.localizedCaseInsensitiveCompare(category2) == .orderedAscending
            }
        }
        
        return passwords
    }
    
    private var categoryName: String {
        guard let categoryId = selectedCategory else { return "All Passwords" }
        return passwordService.categories.first { $0.id == categoryId }?.name ?? "Unknown Category"
    }
    
    private func categoryName(for categoryId: UUID?) -> String {
        guard let categoryId = categoryId else { return "No Category" }
        return passwordService.categories.first { $0.id == categoryId }?.name ?? "Unknown"
    }
    
    private func deletePasswords(offsets: IndexSet) {
        for index in offsets {
            let password = filteredPasswords[index]
            passwordService.deletePassword(password)
        }
    }
    
    private func syncPasswords() {
        Task {
            showingSync = true
            await passwordService.syncWithServer()
            showingSync = false
        }
    }
    
    private func refreshData() async {
        if settingsService.isAPIConfigured {
            await passwordService.syncWithServer()
        } else {
            passwordService.loadData()
        }
    }
}

struct PasswordRowView: View {
    let password: Password
    let onTap: () -> Void
    @EnvironmentObject var passwordService: PasswordService
    @State private var showPassword = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon
                VStack {
                    if let categoryId = password.categoryId,
                       let category = passwordService.categories.first(where: { $0.id == categoryId }) {
                        Image(systemName: category.icon)
                            .foregroundColor(Color(category.color))
                            .font(.title2)
                    } else {
                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(password.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if password.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    Text(password.username)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !password.website.isEmpty {
                        Text(password.website)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack {
                    Button(action: {
                        passwordService.toggleFavorite(password)
                    }) {
                        Image(systemName: password.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(password.isFavorite ? .red : .gray)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        copyPassword()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func copyPassword() {
        UIPasteboard.general.string = password.password
        
        // Clear clipboard after timeout if enabled
        if SettingsService.shared?.enableClipboardClear == true {
            let timeout = SettingsService.shared?.clipboardClearTimeout ?? 30
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                if UIPasteboard.general.string == password.password {
                    UIPasteboard.general.string = ""
                }
            }
        }
    }
}

struct CategoryFilterView: View {
    @Binding var selectedCategory: UUID?
    @EnvironmentObject var passwordService: PasswordService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button("All Categories") {
                    selectedCategory = nil
                    dismiss()
                }
                .foregroundColor(selectedCategory == nil ? .blue : .primary)
                
                ForEach(passwordService.categories) { category in
                    Button(action: {
                        selectedCategory = category.id
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(category.color))
                            Text(category.name)
                            Spacer()
                            Text("\(passwordService.passwordsCount(for: category))")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(selectedCategory == category.id ? .blue : .primary)
                }
            }
            .navigationTitle("Filter by Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PasswordListView()
        .environmentObject(PasswordService())
        .environmentObject(SettingsService())
}