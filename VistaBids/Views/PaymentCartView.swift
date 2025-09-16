import SwiftUI
import FirebaseFirestore

struct PaymentCartView: View {
    let properties: [AuctionProperty]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var biddingService: BiddingService
    @State private var showingPaymentView = false
    @State private var selectedProperty: AuctionProperty?
    @State private var selectedPaymentMethod = PaymentMethod.creditCard
    @State private var showPaymentSuccess = false
    @State private var processingPayment = false
    
    var totalAmount: Double {
        properties.reduce(0) { total, property in
            total + (property.finalPrice ?? property.currentBid)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Payment Cart")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("\(properties.count) properties requiring payment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.medium)
                    }
                    
                    // Total Summary
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Amount")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(totalAmount, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        PaymentMethodSelector(selectedMethod: $selectedPaymentMethod)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                // Property List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(properties, id: \.id) { property in
                            PaymentCartItemView(property: property)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Payment Button
                VStack(spacing: 16) {
                    Divider()
                    
                    Button(action: processPayment) {
                        HStack {
                            if processingPayment {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Processing...")
                            } else {
                                Text("Pay $\(totalAmount, specifier: "%.0f")")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(processingPayment ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(processingPayment)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(.systemGray6))
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showPaymentSuccess) {
            // Show success for the first property
            if let firstProperty = properties.first {
                PaymentSuccessView(
                    property: firstProperty,
                    showPaymentSuccess: $showPaymentSuccess,
                    showPaymentView: .constant(false),
                    showOTPView: .constant(false),
                    onDismiss: {
                        // Dismiss the cart view and navigate back to BiddingScreen
                        dismiss()
                    }
                )
            }
        }
    }
    
    private func processPayment() {
        guard !processingPayment else { return }
        
        processingPayment = true
        
        Task {
            do {
                // Process payment for all properties in the cart
                for property in properties {
                    print("🎯 Processing payment for property: \(property.title)")
                    try await biddingService.completePayment(for: property.id ?? "")
                }
                
                // Show success after all payments are processed
                await MainActor.run {
                    processingPayment = false
                    showPaymentSuccess = true
                    print("✅ All payments processed successfully")
                }
                
            } catch {
                await MainActor.run {
                    processingPayment = false
                    print("❌ Payment processing failed: \(error.localizedDescription)")
                    // You might want to show an error alert here
                }
            }
        }
    }
}

// MARK: - Payment Cart Item View
struct PaymentCartItemView: View {
    let property: AuctionProperty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PropertyCartHeader(property: property)
            
            HStack(alignment: .top, spacing: 12) {
                PropertyCartImage(property: property)
                
                VStack(alignment: .leading, spacing: 8) {
                    PropertyCartDetails(property: property)
                    PropertyCartPricing(property: property)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            PropertyCartFooter(property: property)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Component Views
struct PropertyCartHeader: View {
    let property: AuctionProperty
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                Text("Winner")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
            
            Text("ID: \((property.id ?? "").prefix(8))...")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct PropertyCartImage: View {
    let property: AuctionProperty
    
    var body: some View {
        AsyncImage(url: URL(string: property.images.first ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray4))
                .overlay(
                    Image(systemName: "house.fill")
                        .foregroundColor(.gray)
                )
        }
        .frame(width: 80, height: 80)
        .cornerRadius(8)
    }
}

struct PropertyCartDetails: View {
    let property: AuctionProperty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(property.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(property.address.fullAddress)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            PropertyCartFeaturesView(features: property.features)
        }
    }
}

struct PropertyCartFeaturesView: View {
    let features: PropertyFeatures
    
    var body: some View {
        HStack(spacing: 12) {
            PaymentFeatureItem(icon: "bed.double.fill", value: "\(features.bedrooms)")
            PaymentFeatureItem(icon: "bathtub.fill", value: "\(features.bathrooms)")
            PaymentFeatureItem(icon: "square.fill", value: "\(Int(features.area))sq")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

struct PaymentFeatureItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(value)
        }
    }
}

struct PropertyCartPricing: View {
    let property: AuctionProperty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Final Bid")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("$\(property.finalPrice ?? property.currentBid, specifier: "%.0f")")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
    }
}

struct PropertyCartFooter: View {
    let property: AuctionProperty
    
    var body: some View {
        HStack {
            Text("Payment Status: Pending")
                .font(.caption2)
                .foregroundColor(.orange)
            
            Spacer()
            
            Text("Due: Now")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.red)
        }
        .padding(.top, 8)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.2)),
            alignment: .top
        )
    }
}

// MARK: - Payment Method Selector
struct PaymentMethodSelector: View {
    @Binding var selectedMethod: PaymentMethod
    @State private var showingMethods = false
    
    var body: some View {
        Button(action: { showingMethods = true }) {
            HStack(spacing: 8) {
                Image(systemName: selectedMethod.icon)
                    .foregroundColor(selectedMethod.color)
                Text(selectedMethod.displayName)
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .actionSheet(isPresented: $showingMethods) {
            ActionSheet(
                title: Text("Select Payment Method"),
                buttons: PaymentMethod.allCases.map { method in
                    .default(Text(method.displayName)) {
                        selectedMethod = method
                    }
                } + [.cancel()]
            )
        }
    }
}

#Preview {
    PaymentCartView(properties: [
        AuctionProperty(
            sellerId: "seller1",
            sellerName: "John Doe",
            title: "Modern Downtown Condo",
            description: "Beautiful condo in the heart of the city",
            startingPrice: 500000,
            currentBid: 750000,
            highestBidderId: "bidder1",
            highestBidderName: "Jane Smith",
            images: ["https://example.com/image1.jpg"],
            videos: [],
            arModelURL: nil,
            address: PropertyAddress(
                street: "123 Beach Avenue",
                city: "Miami",
                state: "FL",
                postalCode: "33101",
                country: "USA"
            ),
            location: GeoPoint(latitude: 25.7617, longitude: -80.1918),
            features: PropertyFeatures(
                bedrooms: 2,
                bathrooms: 2,
                area: 1200,
                yearBuilt: 2020,
                parkingSpaces: 1,
                hasGarden: false,
                hasPool: true,
                hasGym: false,
                floorNumber: 5,
                totalFloors: 10,
                propertyType: "Condo"
            ),
            auctionStartTime: Date().addingTimeInterval(-3600),
            auctionEndTime: Date().addingTimeInterval(-600),
            auctionDuration: .oneHour,
            status: .ended,
            category: .residential,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: Date().addingTimeInterval(-7200),
            updatedAt: Date().addingTimeInterval(-600),
            winnerId: "bidder1",
            winnerName: "Jane Smith",
            finalPrice: 750000,
            paymentStatus: .pending,
            transactionId: nil,
            panoramicImages: [],
            walkthroughVideoURL: nil
        )
    ])
}