import SwiftUI

struct PasswordDetailView: View {
    let password: Password
    @EnvironmentObject var passwordService: PasswordService
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var accessibilityStateManager: AccessibilityStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Password Info
                    passwordInfoSection
                    
                    // Additional Info
                    additionalInfoSection
                    
                    // Actions
                    actionsSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Password Details")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityHeading("Password Details for \(password.title)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AccessibilityConstants.Labels.done) {
                        dismiss()
                    }
                    .accessibilityButton(
                        AccessibilityConstants.Labels.done,
                        hint: "Close password details"
                    )
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(AccessibilityConstants.Labels.edit) {
                            showingEdit = true
                        }
                        .accessibilityButton(
                            AccessibilityConstants.Labels.edit,
                            hint: "Edit this password"
                        )
                        
                        Button("Toggle Favorite") {
                            passwordService.toggleFavorite(password)
                            let announcement = password.isFavorite ? 
                                AccessibilityConstants.Announcements.removedFromFavorites :
                                AccessibilityConstants.Announcements.addedToFavorites
                            UIAccessibility.post(notification: .announcement, argument: announcement)
                        }
                        .accessibilityButton(
                            password.isFavorite ? "Remove from favorites" : "Add to favorites",
                            hint: AccessibilityConstants.Hints.tapToToggleFavorite
                        )
                        
                        Divider()
                        
                        Button(AccessibilityConstants.Labels.delete, role: .destructive) {
                            showingDeleteAlert = true
                        }
                        .accessibilityButton(
                            AccessibilityConstants.Labels.delete,
                            hint: "Delete this password permanently"
                        )
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityButton(
                        AccessibilityConstants.Labels.more,
                        hint: "Show more options for this password"
                    )
                }
            }
            .sheet(isPresented: $showingEdit) {
                AddEditPasswordView(password: password)
            }
            .alert("Delete Password", isPresented: $showingDeleteAlert) {
                Button(AccessibilityConstants.Labels.cancel, role: .cancel) { 
                    UIAccessibility.post(notification: .announcement, argument: "Delete cancelled")
                }
                .accessibilityButton(AccessibilityConstants.Labels.cancel)
                
                Button(AccessibilityConstants.Labels.delete, role: .destructive) {
                    passwordService.deletePassword(password)
                    UIAccessibility.post(notification: .announcement, 
                                       argument: AccessibilityConstants.Announcements.passwordDeleted)
                    dismiss()
                }
                .accessibilityButton(AccessibilityConstants.Labels.delete + " permanently")
            } message: {
                Text("Are you sure you want to delete this password? This action cannot be undone.")
                    .accessibilityLabel("Confirmation: Are you sure you want to delete this password? This action cannot be undone.")
            }
            .onAppear {
                UIAccessibility.post(notification: .screenChanged, 
                                   argument: "Password details for \(password.title)")
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: categoryIcon)
                    .accessibleFont(size: 32)
                    .foregroundColor(categoryColor)
            }
            .accessibilityLabel("Category icon for \(categoryName)")
            .accessibilityHidden(true) // Icon is decorative, information provided in text
            
            VStack(spacing: 4) {
                Text(password.title)
                    .accessibleFont(.title2, weight: .bold)
                    .multilineTextAlignment(.center)
                    .accessibilityHeading(password.title)
                
                if !password.website.isEmpty {
                    Link(password.website, destination: URL(string: password.website.hasPrefix("http") ? password.website : "https://\(password.website)") ?? URL(string: "https://google.com")!)
                        .accessibleFont(.subheadline)
                        .foregroundColor(.blue)
                        .accessibilityButton(
                            "Website: \(password.website)",
                            hint: "Double tap to open website in browser"
                        )
                        .accessibleTapTarget()
                }
            }
            
            if password.isFavorite {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .accessibilityHidden(true)
                    Text("Favorite")
                        .accessibleFont(.caption)
                        .foregroundColor(.red)
                }
                .accessibilityLabel("This password is marked as favorite")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Password header for \(password.title)" + 
                           (password.website.isEmpty ? "" : ", website: \(password.website)") +
                           (password.isFavorite ? ", marked as favorite" : ""))
    }
    
    private var passwordInfoSection: some View {
        VStack(spacing: 16) {
            DetailRow(
                title: AccessibilityConstants.PasswordManager.usernameField,
                value: password.username,
                icon: "person.fill",
                copyable: true
            )
            
            DetailRow(
                title: AccessibilityConstants.PasswordManager.passwordField,
                value: password.password,
                icon: "key.fill",
                isSecure: !showPassword,
                copyable: true,
                action: {
                    showPassword.toggle()
                    let announcement = showPassword ? "Password revealed" : "Password hidden"
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                },
                actionIcon: showPassword ? "eye.slash" : "eye"
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Credentials section")
    }
    
    private var additionalInfoSection: some View {
        VStack(spacing: 16) {
            if let categoryId = password.categoryId,
               let category = passwordService.categories.first(where: { $0.id == categoryId }) {
                DetailRow(
                    title: AccessibilityConstants.PasswordManager.categoryField,
                    value: category.name,
                    icon: category.icon,
                    iconColor: Color(category.color)
                )
            }
            
            if !password.notes.isEmpty {
                DetailRow(
                    title: AccessibilityConstants.PasswordManager.notesField,
                    value: password.notes,
                    icon: "note.text",
                    multiline: true
                )
            }
            
            DetailRow(
                title: "Created",
                value: formatDate(password.createdAt),
                icon: "calendar"
            )
            
            DetailRow(
                title: "Modified",
                value: formatDate(password.modifiedAt),
                icon: "clock"
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Additional information section")
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ActionButton(
                    title: AccessibilityConstants.PasswordManager.copyUsername,
                    icon: "person.crop.circle",
                    action: {
                        copyToClipboard(password.username)
                        UIAccessibility.post(notification: .announcement, 
                                           argument: AccessibilityConstants.Announcements.usernameCopied)
                    }
                )
                
                ActionButton(
                    title: AccessibilityConstants.PasswordManager.copyPassword,
                    icon: "doc.on.doc",
                    action: {
                        copyToClipboard(password.password)
                        UIAccessibility.post(notification: .announcement, 
                                           argument: AccessibilityConstants.Announcements.passwordCopied)
                    }
                )
            }
            
            if !password.website.isEmpty {
                ActionButton(
                    title: "Open Website",
                    icon: "safari",
                    action: {
                        openWebsite()
                        UIAccessibility.post(notification: .announcement, 
                                           argument: "Opening \(password.website) in browser")
                    },
                    fullWidth: true
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quick actions section")
    }
    
    private var categoryName: String {
        if let categoryId = password.categoryId,
           let category = passwordService.categories.first(where: { $0.id == categoryId }) {
            return category.name
        }
        return "No Category"
    }
    
    private var categoryIcon: String {
        if let categoryId = password.categoryId,
           let category = passwordService.categories.first(where: { $0.id == categoryId }) {
            return category.icon
        }
        return "key.fill"
    }
    
    private var categoryColor: Color {
        if let categoryId = password.categoryId,
           let category = passwordService.categories.first(where: { $0.id == categoryId }) {
            return Color(category.color)
        }
        return .blue
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        
        // Clear clipboard after timeout if enabled
        if settingsService.enableClipboardClear {
            DispatchQueue.main.asyncAfter(deadline: .now() + settingsService.clipboardClearTimeout) {
                if UIPasteboard.general.string == text {
                    UIPasteboard.general.string = ""
                }
            }
        }
    }
    
    private func openWebsite() {
        guard !password.website.isEmpty else { return }
        let urlString = password.website.hasPrefix("http") ? password.website : "https://\(password.website)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = .blue
    var isSecure: Bool = false
    var copyable: Bool = false
    var multiline: Bool = false
    var action: (() -> Void)? = nil
    var actionIcon: String? = nil
    
    var body: some View {
        HStack(alignment: multiline ? .top : .center, spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .accessibleFont(.title3)
                .frame(width: 24)
                .accessibilityHidden(true) // Icon is decorative
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .accessibleFont(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("\(title) field")
                
                if multiline {
                    Text(isSecure ? String(repeating: "•", count: value.count) : value)
                        .accessibleFont(.body)
                        .textSelection(.enabled)
                        .accessibilityLabel(isSecure ? "\(title): hidden" : "\(title): \(value)")
                        .accessibilityValue(isSecure ? "Tap show button to reveal" : value)
                } else {
                    Text(isSecure ? String(repeating: "•", count: value.count) : value)
                        .accessibleFont(.body, design: title == "Password" ? .monospaced : .default)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .accessibilityLabel(isSecure ? "\(title): hidden" : "\(title): \(value)")
                        .accessibilityValue(isSecure ? "Tap show button to reveal" : value)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if copyable {
                    Button(action: {
                        UIPasteboard.general.string = value
                        UIAccessibility.post(notification: .announcement, 
                                           argument: "\(title) copied to clipboard")
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    .accessibilityButton(
                        "Copy \(title.lowercased())",
                        hint: AccessibilityConstants.Hints.tapToCopy
                    )
                    .accessibleTapTarget()
                }
                
                if let action = action, let actionIcon = actionIcon {
                    Button(action: action) {
                        Image(systemName: actionIcon)
                            .foregroundColor(.blue)
                    }
                    .accessibilityButton(
                        isSecure ? AccessibilityConstants.PasswordManager.showPassword : AccessibilityConstants.PasswordManager.hidePassword,
                        hint: isSecure ? AccessibilityConstants.Hints.tapToReveal : "Double tap to hide password"
                    )
                    .accessibleTapTarget()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var fullWidth: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .accessibilityHidden(true)
                Text(title)
                    .fontWeight(.medium)
                    .accessibleFont(.body, weight: .medium)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
        }
        .accessibilityButton(
            title,
            hint: "Double tap to \(title.lowercased())"
        )
        .accessibleTapTarget()
    }
}

#Preview {
    let samplePassword = Password(
        title: "GitHub",
        username: "john.doe@example.com",
        password: "SecurePassword123!",
        website: "github.com",
        notes: "Personal GitHub account for projects",
        isFavorite: true
    )
    
    return PasswordDetailView(password: samplePassword)
        .environmentObject(PasswordService())
        .environmentObject(SettingsService())
        .environmentObject(AccessibilityStateManager())
}