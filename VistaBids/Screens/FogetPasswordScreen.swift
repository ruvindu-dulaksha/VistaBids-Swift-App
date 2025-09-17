//
//  ForgetPasswordScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-23.
//

import SwiftUI
import FirebaseAuth

struct ForgetPasswordScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = APIService()
    @State private var email: String = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var validationError = ""

    var body: some View {
        VStack {
            
            Image("loginlogo") 
                .resizable()
                .scaledToFit()
                .frame(height: 200)

            // Title
            Text("Forget Password")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
                .padding(.top, 8)

            Text("Enter your email address and we'll send you a secure link to reset your password.")
                .font(.system(size: 14))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                // Email Field
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.inputFields)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .onChange(of: email) { _ in
                        clearValidationError()
                    }
                
                if !validationError.isEmpty {
                    Text(validationError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 24)

            // Submit Button
            Button(action: {
                handlePasswordReset()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "Sending Email..." : "Send Reset Email")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading ? Color.gray : Color.accentBlues)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 24)
            }
            .disabled(isLoading)

            Spacer()
        }
        .background(Color.backgrounds.ignoresSafeArea())
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if alertTitle == "Email Sent" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    //Password Reset Method
    private func handlePasswordReset() {
        // Clear previous errors
        clearValidationError()
        
        // Validate email
        if email.isEmpty {
            validationError = "Email is required"
            return
        }
        
        if !ValidationService.isValidEmail(email) {
            validationError = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await authService.resetPassword(email: email)
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Email Sent"
                    alertMessage = "We've sent a password reset link to \(email). Please check your email and follow the instructions to create a new password. The link will expire in 24 hours."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    if let nsError = error as NSError? {
                        switch nsError.code {
                        case AuthErrorCode.invalidEmail.rawValue:
                            alertMessage = "Invalid email address"
                        case AuthErrorCode.userNotFound.rawValue:
                            alertMessage = "No account found with this email address"
                        case AuthErrorCode.networkError.rawValue:
                            alertMessage = "Network error. Please check your connection"
                        default:
                            alertMessage = "Failed to send reset email: \(error.localizedDescription)"
                        }
                    } else {
                        alertMessage = "Failed to send reset email: \(error.localizedDescription)"
                    }
                    showingAlert = true
                }
            }
        }
    }
    
    private func clearValidationError() {
        validationError = ""
    }
}

#Preview {
    ForgetPasswordScreen()
}
