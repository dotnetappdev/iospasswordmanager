import SwiftUI

struct ContentView: View {
    @StateObject private var passwordManager = PasswordManager()
    @State private var masterKey: String = ""
    @State private var showingDatabaseInfo = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if passwordManager.isAuthenticated {
                    AuthenticatedView(passwordManager: passwordManager)
                } else {
                    LoginView(passwordManager: passwordManager)
                }
            }
            .navigationTitle("Password Manager")
            .toolbar {
                if passwordManager.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Info") {
                            showingDatabaseInfo = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingDatabaseInfo) {
                DatabaseInfoView(passwordManager: passwordManager)
            }
        }
    }
}

struct LoginView: View {
    @ObservedObject var passwordManager: PasswordManager
    @State private var masterKey: String = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Master Key")
                .font(.title2)
                .fontWeight(.semibold)
            
            SecureField("Master Key", text: $masterKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isLoading)
            
            Button("Unlock") {
                authenticateUser()
            }
            .buttonStyle(.borderedProminent)
            .disabled(masterKey.isEmpty || isLoading)
            
            if isLoading {
                ProgressView("Authenticating...")
            }
        }
        .padding()
    }
    
    private func authenticateUser() {
        isLoading = true
        Task {
            let success = await passwordManager.authenticateWithMasterKey(masterKey)
            await MainActor.run {
                isLoading = false
                if !success {
                    masterKey = ""
                }
            }
        }
    }
}

struct AuthenticatedView: View {
    @ObservedObject var passwordManager: PasswordManager
    @State private var showingAddPassword = false
    
    var body: some View {
        VStack {
            List {
                ForEach(passwordManager.passwords) { password in
                    PasswordRowView(password: password, passwordManager: passwordManager)
                }
                .onDelete(perform: deletePasswords)
            }
            
            Button("Add Password") {
                showingAddPassword = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            Button("Logout") {
                passwordManager.logout()
            }
            .buttonStyle(.bordered)
        }
        .sheet(isPresented: $showingAddPassword) {
            AddPasswordView(passwordManager: passwordManager)
        }
    }
    
    private func deletePasswords(offsets: IndexSet) {
        for index in offsets {
            passwordManager.deletePassword(passwordManager.passwords[index])
        }
    }
}

struct PasswordRowView: View {
    let password: PasswordEntry
    @ObservedObject var passwordManager: PasswordManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(password.title)
                .font(.headline)
            Text(password.username)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if !password.website.isEmpty {
                Text(password.website)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            passwordManager.copyToClipboard(password.password)
        }
    }
}

struct AddPasswordView: View {
    @ObservedObject var passwordManager: PasswordManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var website: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Password Details") {
                    TextField("Title", text: $title)
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                    TextField("Website (optional)", text: $website)
                }
                
                Section {
                    Button("Generate Strong Password") {
                        password = passwordManager.generateStrongPassword()
                    }
                }
            }
            .navigationTitle("Add Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePassword()
                    }
                    .disabled(title.isEmpty || username.isEmpty || password.isEmpty)
                }
            }
        }
    }
    
    private func savePassword() {
        let newPassword = PasswordEntry(
            title: title,
            username: username,
            password: password,
            website: website
        )
        passwordManager.addPassword(newPassword)
        presentationMode.wrappedValue.dismiss()
    }
}

struct DatabaseInfoView: View {
    @ObservedObject var passwordManager: PasswordManager
    @Environment(\.presentationMode) var presentationMode
    @State private var databaseInfo: [String: Any] = [:]
    
    var body: some View {
        NavigationView {
            List {
                Section("Database Information") {
                    ForEach(Array(databaseInfo.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key.capitalized)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(databaseInfo[key] ?? "N/A")")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Vacuum Database") {
                        passwordManager.vacuumDatabase()
                        loadDatabaseInfo()
                    }
                    
                    Button("Clear All Data", role: .destructive) {
                        passwordManager.clearAllData()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Database Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                loadDatabaseInfo()
            }
        }
    }
    
    private func loadDatabaseInfo() {
        databaseInfo = passwordManager.getDatabaseInfo()
    }
}

#Preview {
    ContentView()
}