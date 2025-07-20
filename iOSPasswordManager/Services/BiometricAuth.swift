import Foundation
import LocalAuthentication

enum BiometricType {
    case none
    case touchID
    case faceID
}

class BiometricAuthService {
    private let context = LAContext()
    
    var biometricType: BiometricType {
        guard canUseBiometrics() else { return .none }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
    
    func canUseBiometrics() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func authenticateWithBiometrics() async -> Bool {
        guard canUseBiometrics() else {
            print("Biometric authentication not available")
            return false
        }
        
        do {
            let reason = "Authenticate to access your passwords"
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return result
        } catch {
            print("Biometric authentication failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func authenticateWithPasscode() async -> Bool {
        do {
            let reason = "Authenticate to access your passwords"
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return result
        } catch {
            print("Passcode authentication failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func getBiometricAuthError() -> String? {
        var error: NSError?
        guard !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return nil
        }
        
        guard let authError = error else {
            return "Unknown biometric authentication error"
        }
        
        switch LAError.Code(rawValue: authError.code) {
        case .biometryNotEnrolled:
            return "Biometric authentication is not set up on this device"
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometryLockout:
            return "Biometric authentication is locked out. Please use your passcode"
        case .userCancel:
            return "Authentication was cancelled by user"
        case .userFallback:
            return "User chose to use passcode instead"
        case .systemCancel:
            return "Authentication was cancelled by system"
        case .passcodeNotSet:
            return "Passcode is not set on this device"
        case .touchIDNotAvailable:
            return "Touch ID is not available on this device"
        case .touchIDNotEnrolled:
            return "Touch ID is not set up on this device"
        case .touchIDLockout:
            return "Touch ID is locked out. Please use your passcode"
        default:
            return authError.localizedDescription
        }
    }
    
    // MARK: - Utility Methods
    
    func promptForBiometricSetup() -> String {
        switch biometricType {
        case .faceID:
            return "Would you like to use Face ID for quick and secure access to your passwords?"
        case .touchID:
            return "Would you like to use Touch ID for quick and secure access to your passwords?"
        case .none:
            return "Biometric authentication is not available on this device."
        }
    }
    
    func getBiometricButtonTitle() -> String {
        switch biometricType {
        case .faceID:
            return "Use Face ID"
        case .touchID:
            return "Use Touch ID"
        case .none:
            return "Biometric Auth"
        }
    }
    
    func getBiometricIcon() -> String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "person.fill.checkmark"
        }
    }
    
    // MARK: - Advanced Authentication
    
    func authenticateWithBiometricsAndFallback() async -> Bool {
        // First try biometric authentication
        if canUseBiometrics() {
            let biometricResult = await authenticateWithBiometrics()
            if biometricResult {
                return true
            }
        }
        
        // If biometric fails or is not available, try passcode
        return await authenticateWithPasscode()
    }
    
    func isDeviceSecure() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
}