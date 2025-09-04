//
//  BiometricCredentialsService.swift
//  VistaBids
//
//  Created by Assistant on 2025-08-11.
//

import Foundation
import Security

class BiometricCredentialsService: ObservableObject {
    private let keychain = KeychainHelper()
    
    @Published var isBiometricLoginEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricLoginEnabled, forKey: "isBiometricLoginEnabled")
        }
    }
    
    init() {
        self.isBiometricLoginEnabled = UserDefaults.standard.bool(forKey: "isBiometricLoginEnabled")
    }
    
    func storeBiometricCredentials(email: String, password: String) -> Bool {
        let emailStored = keychain.store(key: "VistaBids_userEmail", value: email)
        let passwordStored = keychain.store(key: "VistaBids_userPassword", value: password)
        
        if emailStored && passwordStored {
            isBiometricLoginEnabled = true
            return true
        } else {
            return false
        }
    }
    
    func getBiometricCredentials() -> (email: String, password: String)? {
        guard isBiometricLoginEnabled else { return nil }
        
        guard let email = keychain.retrieve(key: "VistaBids_userEmail"),
              let password = keychain.retrieve(key: "VistaBids_userPassword") else {
            return nil
        }
        
        return (email: email, password: password)
    }
    
    func clearStoredCredentials() {
        keychain.delete(key: "VistaBids_userEmail")
        keychain.delete(key: "VistaBids_userPassword")
        isBiometricLoginEnabled = false
    }
}

// Simple KeychainHelper for BiometricCredentialsService
class KeychainHelper {
    func store(key: String, value: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
