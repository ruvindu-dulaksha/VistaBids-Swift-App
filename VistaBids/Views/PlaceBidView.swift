//
//  PlaceBidView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-16.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PlaceBidView: View {
    let property: AuctionProperty
    let biddingService: BiddingService
    @Environment(\.dismiss) private var dismiss
    @State private var bidAmount: String = ""
    @State private var isAutoBidEnabled = false
    @State private var maxAutoBidAmount: String = ""
    @State private var isPlacingBid = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    private var minimumBid: Double {
        property.currentBid + 1000 // Minimum increment of $1000
    }
    
    private var bidAmountValue: Double {
        Double(bidAmount) ?? 0
    }
    
    private var maxAutoBidValue: Double {
        Double(maxAutoBidAmount) ?? 0
    }
    
    private var isValidBid: Bool {
        bidAmountValue >= minimumBid
    }
    
    private var isValidMaxAutoBid: Bool {
        !isAutoBidEnabled || maxAutoBidValue >= bidAmountValue
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Property Summary
                    propertyInfo
                    
                    // Current Bid Info
                    currentBidInfo
                    
                    // Bid Amount Input
                    bidAmountSection
                    
                    // Auto Bid Section
                    autoBidSection
                    
                    // Place Bid Button
                    placeBidButton
                    
                    // Terms and Conditions
                    termsSection
                }
                .padding()
            }
            .navigationTitle("Place Bid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Set initial bid amount to minimum bid
                bidAmount = String(format: "%.0f", minimumBid)
            }
        }
    }
    
    private var propertyInfo: some View {
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
            .clipped()
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(property.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                
                Text(property.address.fullAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(property.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.accentBlues)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentBlues.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    private var currentBidInfo: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Current Highest Bid")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("$\(String(format: "%.0f", property.currentBid))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }
            
            if let highestBidder = property.highestBidderName {
                HStack {
                    Text("Leading Bidder")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(highestBidder)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }
            }
            
            Divider()
            
            HStack {
                Text("Minimum Bid")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("$\(String(format: "%.0f", minimumBid))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentBlues)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    private var bidAmountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Bid Amount")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("$")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Enter bid amount", text: $bidAmount)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .keyboardType(.numberPad)
                        .foregroundColor(.textPrimary)
                }
                .padding()
                .background(Color.inputField)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isValidBid ? Color.accentBlues : Color.red, lineWidth: isValidBid ? 1 : 2)
                )
                
                if !isValidBid && !bidAmount.isEmpty {
                    Text("Bid must be at least $\(String(format: "%.0f", minimumBid))")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Quick Bid Buttons
            HStack(spacing: 12) {
                ForEach([1000, 5000, 10000], id: \.self) { increment in
                    Button(action: {
                        let newAmount = minimumBid + Double(increment)
                        bidAmount = String(format: "%.0f", newAmount)
                    }) {
                        Text("+$\(increment)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentBlues)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentBlues.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var autoBidSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Enable Auto-Bidding", isOn: $isAutoBidEnabled)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }
            
            Text("Automatically bid up to your maximum amount when outbid")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isAutoBidEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum Auto-Bid Amount")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    HStack {
                        Text("$")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        TextField("Enter maximum amount", text: $maxAutoBidAmount)
                            .font(.title3)
                            .fontWeight(.medium)
                            .keyboardType(.numberPad)
                            .foregroundColor(.textPrimary)
                    }
                    .padding()
                    .background(Color.inputField)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isValidMaxAutoBid ? Color.accentBlues : Color.red, lineWidth: isValidMaxAutoBid ? 1 : 2)
                    )
                    
                    if !isValidMaxAutoBid && !maxAutoBidAmount.isEmpty {
                        Text("Maximum auto-bid must be greater than or equal to your bid amount")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .transition(.slide)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .animation(.easeInOut, value: isAutoBidEnabled)
    }
    
    private var placeBidButton: some View {
        Button(action: placeBid) {
            HStack {
                if isPlacingBid {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.white)
                }
                
                Text(isPlacingBid ? "Placing Bid..." : "Place Bid")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                (isValidBid && isValidMaxAutoBid && !isPlacingBid) ? 
                Color.accentBlues : Color.gray
            )
            .cornerRadius(12)
        }
        .disabled(!isValidBid || !isValidMaxAutoBid || isPlacingBid)
    }
    
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Important Information")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("All bids are binding and cannot be withdrawn")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("You will be notified if you are outbid")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Auto-bidding will increment by minimum amounts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Winning bid requires immediate payment verification")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    private func placeBid() {
        guard isValidBid && isValidMaxAutoBid else { return }
        
        isPlacingBid = true
        
        Task {
            do {
                let bid = UserBid(
                    id: UUID().uuidString,
                    propertyId: property.id ?? "",
                    propertyTitle: property.title,
                    bidAmount: bidAmountValue,
                    bidTime: Date(),
                    status: .active,
                    isWinning: false
                )
                
                try await biddingService.placeBid(
                    on: property.id ?? "",
                    amount: bidAmountValue,
                    maxAutoBid: isAutoBidEnabled ? maxAutoBidValue : nil
                )
                
                await MainActor.run {
                    isPlacingBid = false
                    alertTitle = "Bid Placed Successfully"
                    alertMessage = "Your bid of $\(String(format: "%.0f", bidAmountValue)) has been placed successfully!"
                    showingAlert = true
                }
                
                // Dismiss after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isPlacingBid = false
                    alertTitle = "Bid Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    PlaceBidView(
        property: AuctionProperty(
            sellerId: "seller1",
            sellerName: "John Doe",
            title: "Modern Villa",
            description: "Beautiful modern villa with stunning views.",
            startingPrice: 500000,
            currentBid: 550000,
            highestBidderId: "bidder1",
            highestBidderName: "Jane Smith",
            images: [],
            videos: [],
            arModelURL: nil,
            address: PropertyAddress(
                street: "123 Main Street",
                city: "Colombo",
                state: "Western Province",
                postalCode: "00100",
                country: "Sri Lanka"
            ),
            location: GeoPoint(latitude: 6.9271, longitude: 79.8612),
            features: PropertyFeatures(
                bedrooms: 4,
                bathrooms: 3,
                area: 2500,
                yearBuilt: 2020,
                parkingSpaces: 2,
                hasGarden: true,
                hasPool: true,
                hasGym: false,
                floorNumber: nil,
                totalFloors: nil,
                propertyType: "Villa"
            ),
            auctionStartTime: Date().addingTimeInterval(-3600),
            auctionEndTime: Date().addingTimeInterval(7200),
            auctionDuration: .oneHour,
            status: .active,
            category: .luxury,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: Date(),
            updatedAt: Date(),
            panoramicImages: [],
            walkthroughVideoURL: nil
        ),
        biddingService: BiddingService()
    )
}
