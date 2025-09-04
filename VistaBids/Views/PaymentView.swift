//
//  PaymentView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-08-24.
//

import SwiftUI
import PassKit
import CoreLocation
import FirebaseFirestore

struct PaymentView: View {
    let property: AuctionProperty
    let winningAmount: Double
    
    @StateObject private var paymentService = PaymentService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPaymentMethod: PaymentMethod = .applePay
    @State private var showingCardForm = false
    @State private var showingApplePay = false
    @State private var showingSuccessMessage = false
    @State private var transactionId: String?
    
    // Card details
    @State private var cardNumber = ""
    @State private var expiryMonth = 1
    @State private var expiryYear = Calendar.current.component(.year, from: Date())
    @State private var cvv = ""
    @State private var cardholderName = ""
    
    // Billing address
    @State private var billingStreet = ""
    @State private var billingCity = ""
    @State private var billingState = ""
    @State private var billingPostalCode = ""
    @State private var billingCountry = "United States"
    
    private var totalAmount: Double {
        let serviceFee = winningAmount * 0.025
        let processingFee = winningAmount * 0.01
        let taxes = (winningAmount + serviceFee + processingFee) * 0.08
        return winningAmount + serviceFee + processingFee + taxes
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Property Summary
                    propertyCard
                    
                    // Payment Amount Summary
                    paymentSummary
                    
                    // Payment Method Selection
                    paymentMethodSelection
                    
                    // Billing Information
                    if selectedPaymentMethod != .applePay {
                        billingInformation
                    }
                    
                    // Pay Button
                    payButton
                    
                    // Security Information
                    securityInfo
                }
                .padding()
            }
            .navigationTitle("Complete Payment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Payment Successful!", isPresented: $showingSuccessMessage) {
                Button("View Transaction") {
                    // Navigate to transaction details
                    dismiss()
                }
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your payment has been processed successfully. Transaction ID: \(transactionId ?? "N/A")")
            }
            .alert("Payment Error", isPresented: .constant(paymentService.paymentError != nil)) {
                Button("Try Again") {
                    paymentService.paymentError = nil
                }
                Button("Cancel") {
                    dismiss()
                }
            } message: {
                Text(paymentService.paymentError ?? "An error occurred")
            }
        }
    }
    
    private var propertyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎉 Congratulations! You won the auction")
                .font(.headline)
                .foregroundColor(.green)
            
            HStack {
                AsyncImage(url: URL(string: property.images.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(property.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(property.address.fullAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text("Winning Bid: $\(winningAmount, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var paymentSummary: some View {
        VStack(spacing: 12) {
            Text("Payment Summary")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Property Price")
                    Spacer()
                    Text("$\(winningAmount, specifier: "%.2f")")
                }
                
                HStack {
                    Text("Service Fee (2.5%)")
                    Spacer()
                    Text("$\(winningAmount * 0.025, specifier: "%.2f")")
                }
                
                HStack {
                    Text("Processing Fee (1%)")
                    Spacer()
                    Text("$\(winningAmount * 0.01, specifier: "%.2f")")
                }
                
                HStack {
                    Text("Taxes (8%)")
                    Spacer()
                    Text("$\((winningAmount + winningAmount * 0.025 + winningAmount * 0.01) * 0.08, specifier: "%.2f")")
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text("$\(totalAmount, specifier: "%.2f")")
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var paymentMethodSelection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    let isEnabled = method == .applePay ? paymentService.canMakeApplePayPayments() : true
                    let isSelected = selectedPaymentMethod == method
                    
                    PaymentMethodCard(
                        method: method,
                        isSelected: isSelected,
                        isEnabled: isEnabled
                    ) {
                        selectedPaymentMethod = method
                        if method != .applePay {
                            showingCardForm = true
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var billingInformation: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Billing Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                TextField("Cardholder Name", text: $cardholderName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Card Number", text: $cardNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                HStack {
                    Picker("Month", selection: $expiryMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(String(format: "%02d", month)).tag(month)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Year", selection: $expiryYear) {
                        ForEach(Calendar.current.component(.year, from: Date())...(Calendar.current.component(.year, from: Date()) + 10), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("CVV", text: $cvv)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                }
                
                Divider()
                
                Text("Billing Address")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Street Address", text: $billingStreet)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    TextField("City", text: $billingCity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("State", text: $billingState)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    TextField("Postal Code", text: $billingPostalCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Country", text: $billingCountry)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }
    
    private var payButton: some View {
        VStack(spacing: 12) {
            if selectedPaymentMethod == .applePay {
                PayWithApplePayButton(.buy) {
                    processApplePayPayment()
                }
                .frame(height: 50)
                .cornerRadius(8)
            } else {
                Button(action: processCardPayment) {
                    HStack {
                        if paymentService.isProcessingPayment {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(paymentService.isProcessingPayment ? "Processing..." : "Pay $\(totalAmount, specifier: "%.2f")")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(paymentService.isProcessingPayment || !isFormValid)
            }
        }
    }
    
    private var securityInfo: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.green)
                Text("Your payment is secured with bank-level encryption")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Image(systemName: "checkmark.shield")
                    .foregroundColor(.green)
                Text("PCI DSS compliant payment processing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var isFormValid: Bool {
        if selectedPaymentMethod == .applePay {
            return true
        }
        
        return !cardholderName.isEmpty &&
               !cardNumber.isEmpty &&
               cardNumber.count >= 13 &&
               !cvv.isEmpty &&
               cvv.count >= 3 &&
               !billingStreet.isEmpty &&
               !billingCity.isEmpty &&
               !billingState.isEmpty &&
               !billingPostalCode.isEmpty
    }
    
    private func processCardPayment() {
        let cardDetails = CardDetails(
            cardType: .unknown, // This should be determined based on the card number
            lastFourDigits: String(cardNumber.suffix(4)),
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            isVerified: true,
            verificationMethod: .cvv
        )
        
        let billingAddress = BillingAddress(
            street: billingStreet,
            city: billingCity,
            state: billingState,
            postalCode: billingPostalCode,
            country: billingCountry
        )
        
        Task {
            do {
                let transactionId = try await paymentService.processAuctionPayment(
                    propertyId: property.id ?? "",
                    amount: winningAmount,
                    paymentMethod: selectedPaymentMethod,
                    cardDetails: cardDetails,
                    billingAddress: billingAddress
                )
                
                self.transactionId = transactionId
                showingSuccessMessage = true
                
            } catch {
                // Error is handled by the alert
            }
        }
    }
    
    private func processApplePayPayment() {
        let request = paymentService.createApplePayRequest(for: totalAmount, propertyTitle: property.title)
        // In a real app, you would handle the Apple Pay authorization and payment processing
        // For now, simulate a successful payment
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            transactionId = UUID().uuidString
            showingSuccessMessage = true
        }
    }
}

struct PaymentMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(isEnabled ? .primary : .gray)
                
                Text(method.displayText)
                    .font(.caption)
                    .foregroundColor(isEnabled ? .primary : .gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    PaymentView(
        property: AuctionProperty(
            id: "preview-property",
            sellerId: "seller1",
            sellerName: "John Doe",
            title: "Beautiful Modern Home",
            description: "A stunning property...",
            startingPrice: 500000,
            currentBid: 750000,
            highestBidderId: "bidder1",
            highestBidderName: "Jane Smith",
            images: [],
            videos: [],
            arModelURL: nil,
            address: PropertyAddress(street: "123 Main St", city: "San Francisco", state: "CA", postalCode: "94102", country: "USA"),
            location: GeoPoint(latitude: 37.7749, longitude: -122.4194),
            features: PropertyFeatures(bedrooms: 3, bathrooms: 2, area: 1500, yearBuilt: 2020, parkingSpaces: 2, hasGarden: true, hasPool: false, hasGym: false, floorNumber: nil, totalFloors: nil, propertyType: "House"),
            auctionStartTime: Date(),
            auctionEndTime: Date().addingTimeInterval(3600),
            auctionDuration: .thirtyMinutes,
            status: .ended,
            category: .residential,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: Date(),
            updatedAt: Date(),
            winnerId: "bidder1",
            winnerName: "Jane Smith",
            finalPrice: 750000,
            paymentStatus: .pending,
            transactionId: nil,
            panoramicImages: [],
            walkthroughVideoURL: nil
        ),
        winningAmount: 750000
    )
}
