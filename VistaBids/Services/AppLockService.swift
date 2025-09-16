//
//  AppLockService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-11.
//

import Foundation
import SwiftUI
import Combine

class AppLockService: ObservableObject {
    @Published var isAppLocked: Bool = false
    @Published var shouldShowBiometricPrompt: Bool = false
    @Published var isAuthenticating: Bool = false
    
    private let biometricService = BiometricAuthService()
    private let credentialsService = BiometricCredentialsService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAppLifecycleObservers()
        checkInitialLockState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - App Lifecycle Management
    private func setupAppLifecycleObservers() {
        // Listen for app entering background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Listen for app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Listen for app resigning active (when control center, notifications, etc. are shown)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        print("🔒 App entered background - checking if should lock...")
        lockAppIfBiometricEnabled()
    }
    
    @objc private func appWillEnterForeground() {
        print("🔓 App entering foreground - checking lock state...")
        checkAndPromptBiometricUnlock()
    }
    
    @objc private func appWillResignActive() {
        print("⏸️ App resigning active - preparing for potential lock...")
        // Optionally lock immediately when app loses focus for sensitive apps
        // For now, we'll only lock when actually going to background
    }
    
    // MARK: - Lock State Management
    func checkInitialLockState() {
        // Check if user has Face ID enabled for app lock
        let credentialsService = BiometricCredentialsService()
        let isFaceIDEnabled = credentialsService.isBiometricLoginEnabled
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "has_launched_before")
        
        print("🔍 Checking initial lock state:")
        print("   - Face ID enabled: \(isFaceIDEnabled)")
        print("   - Has launched before: \(hasLaunchedBefore)")
        print("   - Biometric available: \(biometricService.isBiometricAvailable)")
        
        // Lock the app if Face ID is enabled and biometric is available
        // This will be evaluated with user login state in ContentView
        if isFaceIDEnabled && biometricService.isBiometricAvailable {
            print("🔒 App should be locked on startup (will check login state)")
            isAppLocked = true
            shouldShowBiometricPrompt = true // Show prompt immediately for app startup
        } else {
            print("🔓 App unlocked on startup")
            isAppLocked = false
        }
        
        // Mark that the app has been launched
        UserDefaults.standard.set(true, forKey: "has_launched_before")
    }
    
    private func lockAppIfBiometricEnabled() {
        let credentialsService = BiometricCredentialsService()
        let isFaceIDEnabled = credentialsService.isBiometricLoginEnabled
        
        guard isFaceIDEnabled && biometricService.isBiometricAvailable else {
            print("📱 Face ID not enabled or available - not locking app")
            return
        }
        
        print("🔒 Locking app - Face ID authentication required")
        DispatchQueue.main.async {
            self.isAppLocked = true
            self.shouldShowBiometricPrompt = false // Don't show prompt immediately
        }
    }
    
    private func checkAndPromptBiometricUnlock() {
        guard isAppLocked else {
            print("📱 App not locked - no authentication needed")
            return
        }
        
        let isFaceIDAppLockEnabled = UserDefaults.standard.bool(forKey: "face_id_app_lock_enabled")
        
        guard isFaceIDAppLockEnabled && biometricService.isBiometricAvailable else {
            print("📱 Face ID app lock not available - unlocking app")
            DispatchQueue.main.async {
                self.unlockApp()
            }
            return
        }
        
        print("🔓 Prompting for biometric authentication...")
        DispatchQueue.main.async {
            self.shouldShowBiometricPrompt = true
        }
    }
    
    // MARK: - Authentication Methods
    func authenticateWithBiometrics() {
        guard !isAuthenticating else { return }
        guard canUseBiometric else {
            print("❌ Biometric authentication not available")
            unlockApp()
            return
        }
        
        print("🔐 Starting biometric authentication for app unlock...")
        isAuthenticating = true
        
        Task {
            do {
                let success = try await biometricService.authenticateWithBiometrics()
                
                await MainActor.run {
                    self.isAuthenticating = false
                    
                    if success {
                        print("✅ Biometric authentication successful - unlocking app")
                        self.unlockApp()
                    } else {
                        print("❌ Biometric authentication failed")
                        self.handleAuthenticationFailure()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isAuthenticating = false
                    print("❌ Biometric authentication error: \(error.localizedDescription)")
                    
                    if let biometricError = error as? BiometricError {
                        switch biometricError {
                        case .userCancelled:
                            // User cancelled - keep app locked but hide prompt
                            self.shouldShowBiometricPrompt = false
                            print("👤 User cancelled authentication - app remains locked")
                        case .lockout:
                            // Biometric locked - could fallback to passcode or force logout
                            self.handleBiometricLockout()
                        case .missingPrivacyPermission:
                            // Privacy permission missing - show helpful message
                            print("🚫 Privacy permission missing for biometric authentication")
                            self.handlePrivacyPermissionError()
                        default:
                            self.handleAuthenticationFailure()
                        }
                    } else {
                        self.handleAuthenticationFailure()
                    }
                }
            }
        }
    }
    
    private func unlockApp() {
        print("🔓 Unlocking app...")
        isAppLocked = false
        shouldShowBiometricPrompt = false
        isAuthenticating = false
    }
    
    private func handleAuthenticationFailure() {
        print("❌ Handling authentication failure...")
        // Keep app locked, allow user to try again
        shouldShowBiometricPrompt = false
        
        // Show prompt again after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.isAppLocked {
                self.shouldShowBiometricPrompt = true
            }
        }
    }
    
    private func handleBiometricLockout() {
        print("🚫 Biometric authentication locked out")
        // For app lock, we don't need to clear credentials or force logout
        // Just unlock the app and let user try again later
        unlockApp()
    }
    
    private func handlePrivacyPermissionError() {
        print("🚫 Privacy permission error - disabling Face ID app lock")
        // Disable Face ID app lock feature since permission is denied
        UserDefaults.standard.set(false, forKey: "face_id_app_lock_enabled")
        unlockApp()
        
        // Notify about privacy permission issue
        NotificationCenter.default.post(name: .biometricPrivacyPermissionDenied, object: nil)
    }
    
    // MARK: - Manual Control
    func enableFaceIDAppLock() {
        print("🔐 Face ID app lock enabled (managed by BiometricCredentialsService)")
        UserDefaults.standard.set(true, forKey: "has_launched_before")
    }
    
    func disableFaceIDAppLock() {
        print("🔓 Face ID app lock disabled (managed by BiometricCredentialsService)")
        // If app is currently locked, unlock it
        if isAppLocked {
            unlockApp()
        }
    }
    
    func forceUnlock() {
        print("🔓 Force unlocking app...")
        unlockApp()
    }
    
    func forceLock() {
        print("🔒 Force locking app...")
        lockAppIfBiometricEnabled()
    }
    
    // MARK: - Utility Methods
    var canUseBiometric: Bool {
        return biometricService.isBiometricAvailable
    }
    
    var isFaceIDAppLockEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "face_id_app_lock_enabled")
    }
    
    var biometricDisplayName: String {
        return biometricService.biometricDisplayName
    }
    
    var biometricIcon: String {
        return biometricService.biometricIcon
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let biometricLockoutOccurred = Notification.Name("biometricLockoutOccurred")
    static let biometricPrivacyPermissionDenied = Notification.Name("biometricPrivacyPermissionDenied")
    static let forceLogoutRequested = Notification.Name("forceLogoutRequested")
}
