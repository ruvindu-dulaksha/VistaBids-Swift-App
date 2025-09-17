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
    @Published var shouldShowBiometric: Bool = false
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
    
    // App Lifecycle Management
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
        checkAndBiometricUnlock()
    }
    
    @objc private func appWillResignActive() {
        print("⏸️ App resigning active - preparing for potential lock...")
        
    }
    
    // Lock State Management
    func checkInitialLockState() {
        // Check if user has Face ID enabled for app lock
        let credentialsService = BiometricCredentialsService()
        let isFaceIDEnabled = credentialsService.isBiometricLoginEnabled
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "has_launched_before")
        
        print("🔍 Checking initial lock state:")
        print("   - Face ID enabled: \(isFaceIDEnabled)")
        print("   - Has launched before: \(hasLaunchedBefore)")
        print("   - Biometric available: \(biometricService.isBiometricAvailable)")
        
        
        if isFaceIDEnabled && biometricService.isBiometricAvailable {
            print("🔒 App should be locked on startup (will check login state)")
            isAppLocked = true
            shouldShowBiometric = true
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
            return
        }
        
       DispatchQueue.main.async {
            self.isAppLocked = true
            self.shouldShowBiometric = false
        }
    }
    
    private func checkAndBiometricUnlock() {
        guard isAppLocked else {
            return
        }
        
        let isFaceIDAppLockEnabled = UserDefaults.standard.bool(forKey: "face_id_app_lock_enabled")
        
        guard isFaceIDAppLockEnabled && biometricService.isBiometricAvailable else {
            
            DispatchQueue.main.async {
                self.unlockApp()
            }
            return
        }
        
       
        DispatchQueue.main.async {
            self.shouldShowBiometric = true
        }
    }
    
    // Authentication function
    func authenticateWithBiometrics() {
        guard !isAuthenticating else { return }
        guard canUseBiometric else {
           
            unlockApp()
            return
        }
        
        
        isAuthenticating = true
        
        Task {
            do {
                let success = try await biometricService.authenticateWithBiometrics()
                
                await MainActor.run {
                    self.isAuthenticating = false
                    
                    if success {
                       self.unlockApp()
                    } else {
                       self.handleAuthenticationFailure()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isAuthenticating = false
                    
                    if let biometricError = error as? BiometricError {
                        switch biometricError {
                        case .userCancelled:
                            // User cancelled
                            self.shouldShowBiometric = false
                        case .lockout:
                            // Biometric locked
                            self.handleBiometricLockout()
                        case .missingPrivacyPermission:
                            // Privacy permission missing
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
        isAppLocked = false
        shouldShowBiometric = false
        isAuthenticating = false
    }
    
    private func handleAuthenticationFailure() {
        // Keep app locked, allow user to try again
        shouldShowBiometric = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.isAppLocked {
                self.shouldShowBiometric = true
            }
        }
    }
    
    private func handleBiometricLockout() {
        unlockApp()
    }
    
    private func handlePrivacyPermissionError() {
       UserDefaults.standard.set(false, forKey: "face_id_app_lock_enabled")
        unlockApp()
        
        // Notify about privacy permission issue
        NotificationCenter.default.post(name: .biometricPrivacyPermissionDenied, object: nil)
    }
    
    
    func enableFaceIDAppLock() {
        UserDefaults.standard.set(true, forKey: "has_launched_before")
    }
    
    func disableFaceIDAppLock() {
       if isAppLocked {
            unlockApp()
        }
    }
    
    func forceUnlock() {
        unlockApp()
    }
    
    func forceLock() {
       lockAppIfBiometricEnabled()
    }
    
    //  Utility Methods
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

extension Notification.Name {
    static let biometricLockoutOccurred = Notification.Name("biometricLockoutOccurred")
    static let biometricPrivacyPermissionDenied = Notification.Name("biometricPrivacyPermissionDenied")
    static let forceLogoutRequested = Notification.Name("forceLogoutRequested")
}
