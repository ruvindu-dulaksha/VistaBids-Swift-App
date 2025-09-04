//
//  PaymentTestView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-09-05.
//

import SwiftUI
import FirebaseFirestore

struct PaymentTestView: View {
    @StateObject private var paymentService = PaymentService()
    @State private var showingPayment = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Test property data
    let testProperty = AuctionProperty(
        id: "test-123",
        sellerId: "seller-123",
        sellerName: "Test Seller",
        title: "Cozy Test House",
        description: "A beautiful test property",
        startingPrice: 100000,
        currentBid: 150000,
        highestBidderId: "bidder-123",
        highestBidderName: "Test Bidder",
        images: ["https://example.com/test.jpg"],
        videos: [],
        arModelURL: nil,
        address: PropertyAddress(
            street: "123 Test Street",
            city: "Test City",
            state: "TS",
            postalCode: "12345",
            country: "Test Country"
        ),
        location: GeoPoint(latitude: 0, longitude: 0),
        features: PropertyFeatures(
            bedrooms: 3,
            bathrooms: 2,
            area: 1500,
            yearBuilt: 2025,
            parkingSpaces: 2,
            hasGarden: true,
            hasPool: false,
            hasGym: false,
            floorNumber: nil,
            totalFloors: 2,
            propertyType: "House"
        ),
        auctionStartTime: Date(),
        auctionEndTime: Date().addingTimeInterval(3600),
        auctionDuration: .oneHour,
        status: .active,
        category: .residential,
        bidHistory: [],
        watchlistUsers: [],
        createdAt: Date(),
        updatedAt: Date(),
        winnerId: nil,
        winnerName: nil,
        finalPrice: nil,
        paymentStatus: .pending,
        transactionId: nil,
        panoramicImages: [],
        walkthroughVideoURL: nil
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Payment Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Property Card
                propertyCard
                
                // Test Actions
                actionButtons
                
                // Status Section
                statusSection
            }
            .padding()
        }
        .sheet(isPresented: $showingPayment) {
            PaymentView(
                property: testProperty,
                winningAmount: testProperty.currentBid
            )
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Payment processed successfully! Check your notifications.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var propertyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Property Details")
                .font(.headline)
            
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "house.fill")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(testProperty.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(testProperty.address.fullAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Current Bid: $\(testProperty.currentBid, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button {
                showingPayment = true
            } label: {
                HStack {
                    Image(systemName: "creditcard.fill")
                    Text("Test Payment Flow")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button {
                simulateDirectPayment()
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Quick Test (Direct Payment)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test Information")
                .font(.headline)
            
            Text("• Tap 'Test Payment Flow' to test the complete payment UI")
                .font(.caption)
            
            Text("• Tap 'Quick Test' to simulate a direct payment")
                .font(.caption)
            
            Text("• Check Firebase Console to see the transaction data")
                .font(.caption)
            
            Text("• A push notification will be sent on successful payment")
                .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func simulateDirectPayment() {
        Task {
            do {
                let billingAddress = BillingAddress(
                    street: "123 Test St",
                    city: "Test City",
                    state: "TS",
                    postalCode: "12345",
                    country: "Test Country"
                )
                
                let cardDetails = CardDetails(
                    cardType: .visa,
                    lastFourDigits: "4242",
                    expiryMonth: 12,
                    expiryYear: 2025,
                    cardholderName: "Test User",
                    isVerified: true,
                    verificationMethod: .cvv
                )
                
                let transactionId = try await paymentService.processAuctionPayment(
                    propertyId: testProperty.id ?? "",
                    amount: testProperty.currentBid,
                    paymentMethod: .creditCard,
                    cardDetails: cardDetails,
                    billingAddress: billingAddress
                )
                
                print("Transaction ID:", transactionId)
                showingSuccess = true
                
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    PaymentTestView()
}
