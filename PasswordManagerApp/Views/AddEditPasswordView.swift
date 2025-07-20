import SwiftUI

struct AddEditPasswordView: View {
    @EnvironmentObject var passwordService: PasswordService
    @Environment(\.dismiss) private var dismiss
    
    let passwordToEdit: Password?
    
    @State private var title = ""
    @State private var username = ""
    @State private var password = ""
    @State private var website = ""
    @State private var notes = ""
    @State private var selectedCategoryId: UUID?
    @State private var isFavorite = false
    @State private var showPassword = false
    @State private var showingGenerator = false
    
    init(password: Password? = nil) {
        self.passwordToEdit = password
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Title", text: $title)
                    TextField("Username/Email", text: $username)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                
                Section("Password") {
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            showingGenerator = true
                        }) {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if !password.isEmpty {
                        PasswordStrengthMeter(password: password)
                    }
                }
                
                Section("Additional Information") {
                    TextField("Website", text: $website)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("No Category").tag(UUID?.none)
                        ForEach(passwordService.categories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.name)
                            }
                            .tag(UUID?.some(category.id))
                        }
                    }
                    
                    Toggle("Add to Favorites", isOn: $isFavorite)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(passwordToEdit == nil ? "Add Password" : "Edit Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePassword()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingGenerator) {
                PasswordGeneratorSheet { generatedPassword in
                    password = generatedPassword
                }
            }
        }
        .onAppear {
            loadPasswordData()
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !username.isEmpty && !password.isEmpty
    }
    
    private func loadPasswordData() {
        if let passwordToEdit = passwordToEdit {
            title = passwordToEdit.title
            username = passwordToEdit.username
            password = passwordToEdit.password
            website = passwordToEdit.website
            notes = passwordToEdit.notes
            selectedCategoryId = passwordToEdit.categoryId
            isFavorite = passwordToEdit.isFavorite
        }
    }
    
    private func savePassword() {
        if let passwordToEdit = passwordToEdit {
            // Edit existing password
            var updatedPassword = passwordToEdit
            updatedPassword.update(
                title: title,
                username: username,
                password: password,
                website: website,
                notes: notes,
                categoryId: selectedCategoryId,
                isFavorite: isFavorite
            )
            passwordService.updatePassword(updatedPassword)
        } else {
            // Create new password
            let newPassword = Password(
                title: title,
                username: username,
                password: password,
                website: website,
                notes: notes,
                categoryId: selectedCategoryId,
                isFavorite: isFavorite
            )
            passwordService.addPassword(newPassword)
        }
        
        dismiss()
    }
}

struct PasswordStrengthMeter: View {
    let password: String
    
    private var strength: PasswordStrength {
        CryptoService.shared.calculatePasswordStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Strength:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(strength.level.description)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForStrength(strength.level))
                
                Spacer()
                
                Text("\(strength.score)/7")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(strength.score), total: 7.0)
                .progressViewStyle(LinearProgressViewStyle(tint: colorForStrength(strength.level)))
            
            if !strength.feedback.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(strength.feedback, id: \.self) { feedback in
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(feedback)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func colorForStrength(_ level: PasswordStrengthLevel) -> Color {
        switch level {
        case .weak:
            return .red
        case .fair:
            return .orange
        case .good:
            return .yellow
        case .strong:
            return .green
        }
    }
}

struct PasswordGeneratorSheet: View {
    let onPasswordGenerated: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsService: SettingsService
    
    @State private var length: Double = 16
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var generatedPassword = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Length: \(Int(length))")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Slider(value: $length, in: 4...128, step: 1)
                        .onChange(of: length) { _, _ in generatePassword() }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Uppercase Letters (A-Z)", isOn: $includeUppercase)
                            .onChange(of: includeUppercase) { _, _ in generatePassword() }
                        
                        Toggle("Lowercase Letters (a-z)", isOn: $includeLowercase)
                            .onChange(of: includeLowercase) { _, _ in generatePassword() }
                        
                        Toggle("Numbers (0-9)", isOn: $includeNumbers)
                            .onChange(of: includeNumbers) { _, _ in generatePassword() }
                        
                        Toggle("Symbols (!@#$...)", isOn: $includeSymbols)
                            .onChange(of: includeSymbols) { _, _ in generatePassword() }
                    }
                }
                .padding()
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Generated Password")
                            .font(.headline)
                        Spacer()
                        Button("Regenerate") {
                            generatePassword()
                        }
                        .font(.caption)
                    }
                    
                    HStack {
                        Text(generatedPassword)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                        
                        Button(action: {
                            UIPasteboard.general.string = generatedPassword
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    
                    if !generatedPassword.isEmpty {
                        PasswordStrengthMeter(password: generatedPassword)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Password Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Use Password") {
                        onPasswordGenerated(generatedPassword)
                        dismiss()
                    }
                    .disabled(generatedPassword.isEmpty)
                }
            }
        }
        .onAppear {
            loadSettings()
            generatePassword()
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
}

#Preview {
    AddEditPasswordView()
        .environmentObject(PasswordService())
        .environmentObject(SettingsService())
}