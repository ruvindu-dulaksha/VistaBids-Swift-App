//
//  BiometricAuthService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-06.
//

import Foundation
import LocalAuthentication
import SwiftUI

class BiometricAuthService: ObservableObject {
    @Published var isBiometricAvailable = false
    @Published var biometricType: LABiometryType = .none
    @Published var isAuthenticating = false
    
    private let context = LAContext()
    
    init() {
        checkBiometricAvailability()
    }
    
    //Check Biometric Availability
    func checkBiometricAvailability() {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            DispatchQueue.main.async {
                self.isBiometricAvailable = false
                self.biometricType = .none
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isBiometricAvailable = true
            self.biometricType = self.context.biometryType
            
            switch self.biometricType {
            case .faceID:
                print("Face ID is available")
            case .touchID:
                print("Touch ID is available")
            case .opticID:
                print("Optic ID is available")
            default:
                print("Biometric authentication available but type unknown")
            }
        }
    }
    
    //  Authenticate with Biometrics
    func authenticateWithBiometrics() async throws -> Bool {
        guard isBiometricAvailable else {
            throw BiometricError.notAvailable
        }
        
        await MainActor.run {
            isAuthenticating = true
        }
        
        let reason = "Use \(biometricDisplayName) to sign in to VistaBids"
        
        do {
            print("🔐 Starting biometric authentication...")
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                isAuthenticating = false
            }
            
            if result {
                print(" Biometric authentication successful")
                return true
            } else {
                print("Biometric authentication failed")
                throw BiometricError.authenticationFailed
            }
        } catch {
            await MainActor.run {
                isAuthenticating = false
            }
            
            print("Biometric authentication error: \(error.localizedDescription)")
            throw mapLAError(error)
        }
    }
    
    // Helper Properties
    var biometricDisplayName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric Authentication"
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "person.fill.checkmark"
        }
    }
    
    // Error Mapping
    private func mapLAError(_ error: Error) -> BiometricError {
        guard let laError = error as? LAError else {
            return BiometricError.unknown(error.localizedDescription)
        }
        
        switch laError.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .invalidContext:
            // This can happen when privacy permissions are missing
            return .missingPrivacyPermission
        default:
            // Check if the error message contains privacy-related keywords
            let errorMessage = laError.localizedDescription.lowercased()
            if errorMessage.contains("privacy") || errorMessage.contains("usage description") {
                return .missingPrivacyPermission
            }
            return .unknown(laError.localizedDescription)
        }
    }
}

//  Biometric Errors
enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancelled
    case userFallback
    case lockout
    case missingPrivacyPermission
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings"
        case .authenticationFailed:
            return "Biometric authentication failed. Please try again"
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "User chose to use passcode instead"
        case .lockout:
            return "Biometric authentication is locked. Please use passcode"
        case .missingPrivacyPermission:
            return "Face ID access not granted. Please allow Face ID access in app settings to use this feature"
        case .unknown(let message):
            return "Biometric authentication error: \(message)"
        }
    }
}
