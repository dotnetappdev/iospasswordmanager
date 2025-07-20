import SwiftUI

struct ContentView: View {
    @StateObject private var passwordManager = PasswordManager()
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                PasswordListView()
                    .environmentObject(passwordManager)
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
                    .environmentObject(passwordManager)
            }
        }
        .onAppear {
            // Check if user has biometric authentication enabled and master key stored
            Task {
                await checkBiometricAuth()
            }
        }
    }
    
    private func checkBiometricAuth() async {
        let biometricAuth = BiometricAuthService()
        if await biometricAuth.canUseBiometrics() && KeychainService.shared.hasMasterKey() {
            let result = await biometricAuth.authenticateWithBiometrics()
            if result {
                isAuthenticated = true
            }
        }
    }
}

struct PasswordListView: View {
    @EnvironmentObject var passwordManager: PasswordManager
    @State private var showingAddPassword = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(passwordManager.passwords) { password in
                    PasswordRowView(password: password)
                }
            }
            .navigationTitle("Passwords")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddPassword = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        passwordManager.logout()
                    }
                }
            }
            .sheet(isPresented: $showingAddPassword) {
                AddPasswordView()
                    .environmentObject(passwordManager)
            }
        }
    }
}

struct PasswordRowView: View {
    let password: PasswordEntry
    @State private var showingDetails = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(password.title)
                    .font(.headline)
                Text(password.username)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                UIPasteboard.general.string = password.password
            }) {
                Image(systemName: "doc.on.clipboard")
                    .foregroundColor(.blue)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetails = true
        }
        .sheet(isPresented: $showingDetails) {
            PasswordDetailView(password: password)
        }
    }
}

struct PasswordDetailView: View {
    let password: PasswordEntry
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    HStack {
                        Text("Title:")
                            .font(.headline)
                        Spacer()
                        Text(password.title)
                        Button(action: {
                            UIPasteboard.general.string = password.title
                        }) {
                            Image(systemName: "doc.on.clipboard")
                        }
                    }
                    
                    HStack {
                        Text("Username:")
                            .font(.headline)
                        Spacer()
                        Text(password.username)
                        Button(action: {
                            UIPasteboard.general.string = password.username
                        }) {
                            Image(systemName: "doc.on.clipboard")
                        }
                    }
                    
                    HStack {
                        Text("Password:")
                            .font(.headline)
                        Spacer()
                        Text(String(repeating: "•", count: password.password.count))
                        Button(action: {
                            UIPasteboard.general.string = password.password
                        }) {
                            Image(systemName: "doc.on.clipboard")
                        }
                    }
                    
                    if !password.website.isEmpty {
                        HStack {
                            Text("Website:")
                                .font(.headline)
                            Spacer()
                            Text(password.website)
                            Button(action: {
                                UIPasteboard.general.string = password.website
                            }) {
                                Image(systemName: "doc.on.clipboard")
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Password Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct AddPasswordView: View {
    @EnvironmentObject var passwordManager: PasswordManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var username = ""
    @State private var password = ""
    @State private var website = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Password Information")) {
                    TextField("Title", text: $title)
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                    TextField("Website (optional)", text: $website)
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
                        let newPassword = PasswordEntry(
                            title: title,
                            username: username,
                            password: password,
                            website: website
                        )
                        passwordManager.addPassword(newPassword)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty || username.isEmpty || password.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}