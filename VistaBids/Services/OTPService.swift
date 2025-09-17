//
//  OTPService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-12.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class OTPService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var otpSent = false
    
    private let db = Firestore.firestore()
    
    func sendOTP(email: String, amount: Double, propertyTitle: String) async -> (String?, String?) {
        isLoading = true
        errorMessage = nil
        
        print(" OTP SERVICE: Sending OTP to email: \(email)")
        print(" Amount: \(amount)")
        print("Property: \(propertyTitle)")
        
        // random 6-digit OTP
        let otp = String(format: "%06d", Int.random(in: 100000...999999))
        print("  OTP: \(otp)")
        
        do {
            // Store OTP in Firestore with expiration
            let otpData: [String: Any] = [
                "otp": otp,
                "email": email,
                "amount": amount,
                "propertyTitle": propertyTitle,
                "createdAt": Timestamp(),
                "expiresAt": Timestamp(date: Date().addingTimeInterval(300)) // 5 minutes
            ]
            
            let docRef = try await db.collection("payment_otps").addDocument(data: otpData)
            
            // Send email via Firebase Cloud Function or direct email service
            await sendOTPEmail(email: email, otp: otp, amount: amount, propertyTitle: propertyTitle)
            
            otpSent = true
            isLoading = false
            return (docRef.documentID, otp) // Return both document ID and OTP for testing
            
        } catch {
            errorMessage = "Failed to load OTP: \(error.localizedDescription)"
            isLoading = false
            return (nil, nil)
        }
    }
    
    func verifyOTP(otpId: String, enteredOTP: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let document = try await db.collection("payment_otps").document(otpId).getDocument()
            
            guard let data = document.data(),
                  let storedOTP = data["otp"] as? String,
                  let expiresAt = data["expiresAt"] as? Timestamp else {
                errorMessage = "Invalid OTP"
                isLoading = false
                return false
            }
            
            // Check if OTP has expired
            if expiresAt.dateValue() < Date() {
                errorMessage = "OTP has expired"
                isLoading = false
                return false
            }
            
            // Verify OTP
            if storedOTP == enteredOTP {
                // Delete the OTP document after successful verification
                try await db.collection("payment_otps").document(otpId).delete()
                isLoading = false
                return true
            } else {
                errorMessage = "Invalid OTP"
                isLoading = false
                return false
            }
            
        } catch {
            errorMessage = "Failed to verify OTP: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    private func sendOTPEmail(email: String, otp: String, amount: Double, propertyTitle: String) async {
        print("=== EMAIL SERVICE DEBUG ===")
        print("TO: \(email)")
        print("OTP: \(otp)")
        print("AMOUNT: $\(Int(amount))")
        print("PROPERTY: \(propertyTitle)")
        print("=== EMAIL WOULD BE SENT HERE ===")
        
        
        // Store email data in Firestore for verification
        let emailData: [String: Any] = [
            "to": email,
            "subject": "VistaBids Payment Verification - OTP",
            "otp": otp,
            "amount": amount,
            "propertyTitle": propertyTitle,
            "timestamp": Timestamp(),
            "status": "mock_email_logged"
        ]
        
        do {
            try await db.collection("email_logs").addDocument(data: emailData)
           // print("Email mock logged successfully")
        } catch {
           // print("Failed to log email mock: \(error.localizedDescription)")
        }
    }
    
    func resendOTP(email: String, amount: Double, propertyTitle: String) async -> (String?, String?) {
        return await sendOTP(email: email, amount: amount, propertyTitle: propertyTitle)
    }
}
