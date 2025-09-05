import SwiftUI

struct BiddingScreen: View {
    @ObservedObject private var biddingService = BiddingService()
    @State private var selectedFilter = "All"
    @State private var showingAR = false
    @State private var selectedProperty: AuctionProperty?
    @State private var showingPropertyDetail = false
    @State private var showingAddProperty = false
    
    private let filters = ["All", "Live", "Upcoming", "Ended"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with Add Property Button
                HStack {
                    Text("Live Auctions")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    // Debug button to populate sample data
                    if biddingService.auctionProperties.isEmpty {
                        Button(action: {
                            Task {
                                do {
                                    try await biddingService.createEnhancedAuctionData()
                                    // After creating sample data, reload from Firestore
                                    await biddingService.loadAuctionProperties()
                                } catch {
                                    print("Failed to create sample data: \(error)")
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Sample Data")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(15)
                        }
                    }
                    
                    Button(action: { showingAddProperty = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Property")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentBlues)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FilterPillButton(
                                title: filter,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Properties List
                if biddingService.isCreatingData {
                    VStack(spacing: 20) {
                        ProgressView(value: biddingService.dataCreationProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.horizontal, 40)
                        
                        Text("Creating sample auction data...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(biddingService.dataCreationProgress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.accentBlues)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else if biddingService.isLoading {
                    ProgressView("Loading auctions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if biddingService.auctionProperties.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "house.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Active Auctions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Tap 'Add Sample Data' to populate with example auctions, or 'Add Property' to create your first auction.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredProperties(), id: \.id) { property in
                                LiveAuctionCard(
                                    property: property,
                                    onARTap: {
                                        selectedProperty = property
                                        showingAR = true
                                    },
                                    onDetailTap: {
                                        selectedProperty = property
                                        showingPropertyDetail = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await biddingService.loadAuctionProperties()
                    }
                }
            }
            .background(Color.backgrounds)
            .onAppear {
                Task {
                    await biddingService.loadAuctionProperties()
                }
            }
            .alert("Error", isPresented: .constant(biddingService.error != nil)) {
                Button("OK") {
                    biddingService.error = nil
                }
            } message: {
                if let error = biddingService.error {
                    Text(error)
                }
            }
            .fullScreenCover(isPresented: $showingAR) {
                if let property = selectedProperty {
                    ARPanoramicView(
                        panoramicImages: property.panoramicImages ?? [],
                        property: property
                    )
                }
            }
            .sheet(isPresented: $showingPropertyDetail) {
                if let property = selectedProperty {
                    PropertyDetailView(
                        property: property,
                        biddingService: biddingService
                    )
                }
            }
            .sheet(isPresented: $showingAddProperty) {
                AddPropertyForAuctionView(biddingService: biddingService)
            }
        }
    }
    
    private func filteredProperties() -> [AuctionProperty] {
        switch selectedFilter {
        case "Live":
            return biddingService.auctionProperties.filter { $0.status == AuctionStatus.active }
        case "Upcoming":
            return biddingService.auctionProperties.filter { $0.status == AuctionStatus.upcoming }
        case "Ended":
            return biddingService.auctionProperties.filter { $0.status == AuctionStatus.ended }
        default:
            return biddingService.auctionProperties
        }
    }
}

// MARK: - Supporting Views

struct FilterPillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.accentBlues : Color.backgrounds)
                        .stroke(Color.accentBlues, lineWidth: 1)
                )
                .foregroundColor(isSelected ? .white : .accentBlues)
        }
    }
}

struct LiveAuctionCard: View {
    let property: AuctionProperty
    let onARTap: () -> Void
    let onDetailTap: () -> Void
    
    var body: some View {
        Button(action: onDetailTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Property Image
                PropertyImageView(property: property, onARTap: onARTap)
                
                // Property Details
                PropertyDetailsSection(property: property)
                
                // Action Buttons
                PropertyActionButtons(property: property, onDetailTap: onDetailTap)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct PropertyImageView: View {
    let property: AuctionProperty
    let onARTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: property.images.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "house.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(height: 200)
            .clipped()
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // AR Button
            Button(action: onARTap) {
                Image(systemName: "arkit")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(8)
                    .background(Circle().fill(.black.opacity(0.6)))
            }
            .padding(12)
        }
    }
}

struct PropertyDetailsSection: View {
    let property: AuctionProperty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(property.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("$\(property.currentBid, specifier: "%.0f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.accentBlues)
            }
            
            Text(property.address.fullAddress)
                .font(.subheadline)
                .foregroundColor(.secondaryTextColor)
            
            HStack {
                PropertyFeatureBadge(
                    icon: "bed.double.fill",
                    value: "\(property.features.bedrooms)"
                )
                
                PropertyFeatureBadge(
                    icon: "bathtub.fill",
                    value: "\(property.features.bathrooms)"
                )
                
                PropertyFeatureBadge(
                    icon: "square.fill",
                    value: "\(Int(property.features.area)) sqft"
                )
                
                Spacer()
                
                Text(property.status.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(property.status.color.opacity(0.2))
                    )
                    .foregroundColor(property.status.color)
            }
        }
        .padding(.horizontal, 12)
    }
}

struct PropertyActionButtons: View {
    let property: AuctionProperty
    let onDetailTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDetailTap) {
                HStack {
                    if property.status == .active {
                        Image(systemName: "hammer.fill")
                            .font(.caption)
                        Text("Place Bid")
                    } else if property.status == .upcoming {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                        Text("Set Reminder")
                    } else {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                        Text("View Details")
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentBlues)
                .cornerRadius(8)
            }
            
            Button(action: {}) {
                Image(systemName: "heart")
                    .foregroundColor(.accentBlues)
                    .font(.title3)
                    .padding(12)
                    .background(Color.accentBlues.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    BiddingScreen()
}
