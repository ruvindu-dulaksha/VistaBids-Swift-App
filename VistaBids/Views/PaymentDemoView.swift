//
//  PaymentDemoView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-05.
//

import SwiftUI
import FirebaseFirestore

struct PaymentDemoView: View {
    @State private var showingPaymentSheet = false
    
    // Demo property data
    let demoProperty = AuctionProperty(
        sellerId: "seller1",
        sellerName: "John Doe",
        title: "Luxury Oceanfront Villa",
        description: "A stunning 4-bedroom oceanfront villa with panoramic views of the Pacific",
        startingPrice: 1500000,
        currentBid: 1750000,
        highestBidderId: "bidder1",
        highestBidderName: "Jane Smith",
        images: [
            "https://example.com/luxury-villa-1.jpg",
            "https://example.com/luxury-villa-2.jpg",
        ],
        videos: [],
        arModelURL: nil,
        address: PropertyAddress(
            street: "123 Ocean Drive",
            city: "Malibu",
            state: "CA",
            postalCode: "90265",
            country: "USA"
        ),
        location: GeoPoint(latitude: 34.0259, longitude: -118.7798),
        features: PropertyFeatures(
            bedrooms: 4,
            bathrooms: 4,
            area: 4500,
            yearBuilt: 2020,
            parkingSpaces: 3,
            hasGarden: true,
            hasPool: true,
            hasGym: true,
            floorNumber: nil,
            totalFloors: 2,
            propertyType: "Villa"
        ),
        auctionStartTime: Date().addingTimeInterval(-3600 * 24),
        auctionEndTime: Date(),
        auctionDuration: .oneHour,
        status: .ended,
        category: .luxury,
        bidHistory: [],
        watchlistUsers: [],
        createdAt: Date().addingTimeInterval(-3600 * 48),
        updatedAt: Date(),
        winnerId: "bidder1",
        winnerName: "Jane Smith",
        finalPrice: 1750000,
        paymentStatus: .pending,
        transactionId: nil,
        panoramicImages: [],
        walkthroughVideoURL: nil
    )
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Payment Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("This is a demo of the VistaBids payment system")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Sample Property:")
                    .font(.headline)
                
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(demoProperty.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(demoProperty.address.fullAddress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Final Price: $\(demoProperty.finalPrice ?? 0, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            
            Button {
                showingPaymentSheet = true
            } label: {
                Text("Open Payment Sheet")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            Text("Demo Note: No actual payment will be processed.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentView(
                property: demoProperty,
                showPaymentView: $showingPaymentSheet
            )
        }
    }
}

#Preview {
    PaymentDemoView()
}
