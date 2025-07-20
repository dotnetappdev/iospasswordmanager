import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var accessibilityStateManager: AccessibilityStateManager
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
                .accessibilityHidden(true)
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .accessibleFont(size: 80)
                            .foregroundColor(.white)
                            .accessibilityLabel("Password Manager app icon")
                        
                        Text("Password Manager")
                            .accessibleFont(.largeTitle, weight: .bold)
                            .foregroundColor(.white)
                            .accessibilityHeading("Password Manager")
                        
                        Text("Secure your digital life")
                            .accessibleFont(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .accessibilityLabel("App tagline: Secure your digital life")
                    }
                    .accessibilityGroup()
                    
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
                        
                        // Announce the form change
                        let announcement = showingRegistration ? 
                            AccessibilityConstants.Announcements.loginSuccessful : 
                            "Switched to sign in form"
                        UIAccessibility.post(notification: .screenChanged, argument: announcement)
                    }) {
                        Text(showingRegistration ? "Already have an account? Sign In" : "New user? Create Account")
                            .foregroundColor(.white)
                            .underline()
                            .accessibleFont(.body)
                    }
                    .accessibilityButton(
                        showingRegistration ? "Switch to sign in" : "Switch to create account",
                        hint: "Double tap to toggle between sign in and registration forms"
                    )
                    .accessibleTapTarget()
                    .padding(.bottom, 50)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { 
                UIAccessibility.post(notification: .announcement, argument: "Error dismissed")
            }
            .accessibilityButton(AccessibilityConstants.Labels.close)
        } message: {
            Text(errorMessage)
                .accessibilityLabel("Error message: \(errorMessage)")
        }
        .onAppear {
            attemptBiometricLogin()
            UIAccessibility.post(notification: .screenChanged, argument: showingRegistration ? "Registration form" : "Sign in form")
        }
        .onChange(of: showError) { newValue in
            if newValue {
                UIAccessibility.post(notification: .announcement, argument: "Error: \(errorMessage)")
            }
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 16) {
            // Master Password Field
            SecureField("Master Password", text: $masterPassword)
                .textFieldStyle(CustomTextFieldStyle())
                .accessibilityTextField(
                    AccessibilityConstants.PasswordManager.passwordField,
                    hint: AccessibilityConstants.Hints.masterPasswordHint
                )
                .accessibilityId("masterPasswordField")
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
                            .accessibilityHidden(true)
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
            .accessibilityButton(
                isLoading ? "Signing in, please wait" : "Sign In",
                hint: masterPassword.isEmpty ? "Enter your master password first" : "Double tap to sign in to your account"
            )
            .accessibilityId("signInButton")
            .accessibleTapTarget()
            
            // Biometric Authentication Button
            if authService.biometricType != .none && authService.isBiometricEnabled {
                Button(action: signInWithBiometrics) {
                    HStack {
                        Image(systemName: biometricIcon)
                            .accessibilityHidden(true)
                        Text("Use \(biometricText)")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .accessibilityButton(
                    "Use \(biometricText)",
                    hint: AccessibilityConstants.Hints.biometricAuthHint
                )
                .accessibilityId("biometricButton")
                .accessibleTapTarget()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sign in form")
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
                .accessibilityTextField(
                    AccessibilityConstants.PasswordManager.emailField,
                    hint: "Enter your email address for your new account"
                )
                .accessibilityId("emailField")
            
            // Master Password Field
            SecureField("Master Password", text: $masterPassword)
                .textFieldStyle(CustomTextFieldStyle())
                .accessibilityTextField(
                    AccessibilityConstants.PasswordManager.passwordField,
                    hint: "Create a strong master password. Must be at least 8 characters."
                )
                .accessibilityId("newPasswordField")
            
            // Confirm Password Field
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(CustomTextFieldStyle())
                .accessibilityTextField(
                    "Confirm password",
                    hint: "Re-enter your master password to confirm"
                )
                .accessibilityId("confirmPasswordField")
            
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
                            .accessibilityHidden(true)
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
            .accessibilityButton(
                isLoading ? "Creating account, please wait" : "Create Account",
                hint: !isValidRegistration ? "Complete all fields with valid information first" : "Double tap to create your new account"
            )
            .accessibilityId("createAccountButton")
            .accessibleTapTarget()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Create account form")
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
        UIAccessibility.post(notification: .announcement, argument: "Signing in")
        
        Task {
            let success = await authService.authenticateWithMasterPassword(masterPassword)
            
            await MainActor.run {
                isLoading = false
                if !success {
                    errorMessage = "Invalid master password"
                    showError = true
                    masterPassword = ""
                    UIAccessibility.post(notification: .announcement, argument: AccessibilityConstants.Announcements.loginFailed)
                } else {
                    UIAccessibility.post(notification: .announcement, argument: AccessibilityConstants.Announcements.loginSuccessful)
                }
            }
        }
    }
    
    private func signInWithBiometrics() {
        UIAccessibility.post(notification: .announcement, argument: "Authenticating with \(biometricText)")
        
        Task {
            let success = await authService.authenticateWithBiometrics()
            
            if !success {
                await MainActor.run {
                    errorMessage = "Biometric authentication failed"
                    showError = true
                    UIAccessibility.post(notification: .announcement, argument: AccessibilityConstants.Announcements.loginFailed)
                }
            } else {
                await MainActor.run {
                    UIAccessibility.post(notification: .announcement, argument: AccessibilityConstants.Announcements.loginSuccessful)
                }
            }
        }
    }
    
    private func createAccount() {
        guard isValidRegistration else { return }
        
        isLoading = true
        UIAccessibility.post(notification: .announcement, argument: "Creating account")
        
        Task {
            let success = await authService.registerUser(email: email, masterPassword: masterPassword)
            
            await MainActor.run {
                isLoading = false
                if !success {
                    errorMessage = "Failed to create account. User may already exist."
                    showError = true
                    UIAccessibility.post(notification: .announcement, argument: AccessibilityConstants.Announcements.errorOccurred)
                } else {
                    // Account created successfully, user is now logged in
                    masterPassword = ""
                    email = ""
                    confirmPassword = ""
                    UIAccessibility.post(notification: .announcement, argument: "Account created successfully")
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
            .accessibleFont(.body)
            .accessibleTapTarget(minSize: 44)
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
                    .accessibleFont(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(strength.level.description)
                    .accessibleFont(.caption, weight: .semibold)
                    .foregroundColor(colorForStrength(strength.level))
            }
            .accessibilityGroup()
            .accessibilityLabel("Password strength: \(strength.level.description)")
            .accessibilityValue("\(Int((Double(strength.score) / 7.0) * 100)) percent")
            
            ProgressView(value: Double(strength.score), total: 7.0)
                .progressViewStyle(LinearProgressViewStyle(tint: colorForStrength(strength.level)))
                .accessibilityHidden(true) // Already described in the text above
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
        .environmentObject(AccessibilityStateManager())
}