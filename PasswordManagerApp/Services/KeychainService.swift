import Foundation
import Security

class KeychainService {
    
    private let masterPasswordKey = "com.passwordmanager.masterpassword"
    private let service = "PasswordManagerApp"
    
    // MARK: - Master Password Storage
    func storeMasterPassword(_ password: String) {
        storeData(Data(password.utf8), for: masterPasswordKey)
    }
    
    func retrieveMasterPassword() -> String? {
        guard let data = retrieveData(for: masterPasswordKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func deleteMasterPassword() {
        deleteData(for: masterPasswordKey)
    }
    
    // MARK: - Generic Keychain Operations
    func storeData(_ data: Data, for key: String) {
        // Delete existing item first
        deleteData(for: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Failed to store data in keychain: \(status)")
        }
    }
    
    func retrieveData(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else {
            print("Failed to retrieve data from keychain: \(status)")
            return nil
        }
    }
    
    func deleteData(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Failed to delete data from keychain: \(status)")
        }
    }
    
    // MARK: - Biometric Protected Storage
    func storeBiometricProtectedData(_ data: Data, for key: String) {
        deleteData(for: key)
        
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            nil
        )
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: accessControl as Any
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Failed to store biometric protected data: \(status)")
        }
    }
    
    func retrieveBiometricProtectedData(for key: String, reason: String) async -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseOperationPrompt as String: reason
        ]
        
        return await withCheckedContinuation { continuation in
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            if status == errSecSuccess {
                continuation.resume(returning: result as? Data)
            } else {
                print("Failed to retrieve biometric protected data: \(status)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Utility Methods
    func clearAllKeychainData() {
        let classes = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for secClass in classes {
            let query: [String: Any] = [
                kSecClass as String: secClass,
                kSecAttrService as String: service
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
    
    func isKeychainDataAvailable(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}