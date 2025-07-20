import SwiftUI

struct PasswordListView: View {
    @EnvironmentObject var passwordService: PasswordService
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var accessibilityStateManager: AccessibilityStateManager
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
                        .accessibilityLabel("Loading passwords, please wait")
                } else {
                    passwordListContent
                }
            }
            .navigationTitle("Passwords")
            .navigationBarTitleDisplayMode(.large)
            .accessibilityHeading("Passwords")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Button(action: { showingCategories.toggle() }) {
                            Image(systemName: "folder")
                        }
                        .accessibilityButton(
                            "Filter by category",
                            hint: "Double tap to filter passwords by category"
                        )
                        .accessibilityId("categoryFilterButton")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(AccessibilityConstants.Labels.add + " Password") {
                            showingAddPassword = true
                        }
                        .accessibilityButton(
                            AccessibilityConstants.Labels.add + " Password",
                            hint: "Create a new password entry"
                        )
                        
                        if settingsService.isAPIConfigured {
                            Button("Sync Now") {
                                syncPasswords()
                            }
                            .accessibilityButton(
                                "Sync Now",
                                hint: "Synchronize passwords with server"
                            )
                        }
                        
                        Menu("Sort By") {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(option.displayName) {
                                    sortOption = option
                                    UIAccessibility.post(notification: .announcement, 
                                                       argument: "Sorted by \(option.displayName)")
                                }
                                .accessibilityButton(
                                    option.displayName,
                                    hint: "Sort passwords by \(option.displayName.lowercased())"
                                )
                            }
                        }
                        .accessibilityLabel("Sort options")
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityButton(
                        "Add password and options menu",
                        hint: "Double tap to add a new password or access more options"
                    )
                    .accessibilityId("addPasswordMenu")
                }
            }
            .searchable(text: $searchText, prompt: "Search passwords")
            .accessibilityTextField(
                AccessibilityConstants.Labels.search,
                hint: AccessibilityConstants.Hints.searchPasswordsHint,
                value: searchText.isEmpty ? "No search terms" : "Searching for: \(searchText)"
            )
            .onChange(of: searchText) { _, newValue in
                passwordService.searchText = newValue
                if !newValue.isEmpty {
                    UIAccessibility.post(notification: .announcement, 
                                       argument: "Searching for \(newValue)")
                }
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
            .onAppear {
                UIAccessibility.post(notification: .screenChanged, 
                                   argument: "Passwords list with \(passwordService.passwordCount) passwords")
            }
        }
        .accessibilityElement(children: .contain)
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
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Search results, \(filteredPasswords.count) passwords found")
            } else {
                if !passwordService.favoritePasswords.isEmpty {
                    Section("Favorites") {
                        ForEach(passwordService.favoritePasswords) { password in
                            PasswordRowView(password: password) {
                                selectedPassword = password
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Favorite passwords, \(passwordService.favoritePasswords.count) items")
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
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("All passwords, \(filteredPasswords.count) items")
                } else {
                    Section(categoryName) {
                        ForEach(filteredPasswords) { password in
                            PasswordRowView(password: password) {
                                selectedPassword = password
                            }
                        }
                        .onDelete(perform: deletePasswords)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("\(categoryName), \(filteredPasswords.count) passwords")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            UIAccessibility.post(notification: .announcement, argument: "Refreshing passwords")
            await refreshData()
        }
        .accessibilityLabel(AccessibilityConstants.Navigation.passwordsList)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.slash")
                .accessibleFont(size: 60)
                .foregroundColor(.gray)
                .accessibilityLabel("No passwords icon")
            
            Text("No Passwords Found")
                .accessibleFont(.title2, weight: .semibold)
                .foregroundColor(.gray)
                .accessibilityHeading("No Passwords Found")
            
            if searchText.isEmpty {
                Text("Tap the + button to add your first password")
                    .accessibleFont(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Instructions: Tap the plus button to add your first password")
                
                Button("Add Password") {
                    showingAddPassword = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityButton(
                    AccessibilityConstants.Labels.add + " Password",
                    hint: "Create your first password entry"
                )
                .accessibleTapTarget()
            } else {
                Text("Try adjusting your search terms")
                    .accessibleFont(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("No results found. Try adjusting your search terms")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(searchText.isEmpty ? "No passwords saved" : "No search results")
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
            UIAccessibility.post(notification: .announcement, 
                               argument: "Password \(password.title) deleted")
        }
    }
    
    private func syncPasswords() {
        Task {
            showingSync = true
            UIAccessibility.post(notification: .announcement, argument: "Starting sync")
            await passwordService.syncWithServer()
            showingSync = false
            UIAccessibility.post(notification: .announcement, 
                               argument: AccessibilityConstants.Announcements.syncCompleted)
        }
    }
    
    private func refreshData() async {
        if settingsService.isAPIConfigured {
            await passwordService.syncWithServer()
            UIAccessibility.post(notification: .announcement, 
                               argument: AccessibilityConstants.Announcements.dataLoaded)
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
                            .accessibleFont(.title2)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                            .accessibleFont(.title2)
                            .accessibilityHidden(true)
                    }
                }
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(password.title)
                            .accessibleFont(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if password.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .accessibleFont(.caption)
                                .accessibilityHidden(true)
                        }
                    }
                    
                    Text(password.username)
                        .accessibleFont(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !password.website.isEmpty {
                        Text(password.website)
                            .accessibleFont(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack {
                    Button(action: {
                        passwordService.toggleFavorite(password)
                        let announcement = password.isFavorite ? 
                            AccessibilityConstants.Announcements.removedFromFavorites :
                            AccessibilityConstants.Announcements.addedToFavorites
                        UIAccessibility.post(notification: .announcement, argument: announcement)
                    }) {
                        Image(systemName: password.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(password.isFavorite ? .red : .gray)
                    }
                    .buttonStyle(.plain)
                    .accessibilityButton(
                        password.isFavorite ? 
                            AccessibilityConstants.PasswordManager.unfavoriteButton :
                            AccessibilityConstants.PasswordManager.favoriteButton,
                        hint: AccessibilityConstants.Hints.tapToToggleFavorite
                    )
                    .accessibleTapTarget()
                    
                    Button(action: {
                        copyPassword()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityButton(
                        AccessibilityConstants.PasswordManager.copyPassword,
                        hint: AccessibilityConstants.Hints.tapToCopy
                    )
                    .accessibleTapTarget()
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityListItem(
            "\(password.title), username: \(password.username)" + 
            (password.website.isEmpty ? "" : ", website: \(password.website)") +
            (password.isFavorite ? ", favorite" : ""),
            hint: "Double tap to view and edit this password",
            value: categoryName(for: password.categoryId)
        )
        .accessibilityId("passwordRow_\(password.id.uuidString)")
        .accessibleTapTarget()
    }
    
    private func categoryName(for categoryId: UUID?) -> String {
        guard let categoryId = categoryId else { return "No Category" }
        return passwordService.categories.first { $0.id == categoryId }?.name ?? "Unknown"
    }
    
    private func copyPassword() {
        UIPasteboard.general.string = password.password
        UIAccessibility.post(notification: .announcement, 
                           argument: AccessibilityConstants.Announcements.passwordCopied)
        
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
                    UIAccessibility.post(notification: .announcement, argument: "Showing all categories")
                }
                .foregroundColor(selectedCategory == nil ? .blue : .primary)
                .accessibilityButton(
                    "All Categories",
                    hint: "Show passwords from all categories"
                )
                .accessibilityValue(selectedCategory == nil ? "Selected" : "")
                
                ForEach(passwordService.categories) { category in
                    Button(action: {
                        selectedCategory = category.id
                        dismiss()
                        UIAccessibility.post(notification: .announcement, 
                                           argument: "Filtering by \(category.name)")
                    }) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(category.color))
                                .accessibilityHidden(true)
                            Text(category.name)
                            Spacer()
                            Text("\(passwordService.passwordsCount(for: category))")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(selectedCategory == category.id ? .blue : .primary)
                    .accessibilityButton(
                        "\(category.name), \(passwordService.passwordsCount(for: category)) passwords",
                        hint: "Filter to show only \(category.name) passwords"
                    )
                    .accessibilityValue(selectedCategory == category.id ? "Selected" : "")
                }
            }
            .navigationTitle("Filter by Category")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityHeading("Filter by Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AccessibilityConstants.Labels.done) {
                        dismiss()
                    }
                    .accessibilityButton(
                        AccessibilityConstants.Labels.done,
                        hint: "Close category filter"
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PasswordListView()
        .environmentObject(PasswordService())
        .environmentObject(SettingsService())
        .environmentObject(AccessibilityStateManager())
}