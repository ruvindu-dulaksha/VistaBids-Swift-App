//
//  SignUpScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-23.
//

import SwiftUI

struct SignUpScreen: View {
    @EnvironmentObject private var authService: APIService
    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                Image("loginlogo") 
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)

                Text("Sign Up")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.top, 8)

                Group {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)

                    TextField("Phone Number (Optional)", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                .padding()
                .background(Color.inputFields)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)
                .disabled(isLoading)

                Button(action: {
                    Task {
                        await handleSignUp()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Signing Up..." : "Sign Up")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.accentBlues.opacity(0.7) : Color.accentBlues)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .disabled(isLoading)

                HStack {
                    Rectangle()
                        .fill(Color.inputFields)
                        .frame(height: 1)
                    Text("Or Continue with")
                        .font(.footnote)
                        .foregroundColor(.textPrimary)
                    Rectangle()
                        .fill(Color.inputFields)
                        .frame(height: 1)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Button(action: {
                    Task {
                        await handleGoogleSignUp()
                    }
                }) {
                    HStack(spacing: 20) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .textPrimary))
                                .scaleEffect(0.8)
                        } else {
                            Image("google_icon")
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        Text(isLoading ? "Signing Up..." : "Continue with Google")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.inputFields)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .disabled(isLoading)

                Spacer()

                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.textPrimary)
                    NavigationLink("Log In", destination: LoginScreen())
                        .foregroundColor(.linkTexts)
                }
                .font(.footnote)
                .padding(.bottom, 20)
            }
            .background(Color.backgrounds.ignoresSafeArea())
            .alert("Sign Up Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // Authentication Methods
    @MainActor
    private func handleSignUp() async {
        // Validate input
        guard let validationError = ValidationService.validateSignUpInput(
            email: email,
            password: password,
            fullName: fullName,
            phoneNumber: phoneNumber
        ) else {
            // Input is valid, proceed with sign up
            await performEmailSignUp()
            return
        }
        
        // Show validation error
        errorMessage = validationError
        showError = true
    }
    
    @MainActor
    private func performEmailSignUp() async {
        isLoading = true
        
        do {
            try await authService.signUp(email: email, password: password, fullName: fullName)
            // Successfully signed up - navigation will be handled by the auth state change
            print("Sign up successful, user logged in automatically")
        } catch {
            errorMessage = APIService.mapError(error)
            showError = true
            print("Sign up failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    @MainActor
    private func handleGoogleSignUp() async {
        isLoading = true
        
        do {
            try await authService.signInWithGoogle()
            // Successfully signed up with Google - navigation will be handled by the auth state change
            print("Google sign up successful")
        } catch {
            errorMessage = APIService.mapError(error)
            showError = true
            print("Google sign up failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}


#Preview {
    SignUpScreen()
}
