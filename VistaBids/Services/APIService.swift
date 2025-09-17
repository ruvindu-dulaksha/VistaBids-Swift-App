//
//  APIService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-22.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

class APIService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    
    // Computed property for compatibility with mock AuthService
    var isAuthenticated: Bool {
        return isLoggedIn
    }
    
    init() {
        self.currentUser = Auth.auth().currentUser
        self.isLoggedIn = currentUser != nil
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isLoggedIn = user != nil
            }
        }
    }
    
    // Email/Password Authentication
    func signIn(email: String, password: String) async throws {
        print("🔐 Attempting email login for: \(email)")
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.currentUser = result.user
            self.isLoggedIn = true
            print("✅ Email login successful for: \(result.user.email ?? "unknown")")
            print("👤 User ID: \(result.user.uid)")
        }
    }
    
    func signUp(email: String, password: String, fullName: String? = nil) async throws {
        print("📝 Attempting email signup for: \(email)")
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Update the user's display name if provided
        if let fullName = fullName, !fullName.isEmpty {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()
            print("✅ User profile updated with display name: \(fullName)")
        }
        
        DispatchQueue.main.async {
            self.currentUser = result.user
            self.isLoggedIn = true
            print("✅ Email signup successful for: \(result.user.email ?? "unknown")")
            print("👤 User ID: \(result.user.uid)")
        }
    }
    
    // Google Sign In
    @MainActor
    func signInWithGoogle() async throws {
        print("🔍 Starting Google Sign-In process...")
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ Google Sign-In failed: Missing client ID")
            throw AuthError.missingClientID
        }
        
        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Get the presenting view controller for iOS 18.5
        guard let presentingViewController = await getTopViewController() else {
            print("❌ Google Sign-In failed: No presenting view controller")
            throw AuthError.noViewController
        }
        
        print("🚀 Presenting Google Sign-In UI...")
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        
        print("📧 Google Sign-In UI completed, processing tokens...")
        guard let idToken = result.user.idToken?.tokenString else {
            print("❌ Google Sign-In failed: No ID token")
            throw AuthError.tokenError
        }
        
        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        print("🔗 Authenticating with Firebase using Google credentials...")
        let authResult = try await Auth.auth().signIn(with: credential)
        
        DispatchQueue.main.async {
            self.currentUser = authResult.user
            self.isLoggedIn = true
            print("✅ Google Sign-In successful for: \(authResult.user.email ?? "unknown")")
            print("👤 User ID: \(authResult.user.uid)")
            print("📱 Display Name: \(authResult.user.displayName ?? "No display name")")
        }
    }
    
    //  Helper method to get top view controller for iOS 18.5
    @MainActor
    private func getTopViewController() async -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        return window.rootViewController?.topMostViewController()
    }
    
    // Password Reset
    func resetPassword(email: String) async throws {
        print("📧 Sending password reset email to: \(email)")
        try await Auth.auth().sendPasswordReset(withEmail: email)
        print("✅ Password reset email sent successfully")
    }
    
    //  Sign Out
    func signOut() throws {
        print("👋 Signing out user...")
        try Auth.auth().signOut()
        
        // Also clear biometric credentials for security
        let credentialsService = BiometricCredentialsService()
        credentialsService.clearStoredCredentials()
        
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isLoggedIn = false
            print("✅ User signed out successfully")
        }
    }
    
    // Error Mapping
    static func mapError(_ error: Error) -> String {
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .invalidEmail:
                return "Invalid email address"
            case .emailAlreadyInUse:
                return "This email is already registered"
            case .weakPassword:
                return "Password is too weak. Please use at least 6 characters"
            case .userNotFound:
                return "No account found with this email"
            case .wrongPassword:
                return "Incorrect password"
            case .networkError:
                return "Network error. Please check your connection"
            case .tooManyRequests:
                return "Too many attempts. Please try again later"
            case .userDisabled:
                return "This account has been disabled"
            default:
                return "Authentication failed. Please try again"
            }
        }
        
        if let customError = error as? AuthError {
            return customError.errorDescription ?? "Unknown error occurred"
        }
        
        return error.localizedDescription
    }
}

//  UIViewController Extension for iOS 18.5
extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        
        return self
    }
}

//  Auth Errors
enum AuthError: LocalizedError {
    case missingClientID
    case noViewController
    case tokenError
    case invalidEmail
    case weakPassword
    case emailInUse
    case userNotFound
    case wrongPassword
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Missing Google Client ID"
        case .noViewController:
            return "No view controller available"
        case .tokenError:
            return "Failed to get authentication token"
        case .invalidEmail:
            return "Invalid email address"
        case .weakPassword:
            return "Password is too weak. Please use at least 6 characters"
        case .emailInUse:
            return "This email is already registered"
        case .userNotFound:
            return "No account found with this email"
        case .wrongPassword:
            return "Incorrect password"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknown(let message):
            return message
        }
    }
}

//  Input Validation
class ValidationService {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^[\\+]?[1-9]?[0-9]{7,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
    static func validateLoginInput(email: String, password: String) -> String? {
        if email.isEmpty {
            return "Email is required"
        }
        
        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }
        
        if password.isEmpty {
            return "Password is required"
        }
        
        if !isValidPassword(password) {
            return "Password must be at least 6 characters"
        }
        
        return nil
    }
    
    static func validateSignUpInput(email: String, password: String, fullName: String, phoneNumber: String) -> String? {
        if fullName.isEmpty {
            return "Full name is required"
        }
        
        if fullName.count < 2 {
            return "Please enter your full name"
        }
        
        if email.isEmpty {
            return "Email is required"
        }
        
        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }
        
        if password.isEmpty {
            return "Password is required"
        }
        
        if !isValidPassword(password) {
            return "Password must be at least 6 characters"
        }
        
        if !phoneNumber.isEmpty && !isValidPhoneNumber(phoneNumber) {
            return "Please enter a valid phone number"
        }
        
        return nil
    }
}
