//
//  ForgetPasswordScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-23.
//

import SwiftUI
import FirebaseAuth
import CoreLocation

struct ForgetPasswordScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = FirebaseAuthService()
    @StateObject private var locationManager = LocationManager()
    @State private var email: String = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var validationError = ""
    @State private var showLocationInfo = false

    var body: some View {
        VStack {
            // Top Illustration
            Image("loginlogo") // Replace with "forgetpassword_illustration" if you have it
                .resizable()
                .scaledToFit()
                .frame(height: 200)

            // Title
            Text("Forget Password")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
                .padding(.top, 8)

            Text("Enter your email address and we'll send you a link to reset your password.")
                .font(.system(size: 14))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 8)

            // Location Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Your Location")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showLocationInfo.toggle()
                        }
                    }) {
                        Image(systemName: showLocationInfo ? "chevron.up" : "chevron.down")
                            .foregroundColor(.accentBlues)
                    }
                }
                .onTapGesture {
                    withAnimation {
                        showLocationInfo.toggle()
                    }
                }
                
                if showLocationInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button(action: {
                                locationManager.requestPermission()
                            }) {
                                HStack {
                                    Image(systemName: "location")
                                        .foregroundColor(.white)
                                    Text("Get Location")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accentBlues)
                                .cornerRadius(6)
                            }
                            
                            if locationManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.leading, 8)
                            }
                            
                            Spacer()
                        }
                        
                        // Location Status
                        switch locationManager.authorizationStatus {
                        case .notDetermined:
                            Text("Location permission not requested")
                                .font(.caption)
                                .foregroundColor(.gray)
                        case .denied, .restricted:
                            Text("Location access denied. Please enable in Settings.")
                                .font(.caption)
                                .foregroundColor(.red)
                        case .authorizedWhenInUse, .authorizedAlways:
                            if let location = locationManager.location {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("📍 Current Location:")
                                        .font(.caption)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("Latitude: \(location.coordinate.latitude, specifier: "%.6f")")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text("Longitude: \(location.coordinate.longitude, specifier: "%.6f")")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text("Accuracy: ±\(location.horizontalAccuracy, specifier: "%.0f")m")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(8)
                                .background(Color.inputFields.opacity(0.5))
                                .cornerRadius(6)
                            } else {
                                Text("Tap 'Get Location' to fetch your current location")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        @unknown default:
                            Text("Unknown location status")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // Error Message
                        if let errorMessage = locationManager.errorMessage {
                            Text("Error: \(errorMessage)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)

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
            .padding(.top, 16)

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
                    Text(isLoading ? "Sending..." : "Send Reset Link")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading ? Color.gray : Color.accentBlues)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .disabled(isLoading)

            Spacer()
        }
        .background(Color.backgrounds.ignoresSafeArea())
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if alertTitle == "Success" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Password Reset Method
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
                    alertTitle = "Success"
                    alertMessage = "Password reset link sent to \(email). Please check your email and follow the instructions to reset your password."
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
