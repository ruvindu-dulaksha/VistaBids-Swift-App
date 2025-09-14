//
//  ContentView.swift
//  VistaBids
//
//  Created by Assistant on 2025-08-07.
//

import SwiftUI
import Combine
import Firebase
// Import ThemeManager for the updated MainTabView
import Foundation

struct ContentView: View {
    @StateObject private var authService = APIService()
    @StateObject private var appLockService = AppLockService()
    @StateObject private var credentialsService = BiometricCredentialsService()
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                SplashScreen()
                    .onAppear {
                        // Show splash for 3 seconds, then check auth state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else if shouldShowAppLock {
                AppLockScreen()
                    .environmentObject(appLockService)
                    .environmentObject(authService)
                    .transition(.opacity)
            } else {
                if authService.isLoggedIn {
                    MainTabView()
                        .environmentObject(authService)
                        .environmentObject(themeManager)
                        .environmentObject(notificationManager)
                } else {
                    LoginScreen()
                }
            }
        }
        .environmentObject(authService)
        .environmentObject(appLockService)
        .environmentObject(credentialsService)
        .environmentObject(themeManager)
        .environmentObject(notificationManager)
        .overlay(
            // Global notification overlay
            ZStack {
                if notificationManager.showBidWinnerNotification,
                   let property = notificationManager.winningProperty {
                    BidWinnerNotificationView(
                        property: property,
                        showNotification: $notificationManager.showBidWinnerNotification
                    )
                }
            }
        )
        .onReceive(authService.$isLoggedIn) { isLoggedIn in
            // When auth state changes, re-evaluate lock state
            if isLoggedIn {
                print("🔑 User logged in - checking if app should be locked")
                appLockService.checkInitialLockState()
            } else {
                print("🚪 User logged out - unlocking app")
                appLockService.forceUnlock()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .forceLogoutRequested)) { _ in
            handleForceLogout()
        }
        .onReceive(NotificationCenter.default.publisher(for: .biometricPrivacyPermissionDenied)) { _ in
            handlePrivacyPermissionDenied()
        }
    }
    
    // Computed property to determine if app lock should be shown
    private var shouldShowAppLock: Bool {
        // Show app lock if:
        // 1. User is logged in (has Firebase auth session)
        // 2. Face ID is enabled for the app
        // 3. App is locked (either from background or startup)
        let shouldLock = authService.isLoggedIn && 
                        credentialsService.isBiometricLoginEnabled && 
                        appLockService.isAppLocked
        
        if shouldLock {
            print("🔐 Should show app lock: user logged in=\(authService.isLoggedIn), Face ID enabled=\(credentialsService.isBiometricLoginEnabled), app locked=\(appLockService.isAppLocked)")
        }
        
        return shouldLock
    }
    
    private func handleForceLogout() {
        print("🚪 Force logout requested")
        do {
            try authService.signOut()
            appLockService.forceUnlock()
        } catch {
            print("❌ Error during force logout: \(error.localizedDescription)")
        }
    }
    
    private func handlePrivacyPermissionDenied() {
        print("🚫 Face ID privacy permission denied - app lock disabled")
        // Just disable the app lock, don't force logout
        appLockService.disableFaceIDAppLock()
    }
}

#Preview {
    ContentView()
}
