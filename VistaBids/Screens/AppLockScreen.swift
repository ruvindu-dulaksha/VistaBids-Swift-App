//
//  AppLockScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-11.
//

import SwiftUI

struct AppLockScreen: View {
    @EnvironmentObject private var appLockService: AppLockService
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            // Background - adapts to dark/light mode
            Color.backgrounds
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo/Icon
                VStack(spacing: 16) {
                    Image("loginlogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .opacity(0.8)
                    
                    Text("VistaBids")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
                
                // Biometric Authentication Section
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("App Locked")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        Text("Use \(appLockService.biometricDisplayName) to unlock")
                            .font(.subheadline)
                            .foregroundColor(.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Biometric Icon Button
                    Button(action: {
                        if appLockService.shouldShowBiometricPrompt {
                            appLockService.authenticateWithBiometrics()
                        } else {
                            appLockService.shouldShowBiometricPrompt = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                appLockService.authenticateWithBiometrics()
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.inputFields.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.divider, lineWidth: 1)
                                )
                            
                            Image(systemName: appLockService.biometricIcon)
                                .font(.system(size: 32))
                                .foregroundColor(.accentBlues)
                                .scaleEffect(animateIcon ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateIcon)
                        }
                    }
                    .disabled(appLockService.isAuthenticating)
                    
                    // Loading indicator when authenticating
                    if appLockService.isAuthenticating {
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .accentBlues))
                                .scaleEffect(1.2)
                            
                            Text("Authenticating...")
                                .font(.caption)
                                .foregroundColor(.secondaryTextColor)
                        }
                    } else if !appLockService.shouldShowBiometricPrompt {
                        Button(action: {
                            appLockService.shouldShowBiometricPrompt = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                appLockService.authenticateWithBiometrics()
                            }
                        }) {
                            Text("Try Again")
                                .font(.subheadline)
                                .foregroundColor(.accentBlues)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.accentBlues, lineWidth: 1)
                                )
                        }
                    }
                }
                
                Spacer()
                
                // Alternative options
                VStack(spacing: 16) {
                    Button(action: {
                        // Force logout and return to login screen
                        forceLogout()
                    }) {
                        Text("Sign Out")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    
                    Text("Cancel authentication to sign out")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            animateIcon = true
            if appLockService.shouldShowBiometricPrompt {
                // Automatically trigger authentication when screen appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    appLockService.authenticateWithBiometrics()
                }
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
            Button("Try Again") {
                appLockService.authenticateWithBiometrics()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func forceLogout() {
        // Clear biometric credentials and force logout
        let credentialsService = BiometricCredentialsService()
        credentialsService.clearStoredCredentials()
        
        // Post notification to trigger logout
        NotificationCenter.default.post(name: .forceLogoutRequested, object: nil)
        
        // Unlock the app so it can show login screen
        appLockService.forceUnlock()
    }
}

#Preview {
    AppLockScreen()
        .environmentObject(AppLockService())
}
