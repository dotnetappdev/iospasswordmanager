import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var masterPassword = ""
    @State private var showingRegistration = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Password Manager")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Secure your digital life")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // Login Form
                    VStack(spacing: 20) {
                        if !showingRegistration {
                            loginForm
                        } else {
                            registrationForm
                        }
                    }
                    .padding(.horizontal, geometry.size.width > 600 ? 100 : 30)
                    
                    Spacer()
                    
                    // Toggle Registration
                    Button(action: {
                        showingRegistration.toggle()
                        masterPassword = ""
                        errorMessage = ""
                    }) {
                        Text(showingRegistration ? "Already have an account? Sign In" : "New user? Create Account")
                            .foregroundColor(.white)
                            .underline()
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            attemptBiometricLogin()
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 16) {
            // Master Password Field
            SecureField("Master Password", text: $masterPassword)
                .textFieldStyle(CustomTextFieldStyle())
                .onSubmit {
                    signIn()
                }
            
            // Sign In Button
            Button(action: signIn) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(masterPassword.isEmpty || isLoading)
            
            // Biometric Authentication Button
            if authService.biometricType != .none && authService.isBiometricEnabled {
                Button(action: signInWithBiometrics) {
                    HStack {
                        Image(systemName: biometricIcon)
                        Text("Use \(biometricText)")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    @State private var email = ""
    @State private var confirmPassword = ""
    
    private var registrationForm: some View {
        VStack(spacing: 16) {
            // Email Field
            TextField("Email", text: $email)
                .textFieldStyle(CustomTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            // Master Password Field
            SecureField("Master Password", text: $masterPassword)
                .textFieldStyle(CustomTextFieldStyle())
            
            // Confirm Password Field
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(CustomTextFieldStyle())
            
            // Password Strength Indicator
            if !masterPassword.isEmpty {
                PasswordStrengthView(password: masterPassword)
            }
            
            // Create Account Button
            Button(action: createAccount) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isValidRegistration || isLoading)
        }
    }
    
    private var biometricIcon: String {
        switch authService.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock"
        }
    }
    
    private var biometricText: String {
        switch authService.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometrics"
        }
    }
    
    private var isValidRegistration: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        masterPassword.count >= 8 &&
        masterPassword == confirmPassword
    }
    
    private func signIn() {
        guard !masterPassword.isEmpty else { return }
        
        isLoading = true
        
        Task {
            let success = await authService.authenticateWithMasterPassword(masterPassword)
            
            await MainActor.run {
                isLoading = false
                if !success {
                    errorMessage = "Invalid master password"
                    showError = true
                    masterPassword = ""
                }
            }
        }
    }
    
    private func signInWithBiometrics() {
        Task {
            let success = await authService.authenticateWithBiometrics()
            
            if !success {
                await MainActor.run {
                    errorMessage = "Biometric authentication failed"
                    showError = true
                }
            }
        }
    }
    
    private func createAccount() {
        guard isValidRegistration else { return }
        
        isLoading = true
        
        Task {
            let success = await authService.registerUser(email: email, masterPassword: masterPassword)
            
            await MainActor.run {
                isLoading = false
                if !success {
                    errorMessage = "Failed to create account. User may already exist."
                    showError = true
                } else {
                    // Account created successfully, user is now logged in
                    masterPassword = ""
                    email = ""
                    confirmPassword = ""
                }
            }
        }
    }
    
    private func attemptBiometricLogin() {
        Task {
            await authService.attemptAutoLogin()
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(.white)
            .font(.body)
    }
}

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: PasswordStrength {
        CryptoService.shared.calculatePasswordStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Password Strength:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(strength.level.description)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForStrength(strength.level))
            }
            
            ProgressView(value: Double(strength.score), total: 7.0)
                .progressViewStyle(LinearProgressViewStyle(tint: colorForStrength(strength.level)))
        }
        .padding(.horizontal)
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

#Preview {
    LoginView()
        .environmentObject(AuthenticationService())
}