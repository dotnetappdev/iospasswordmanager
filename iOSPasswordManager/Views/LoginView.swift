import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @EnvironmentObject var passwordManager: PasswordManager
    @State private var masterKey = ""
    @State private var showingQRScanner = false
    @State private var showingBiometricPrompt = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isFirstLaunch = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo/Icon
                Image(systemName: "lock.shield")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("iOS Password Manager")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 20) {
                    // Master Key Input
                    SecureField("Enter Master Key", text: $masterKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            authenticateWithMasterKey()
                        }
                    
                    // Login Button
                    Button(action: {
                        authenticateWithMasterKey()
                    }) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(masterKey.isEmpty)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("OR")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    
                    // QR Code Scanner Button
                    Button(action: {
                        showingQRScanner = true
                    }) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Scan QR Code")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    
                    // Biometric Authentication Button (if available)
                    if BiometricAuthService().biometricType != .none {
                        Button(action: {
                            authenticateWithBiometrics()
                        }) {
                            HStack {
                                Image(systemName: BiometricAuthService().biometricType == .faceID ? "faceid" : "touchid")
                                Text("Use \(BiometricAuthService().biometricType == .faceID ? "Face ID" : "Touch ID")")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(10)
                        }
                        .opacity(KeychainService.shared.hasMasterKey() ? 1.0 : 0.5)
                        .disabled(!KeychainService.shared.hasMasterKey())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingQRScanner) {
                QRScannerView { result in
                    handleQRScanResult(result)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                checkFirstLaunch()
            }
            .alert("Enable Biometric Authentication?", isPresented: $showingBiometricPrompt) {
                Button("Yes") {
                    enableBiometricAuth()
                }
                Button("No", role: .cancel) { }
            } message: {
                Text("Would you like to use \(BiometricAuthService().biometricType == .faceID ? "Face ID" : "Touch ID") for quick access in the future?")
            }
        }
    }
    
    private func checkFirstLaunch() {
        isFirstLaunch = !KeychainService.shared.hasMasterKey()
    }
    
    private func authenticateWithMasterKey() {
        Task {
            let success = await passwordManager.authenticateWithMasterKey(masterKey)
            
            await MainActor.run {
                if success {
                    if isFirstLaunch && BiometricAuthService().biometricType != .none {
                        showingBiometricPrompt = true
                    } else {
                        isAuthenticated = true
                    }
                } else {
                    errorMessage = "Invalid master key. Please try again."
                    showError = true
                }
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        Task {
            let biometricAuth = BiometricAuthService()
            let success = await biometricAuth.authenticateWithBiometrics()
            
            await MainActor.run {
                if success {
                    // Load the master key from keychain and authenticate
                    if let storedMasterKey = KeychainService.shared.getMasterKey() {
                        Task {
                            let authSuccess = await passwordManager.authenticateWithMasterKey(storedMasterKey)
                            await MainActor.run {
                                if authSuccess {
                                    isAuthenticated = true
                                } else {
                                    errorMessage = "Failed to authenticate with stored master key."
                                    showError = true
                                }
                            }
                        }
                    } else {
                        errorMessage = "No master key found in secure storage."
                        showError = true
                    }
                } else {
                    errorMessage = "Biometric authentication failed."
                    showError = true
                }
            }
        }
    }
    
    private func handleQRScanResult(_ result: String) {
        // Parse QR code result - assuming it contains the master key
        // In a real implementation, this might be a more complex protocol
        masterKey = result
        authenticateWithMasterKey()
    }
    
    private func enableBiometricAuth() {
        // Store the master key in keychain for biometric access
        KeychainService.shared.storeMasterKey(masterKey)
        isAuthenticated = true
    }
}

#Preview {
    LoginView(isAuthenticated: .constant(false))
        .environmentObject(PasswordManager())
}