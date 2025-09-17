//
//  PaymentViewFixed.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-19.
//

import SwiftUI

struct PaymentView: View {
    let property: AuctionProperty
    @Binding var showPaymentView: Bool
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardHolderName = ""
    @State private var showOTPView = false
    @State private var isProcessing = false
    @State private var selectedPaymentMethod = 0
    @Environment(\.colorScheme) var colorScheme
    
    init(property: AuctionProperty, showPaymentView: Binding<Bool>) {
        print("💳 PaymentViewFixed initialized for property: \(property.title)")
        self.property = property
        self._showPaymentView = showPaymentView
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium background
                LinearGradient(
                    colors: [
                        Color.backgrounds,
                        Color.secondaryBackground,
                        Color.accentBlues.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentBlues.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "creditcard.and.123")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.accentBlues)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Secure Payment")
                                    .font(.title.bold())
                                    .foregroundColor(.textPrimary)
                                
                                Text("Complete your property purchase")
                                    .font(.subheadline)
                                    .foregroundColor(.secondaryTextColor)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.top, 10)
                        
                        // Property summary with better image handling
                        VStack(spacing: 0) {
                            // Image section
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.lightGray.opacity(0.3))
                                    .frame(height: 200)
                                
                                if let firstImage = property.images.first, !firstImage.isEmpty {
                                    AsyncImage(url: URL(string: firstImage)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 200)
                                                .clipped()
                                        case .failure(_):
                                            VStack(spacing: 8) {
                                                Image(systemName: "house.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.accentBlues)
                                                Text("Property Image")
                                                    .font(.headline)
                                                    .foregroundColor(.textPrimary)
                                                Text("Image failed to load")
                                                    .font(.caption)
                                                    .foregroundColor(.secondaryTextColor)
                                            }
                                        case .empty:
                                            VStack(spacing: 8) {
                                                ProgressView()
                                                    .scaleEffect(1.2)
                                                    .tint(.accentBlues)
                                                Text("Loading image...")
                                                    .font(.caption)
                                                    .foregroundColor(.secondaryTextColor)
                                            }
                                        @unknown default:
                                            VStack(spacing: 8) {
                                                Image(systemName: "house.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.accentBlues)
                                                Text("Property")
                                                    .font(.headline)
                                                    .foregroundColor(.textPrimary)
                                            }
                                        }
                                    }
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "house.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.accentBlues)
                                        Text("Property Purchase")
                                            .font(.headline)
                                            .foregroundColor(.textPrimary)
                                        Text("No image available")
                                            .font(.caption)
                                            .foregroundColor(.secondaryTextColor)
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            // Property details
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Text(property.title)
                                        .font(.title3.bold())
                                        .foregroundColor(.textPrimary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.accentBlues)
                                            .font(.subheadline)
                                        
                                        Text(property.address.fullAddress)
                                            .font(.subheadline)
                                            .foregroundColor(.secondaryTextColor)
                                            .fontWeight(.medium)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                }
                                
                                // Price display
                                VStack(spacing: 8) {
                                    Text("Purchase Amount")
                                        .font(.caption)
                                        .foregroundColor(.secondaryTextColor)
                                        .fontWeight(.medium)
                                        .textCase(.uppercase)
                                    
                                    Text("$\(Int(property.finalPrice ?? property.currentBid))")
                                        .font(.title.bold())
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.green.opacity(0.08))
                                        )
                                }
                            }
                            .padding(24)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.cardBackground)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        
                        // Payment method selector
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "wallet.pass.fill")
                                    .foregroundColor(.accentBlues)
                                    .font(.title3)
                                Text("Payment Method")
                                    .font(.headline.bold())
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                // Credit Card
                                Button(action: { selectedPaymentMethod = 0 }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "creditcard.fill")
                                            .font(.title2)
                                            .foregroundColor(selectedPaymentMethod == 0 ? .white : .accentBlues)
                                        
                                        VStack(spacing: 4) {
                                            Text("Credit Card")
                                                .font(.subheadline.bold())
                                                .foregroundColor(selectedPaymentMethod == 0 ? .white : .textPrimary)
                                            
                                            Text("Visa, Mastercard")
                                                .font(.caption)
                                                .foregroundColor(selectedPaymentMethod == 0 ? .white.opacity(0.8) : .secondaryTextColor)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedPaymentMethod == 0 ? Color.accentBlues : Color.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedPaymentMethod == 0 ? Color.clear : Color.accentBlues.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                                
                                // Apple Pay
                                Button(action: { selectedPaymentMethod = 1 }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "apple.logo")
                                            .font(.title2)
                                            .foregroundColor(selectedPaymentMethod == 1 ? .white : .accentBlues)
                                        
                                        VStack(spacing: 4) {
                                            Text("Apple Pay")
                                                .font(.subheadline.bold())
                                                .foregroundColor(selectedPaymentMethod == 1 ? .white : .textPrimary)
                                            
                                            Text("Quick & Secure")
                                                .font(.caption)
                                                .foregroundColor(selectedPaymentMethod == 1 ? .white.opacity(0.8) : .secondaryTextColor)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedPaymentMethod == 1 ? Color.accentBlues : Color.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedPaymentMethod == 1 ? Color.clear : Color.accentBlues.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        
                        // Payment form for credit card
                        if selectedPaymentMethod == 0 {
                            VStack(spacing: 20) {
                                HStack {
                                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                                        .foregroundColor(.accentBlues)
                                        .font(.title3)
                                    Text("Card Details")
                                        .font(.headline.bold())
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "lock.shield.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text("Secure")
                                            .font(.caption.bold())
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.1))
                                    )
                                }
                                
                                VStack(spacing: 16) {
                                    // Card holder name
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.accentBlues)
                                                .font(.caption)
                                            Text("Cardholder Name")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.textPrimary)
                                        }
                                        
                                        TextField("Enter full name as on card", text: $cardHolderName)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
                                            .background(Color.inputFields)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.accentBlues.opacity(0.2), lineWidth: 1)
                                            )
                                            .autocapitalization(.words)
                                    }
                                    
                                    // Card number
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "creditcard.fill")
                                                .foregroundColor(.accentBlues)
                                                .font(.caption)
                                            Text("Card Number")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.textPrimary)
                                        }
                                        
                                        TextField("1234 5678 9012 3456", text: $cardNumber)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
                                            .background(Color.inputFields)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.accentBlues.opacity(0.2), lineWidth: 1)
                                            )
                                            .keyboardType(.numberPad)
                                            .onChange(of: cardNumber) { _, newValue in
                                                cardNumber = formatCardNumber(newValue)
                                            }
                                    }
                                    
                                    HStack(spacing: 16) {
                                        // Expiry date
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "calendar")
                                                    .foregroundColor(.accentBlues)
                                                    .font(.caption)
                                                Text("Expiry Date")
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.textPrimary)
                                            }
                                            
                                            TextField("MM/YY", text: $expiryDate)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 16)
                                                .background(Color.inputFields)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.accentBlues.opacity(0.2), lineWidth: 1)
                                                )
                                                .keyboardType(.numberPad)
                                                .onChange(of: expiryDate) { _, newValue in
                                                    expiryDate = formatExpiryDate(newValue)
                                                }
                                        }
                                        
                                        // CVV
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "lock.fill")
                                                    .foregroundColor(.accentBlues)
                                                    .font(.caption)
                                                Text("CVV")
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.textPrimary)
                                            }
                                            
                                            SecureField("123", text: $cvv)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 16)
                                                .background(Color.inputFields)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.accentBlues.opacity(0.2), lineWidth: 1)
                                                )
                                                .keyboardType(.numberPad)
                                                .onChange(of: cvv) { _, newValue in
                                                    if newValue.count > 3 {
                                                        cvv = String(newValue.prefix(3))
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cardBackground)
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                        }
                        
                        // Security section
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "shield.checkered")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                Text("Security & Privacy")
                                    .font(.headline.bold())
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                SecurityInfoRow(
                                    icon: "lock.shield.fill",
                                    text: "256-bit SSL encryption protects your payment data",
                                    color: .green
                                )
                                
                                SecurityInfoRow(
                                    icon: "envelope.fill",
                                    text: "OTP verification sent to your registered email",
                                    color: .accentBlues
                                )
                                
                                SecurityInfoRow(
                                    icon: "eye.slash.fill",
                                    text: "Your card details are never stored on our servers",
                                    color: .purple
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        Spacer(minLength: 20)
                        
                        // Payment button
                        Button(action: processPayment) {
                            HStack(spacing: 16) {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.1)
                                } else {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.title3.bold())
                                }
                                
                                VStack(spacing: 2) {
                                    Text(isProcessing ? "Processing Payment..." : "Complete Secure Payment")
                                        .fontWeight(.bold)
                                        .font(.headline)
                                    
                                    if !isProcessing {
                                        Text("$\(Int(property.finalPrice ?? property.currentBid))")
                                            .font(.title2.bold())
                                    }
                                }
                                
                                if !isProcessing {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        isFormValid
                                        ? LinearGradient(
                                            colors: [Color.accentBlues, Color.accentBlues.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [Color.disabledBackground, Color.disabledBackground],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .foregroundColor(isFormValid ? .white : .disabledText)
                            .scaleEffect(isProcessing ? 0.98 : 1.0)
                            .shadow(
                                color: isFormValid ? Color.accentBlues.opacity(0.4) : Color.clear,
                                radius: isFormValid ? 12 : 0,
                                x: 0,
                                y: isFormValid ? 6 : 0
                            )
                            .animation(.easeInOut(duration: 0.2), value: isProcessing)
                        }
                        .disabled(!isFormValid || isProcessing)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showPaymentView = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondaryTextColor)
                                .font(.title3)
                            Text("Cancel")
                                .foregroundColor(.textPrimary)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showOTPView) {
            OTPVerificationView(
                property: property,
                cardDetails: CardFormData(
                    cardNumber: cardNumber,
                    expiryDate: expiryDate,
                    cvv: cvv,
                    cardHolderName: cardHolderName
                ),
                showOTPView: $showOTPView,
                showPaymentView: $showPaymentView
            )
        }
    }
    
    private var isFormValid: Bool {
        if selectedPaymentMethod == 1 { 
            return true
        }
        
        return !cardHolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               cardNumber.replacingOccurrences(of: " ", with: "").count >= 16 &&
               expiryDate.count == 5 &&
               cvv.count == 3
    }
    
    private func processPayment() {
        print("💳 Processing payment for: \(property.title)")
        print("💳 Payment method: \(selectedPaymentMethod == 0 ? "Credit Card" : "Apple Pay")")
        print("💳 Amount: $\(Int(property.finalPrice ?? property.currentBid))")
        
        isProcessing = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isProcessing = false
            showOTPView = true
        }
    }
    
    private func formatCardNumber(_ input: String) -> String {
        let digits = input.replacingOccurrences(of: " ", with: "")
        let limited = String(digits.prefix(16))
        
        var formatted = ""
        for (index, character) in limited.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        return formatted
    }
    
    private func formatExpiryDate(_ input: String) -> String {
        let digits = input.replacingOccurrences(of: "/", with: "")
        let limited = String(digits.prefix(4))
        
        if limited.count >= 2 {
            let month = String(limited.prefix(2))
            let year = String(limited.dropFirst(2))
            return "\(month)/\(year)"
        }
        return limited
    }
}

// Security info row component
struct SecurityInfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct CardFormData {
    let cardNumber: String
    let expiryDate: String
    let cvv: String
    let cardHolderName: String
}

#Preview {
    PaymentView(
        property: AuctionProperty.mockProperty(),
        showPaymentView: .constant(true)
    )
}
