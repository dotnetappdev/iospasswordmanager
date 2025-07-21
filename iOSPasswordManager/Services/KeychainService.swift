import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "iOSPasswordManager"
    private let masterKeyAccount = "MasterKey"
    private let passwordsAccount = "EncryptedPasswords"
    
    private init() {}
    
    // MARK: - Master Key Management
    
    func storeMasterKey(_ key: String) {
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: masterKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing master key first
        deleteMasterKey()
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Failed to store master key: \(status)")
        }
    }
    
    func getMasterKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: masterKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func hasMasterKey() -> Bool {
        return getMasterKey() != nil
    }
    
    func deleteMasterKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: masterKeyAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Encrypted Passwords Management
    
    func storeEncryptedPasswords(_ data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: passwordsAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing passwords first
        deleteEncryptedPasswords()
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Failed to store encrypted passwords: \(status)")
        }
    }
    
    func getEncryptedPasswords() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: passwordsAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return data
    }
    
    func deleteEncryptedPasswords() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: passwordsAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Utility Methods
    
    func clearAllData() {
        deleteMasterKey()
        deleteEncryptedPasswords()
    }
    
    // MARK: - Biometric-Protected Storage
    
    func storeMasterKeyWithBiometrics(_ key: String) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }
        
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            nil
        )
        
        guard access != nil else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "\(masterKeyAccount)_biometric",
            kSecValueData as String: data,
            kSecAttrAccessControl as String: access!
        ]
        
        // Delete any existing biometric-protected key first
        deleteBiometricMasterKey()
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getBiometricMasterKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "\(masterKeyAccount)_biometric",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func deleteBiometricMasterKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "\(masterKeyAccount)_biometric"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}