import SwiftUI

struct PasswordDetailView: View {
    let password: Password
    @EnvironmentObject var passwordService: PasswordService
    @EnvironmentObject var settingsService: SettingsService
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit") {
                            showingEdit = true
                        }
                        
                        Button("Toggle Favorite") {
                            passwordService.toggleFavorite(password)
                        }
                        
                        Divider()
                        
                        Button("Delete", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                AddEditPasswordView(password: password)
            }
            .alert("Delete Password", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    passwordService.deletePassword(password)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this password? This action cannot be undone.")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 32))
                    .foregroundColor(categoryColor)
            }
            
            VStack(spacing: 4) {
                Text(password.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if !password.website.isEmpty {
                    Link(password.website, destination: URL(string: password.website.hasPrefix("http") ? password.website : "https://\(password.website)") ?? URL(string: "https://google.com")!)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if password.isFavorite {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Favorite")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var passwordInfoSection: some View {
        VStack(spacing: 16) {
            DetailRow(
                title: "Username",
                value: password.username,
                icon: "person.fill",
                copyable: true
            )
            
            DetailRow(
                title: "Password",
                value: password.password,
                icon: "key.fill",
                isSecure: !showPassword,
                copyable: true,
                action: {
                    showPassword.toggle()
                },
                actionIcon: showPassword ? "eye.slash" : "eye"
            )
        }
    }
    
    private var additionalInfoSection: some View {
        VStack(spacing: 16) {
            if let categoryId = password.categoryId,
               let category = passwordService.categories.first(where: { $0.id == categoryId }) {
                DetailRow(
                    title: "Category",
                    value: category.name,
                    icon: category.icon,
                    iconColor: Color(category.color)
                )
            }
            
            if !password.notes.isEmpty {
                DetailRow(
                    title: "Notes",
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
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ActionButton(
                    title: "Copy Username",
                    icon: "person.crop.circle",
                    action: {
                        copyToClipboard(password.username)
                    }
                )
                
                ActionButton(
                    title: "Copy Password",
                    icon: "doc.on.doc",
                    action: {
                        copyToClipboard(password.password)
                    }
                )
            }
            
            if !password.website.isEmpty {
                ActionButton(
                    title: "Open Website",
                    icon: "safari",
                    action: {
                        openWebsite()
                    },
                    fullWidth: true
                )
            }
        }
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
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if multiline {
                    Text(isSecure ? String(repeating: "•", count: value.count) : value)
                        .font(.body)
                        .textSelection(.enabled)
                } else {
                    Text(isSecure ? String(repeating: "•", count: value.count) : value)
                        .font(.system(.body, design: title == "Password" ? .monospaced : .default))
                        .textSelection(.enabled)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if copyable {
                    Button(action: {
                        UIPasteboard.general.string = value
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
                
                if let action = action, let actionIcon = actionIcon {
                    Button(action: action) {
                        Image(systemName: actionIcon)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
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
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
        }
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
}