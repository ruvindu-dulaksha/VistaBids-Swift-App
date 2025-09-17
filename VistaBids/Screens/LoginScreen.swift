//
//  LoginScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-22.
//

import SwiftUI
import FirebaseAuth

struct LoginScreen: View {
    @EnvironmentObject private var authService: APIService
    @StateObject private var biometricService = BiometricAuthService()
    @StateObject private var credentialsService = BiometricCredentialsService()
    @StateObject private var appLockService = AppLockService()
    @State private var email = ""
    @State private var password = ""
    @State private var isFaceIDAnimating = false
    @State private var navigateToSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var validationError = ""
    @State private var showBiometricOption = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                Image("loginlogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)

                Text("Log In")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.inputFields)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .onChange(of: email) { _ in
                            clearValidationError()
                        }

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.inputFields)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .onChange(of: password) { _ in
                            clearValidationError()
                        }
                    
                    if !validationError.isEmpty {
                        Text(validationError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 8)

                HStack {
                    Spacer()
                    NavigationLink(destination: ForgetPasswordScreen()) {
                        Text("Forget Password?")
                            .font(.footnote)
                            .foregroundColor(.linkTexts)
                    }
                    .padding(.trailing, 32)
                }
                .padding(.top, 8)

                Button(action: {
                    handleLogin()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Signing In..." : "Log In")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.disabledBackground : Color.buttonBackground)
                    .foregroundColor(.buttonText)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .disabled(isLoading)

                HStack {
                    Rectangle()
                        .fill(Color.inputFields)
                        .frame(height: 1)
                    Text("or")
                        .font(.footnote)
                        .foregroundColor(.textPrimary)
                    Rectangle()
                        .fill(Color.inputFields)
                        .frame(height: 1)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Button(action: {
                    handleGoogleSignIn()
                }) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .textPrimary))
                                .scaleEffect(0.8)
                        } else {
                            Image("google_icon")
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        Text(isLoading ? "Signing In..." : "Continue with Google")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.disabledBackground.opacity(0.7) : Color.inputFields)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .disabled(isLoading)

                Spacer()

                HStack {
                    Text("Don’t have an account?")
                        .foregroundColor(.textPrimary)
                    NavigationLink("Sign Up", destination: SignUpScreen())
                        .foregroundColor(.linkTexts)
                }
                .font(.footnote)
                .padding(.bottom, 20)
            }
            .background(Color.backgrounds.ignoresSafeArea())
            .alert("Authentication Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: authService.isLoggedIn) { isLoggedIn in
                if isLoggedIn {
                    print("🎉 LOGIN STATUS CHANGED: User is now logged in!")
                    if let user = authService.currentUser {
                        print("📧 Logged in user email: \(user.email ?? "No email")")
                        print("👤 User display name: \(user.displayName ?? "No display name")")
                        print("🆔 User ID: \(user.uid)")
                        print("✅ Email verified: \(user.isEmailVerified)")
                        
                        // Show biometric setup option if not already enabled
                        if biometricService.isBiometricAvailable && !credentialsService.isBiometricLoginEnabled {
                            showBiometricOption = true
                        }
                    }
                    // Navigate to main app or dashboard
                    
                } else {
                    print("👋 LOGIN STATUS CHANGED: User is logged out")
                }
            }
            .alert("Enable Biometric Login", isPresented: $showBiometricOption) {
                Button("Enable") {
                    enableBiometricLogin()
                }
                Button("Skip", role: .cancel) { }
            } message: {
                Text("Would you like to enable \(biometricService.biometricDisplayName) for quick sign-in?")
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    //Authentication Methods
    private func handleLogin() {
        print("🔐 Starting email/password login process...")
        // Clear previous errors
        clearValidationError()
        
        // Validate input
        if let error = ValidationService.validateLoginInput(email: email, password: password) {
            print("❌ Validation failed: \(error)")
            validationError = error
            return
        }
        
        print("✅ Input validation passed")
        isLoading = true
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    print("🎉 EMAIL LOGIN SUCCESSFUL!")
                    
                    // Show biometric setup option if not already enabled
                    if biometricService.isBiometricAvailable && !credentialsService.isBiometricLoginEnabled {
                        showBiometricOption = true
                    }
                    // Success - user will be automatically navigated via the onChange handler
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ EMAIL LOGIN FAILED: \(error.localizedDescription)")
                    handleAuthError(error)
                }
            }
        }
    }
    
    private func handleBiometricAuthentication() {
        print("🔐 Starting biometric authentication...")
        
        guard biometricService.isBiometricAvailable else {
            alertMessage = "Biometric authentication is not available on this device"
            showingAlert = true
            return
        }
        
        guard credentialsService.isBiometricLoginEnabled else {
            alertMessage = "Please sign in with email/password first to enable biometric login"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // First authenticate with biometrics
                let biometricSuccess = try await biometricService.authenticateWithBiometrics()
                
                if biometricSuccess {
                    // Get stored credentials
                    guard let credentials = credentialsService.getBiometricCredentials() else {
                        await MainActor.run {
                            isLoading = false
                            alertMessage = "No stored credentials found. Please sign in with email/password"
                            showingAlert = true
                        }
                        return
                    }
                    
                    // Sign in with stored credentials
                    try await authService.signIn(email: credentials.email, password: credentials.password)
                    
                    await MainActor.run {
                        isLoading = false
                        print("🎉 BIOMETRIC LOGIN SUCCESSFUL!")
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let biometricError = error as? BiometricError {
                        switch biometricError {
                        case .userCancelled:
                            print("👤 User cancelled biometric authentication")
                            // Don't show error for user cancellation
                            return
                        default:
                            alertMessage = biometricError.errorDescription ?? "Biometric authentication failed"
                        }
                    } else {
                        alertMessage = "Biometric authentication failed: \(error.localizedDescription)"
                    }
                    print("❌ BIOMETRIC LOGIN FAILED: \(alertMessage)")
                    showingAlert = true
                }
            }
        }
    }
    
    private func enableBiometricLogin() {
        guard !email.isEmpty && !password.isEmpty else {
            alertMessage = "Please enter your credentials first"
            showingAlert = true
            return
        }
        
        Task {
            do {
                // Test biometric authentication first
                let success = try await biometricService.authenticateWithBiometrics()
                
                if success {
                    // Store credentials for future biometric login
                    await MainActor.run {
                        let stored = credentialsService.storeBiometricCredentials(email: email, password: password)
                        if stored {
                            // Also enable app lock functionality
                            appLockService.enableFaceIDAppLock()
                            
                            alertMessage = """
                            \(biometricService.biometricDisplayName) enabled successfully!
                            
                            Features enabled:
                            • Quick login with \(biometricService.biometricDisplayName)
                            • App lock when closed/backgrounded
                            """
                        } else {
                            alertMessage = "Failed to enable biometric login"
                        }
                        showingAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    if let biometricError = error as? BiometricError, case .userCancelled = biometricError {
                        
                        return
                    }
                    alertMessage = "Failed to enable biometric login: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        print("🔍 Starting Google Sign-In process...")
        isLoading = true
        
        Task {
            do {
                try await authService.signInWithGoogle()
                await MainActor.run {
                    isLoading = false
                    print("🎉 GOOGLE LOGIN SUCCESSFUL!")
                    // Success - user will be automatically navigated via the onChange handler
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ GOOGLE LOGIN FAILED: \(error.localizedDescription)")
                    handleAuthError(error)
                }
            }
        }
    }
    
    private func handleAuthError(_ error: Error) {
        print("🚨 Authentication error occurred: \(error)")
        if let authError = error as? AuthError {
            alertMessage = authError.errorDescription ?? "An unknown error occurred"
            print("🔍 AuthError details: \(authError)")
        } else if let nsError = error as NSError? {
            print("🔍 NSError code: \(nsError.code), domain: \(nsError.domain)")
            switch nsError.code {
            case AuthErrorCode.invalidEmail.rawValue:
                alertMessage = "Invalid email address"
            case AuthErrorCode.wrongPassword.rawValue:
                alertMessage = "Incorrect password"
            case AuthErrorCode.userNotFound.rawValue:
                alertMessage = "No account found with this email"
            case AuthErrorCode.networkError.rawValue:
                alertMessage = "Network error. Please check your connection"
            default:
                alertMessage = "Login failed: \(error.localizedDescription)"
            }
        } else {
            alertMessage = "Login failed: \(error.localizedDescription)"
        }
        print("💬 Alert message: \(alertMessage)")
        showingAlert = true
    }
    
    private func clearValidationError() {
        validationError = ""
    }
}


#Preview {
    LoginScreen()
}
