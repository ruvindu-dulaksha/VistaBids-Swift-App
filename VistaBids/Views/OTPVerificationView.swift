//
//  OTPVerificationView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-12.
//

import SwiftUI
import FirebaseAuth

struct OTPVerificationView: View {
    let property: AuctionProperty
    let cardDetails: CardFormData
    @Binding var showOTPView: Bool
    @Binding var showPaymentView: Bool
    
    @StateObject private var otpService = OTPService()
    @State private var otpCode = ""
    @State private var otpId: String?
    @State private var timeRemaining = 300 // 5 minutes in seconds
    @State private var showPaymentSuccess = false
    @State private var timer: Timer?
    @State private var lastGeneratedOTP: String? 
    @Environment(\.colorScheme) var colorScheme
    
    // Get current user's email from Firebase Auth
    private var userEmail: String {
        let email = Auth.auth().currentUser?.email ?? "user@example.com"
        print("🔍 OTP USER EMAIL DEBUG: \(email)")
        print("🔍 Current User: \(Auth.auth().currentUser?.uid ?? "no user")")
        print("🔍 Is Logged In: \(Auth.auth().currentUser != nil)")
        return email
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Email Verification")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("We've sent a verification code to")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(userEmail)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                // OTP Input
                VStack(spacing: 20) {
                    Text("Enter 6-digit code")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    OTPInputField(otpCode: $otpCode)
                    
                    // Timer
                    if timeRemaining > 0 {
                        Text("Code expires in \(formatTime(timeRemaining))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Code expired")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    // Show OTP for testing 
                    if let otp = lastGeneratedOTP {
                        VStack(spacing: 4) {
                            Text("FOR TESTING - Your OTP is:")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(otp)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Verify Button
                Button(action: verifyOTP) {
                    HStack {
                        if otpService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(otpService.isLoading ? "Verifying..." : "Verify & Pay")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isOTPValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isOTPValid || otpService.isLoading)
                .padding(.horizontal)
                
                // Resend OTP
                VStack(spacing: 8) {
                    Button("Didn't receive the code?") {
                        resendOTP()
                    }
                    .foregroundColor(.blue)
                    .disabled(otpService.isLoading)
                    
                    if let errorMessage = otpService.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showOTPView = false
                    }
                }
            }
            .onAppear {
                sendInitialOTP()
                startTimer()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
        .fullScreenCover(isPresented: $showPaymentSuccess) {
            PaymentSuccessView(
                property: property,
                showPaymentSuccess: $showPaymentSuccess,
                showPaymentView: $showPaymentView,
                showOTPView: $showOTPView,
                onDismiss: {
                    // Dismiss all payment views and return to BiddingScreen
                    showPaymentView = false
                    showOTPView = false
                }
            )
        }
    }
    
    private var isOTPValid: Bool {
        otpCode.count == 6 && timeRemaining > 0
    }
    
    private func sendInitialOTP() {
        Task {
            let result = await otpService.generateAndSendOTP(
                email: userEmail,
                amount: property.finalPrice ?? property.currentBid,
                propertyTitle: property.title
            )
            otpId = result.0
            lastGeneratedOTP = result.1
        }
    }
    
    private func verifyOTP() {
        guard let otpId = otpId else { return }
        
        Task {
            let isValid = await otpService.verifyOTP(otpId: otpId, enteredOTP: otpCode)
            if isValid {
                showPaymentSuccess = true
            }
        }
    }
    
    private func resendOTP() {
        timeRemaining = 300
        otpCode = ""
        Task {
            let result = await otpService.resendOTP(
                email: userEmail,
                amount: property.finalPrice ?? property.currentBid,
                propertyTitle: property.title
            )
            otpId = result.0
            lastGeneratedOTP = result.1
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct OTPInputField: View {
    @Binding var otpCode: String
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<6, id: \.self) { index in
                Text(getDigit(at: index))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                otpCode.count > index ? Color.blue : Color.gray.opacity(0.5),
                                lineWidth: 2
                            )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
        }
        .overlay(
            TextField("", text: $otpCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFieldFocused)
                .opacity(0)
                .onAppear {
                    isFieldFocused = true
                }
                .onChange(of: otpCode) { _, newValue in
                    if newValue.count > 6 {
                        otpCode = String(newValue.prefix(6))
                    }
                    // Filter only numbers
                    otpCode = newValue.filter { $0.isNumber }
                }
        )
        .onTapGesture {
            isFieldFocused = true
        }
    }
    
    private func getDigit(at index: Int) -> String {
        if index < otpCode.count {
            return String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: index)])
        }
        return ""
    }
}

#Preview {
    OTPVerificationView(
        property: AuctionProperty.mockProperty(),
        cardDetails: CardFormData(
            cardNumber: "1234 5678 9012 3456",
            expiryDate: "12/28",
            cvv: "123",
            cardHolderName: "John Doe"
        ),
        showOTPView: Binding.constant(true),
        showPaymentView: Binding.constant(true)
    )
}
