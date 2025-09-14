import SwiftUI

struct BiddingScreen: View {
    @ObservedObject private var biddingService = BiddingService()
    @State private var selectedFilter = "All"
    @State private var showingAR = false
    @State private var selectedProperty: AuctionProperty?
    @State private var showingPropertyDetail = false
    @State private var showingAddProperty = false
    @State private var refreshTimer: Timer? = nil
    
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
                
                // Filter Pills with Counts
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FilterPillButtonWithCount(
                                title: filter,
                                count: getCountForFilter(filter),
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
                                    },
                                    biddingService: biddingService
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
                    
                    // Setup auto-refresh timer (every 30 seconds)
                    self.refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                        Task {
                            await biddingService.loadAuctionProperties()
                        }
                    }
                }
            }
            .onDisappear {
                // Invalidate the timer when leaving the screen
                refreshTimer?.invalidate()
                refreshTimer = nil
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
                        panoramicImages: property.panoramicImages,
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
                .sorted(by: { $0.auctionEndTime < $1.auctionEndTime }) // Sort by end time (soonest ending first)
        case "Upcoming":
            return biddingService.auctionProperties.filter { $0.status == AuctionStatus.upcoming }
                .sorted(by: { $0.auctionStartTime < $1.auctionStartTime }) // Sort by start time (soonest starting first)
        case "Ended":
            return biddingService.auctionProperties.filter { $0.status == AuctionStatus.ended }
                .sorted(by: { $0.auctionEndTime > $1.auctionEndTime }) // Sort by end time (most recently ended first)
        default:
            // For "All", prioritize live auctions, then upcoming, then ended
            let live = biddingService.auctionProperties.filter { $0.status == AuctionStatus.active }
                .sorted(by: { $0.auctionEndTime < $1.auctionEndTime })
            
            let upcoming = biddingService.auctionProperties.filter { $0.status == AuctionStatus.upcoming }
                .sorted(by: { $0.auctionStartTime < $1.auctionStartTime })
            
            let ended = biddingService.auctionProperties.filter { $0.status == AuctionStatus.ended }
                .sorted(by: { $0.auctionEndTime > $1.auctionEndTime })
            
            return live + upcoming + ended
        }
    }
    
    private func getCountForFilter(_ filter: String) -> Int {
        switch filter {
        case "Live":
            return biddingService.auctionProperties.filter { $0.status == AuctionStatus.active }.count
        case "Upcoming":
            return biddingService.auctionProperties.filter { $0.status == AuctionStatus.upcoming }.count
        case "Ended":
            return biddingService.auctionProperties.filter { $0.status == AuctionStatus.ended }.count
        default:
            return biddingService.auctionProperties.count
        }
    }
}

// MARK: - Supporting Views
struct FilterPillButtonWithCount: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.3) : Color.accentBlues.opacity(0.2))
                        )
                }
            }
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
    @ObservedObject var biddingService: BiddingService
    
    var body: some View {
        Button(action: onDetailTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Property Image
                PropertyImageView(property: property, onARTap: onARTap)
                
                // Property Details
                PropertyDetailsSection(property: property, biddingService: biddingService)
                
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
    @ObservedObject var biddingService: BiddingService
    
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
            
            // Live auction timing with countdown
            liveAuctionTimingInfo
                .font(.caption)
                .foregroundColor(timingTextColor)
                .padding(.vertical, 2)
            
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
            
            // Bid count or watchlist count
            HStack(spacing: 12) {
                if !property.bidHistory.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(property.bidHistory.count) bids")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if !property.watchlistUsers.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(property.watchlistUsers.count) watching")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if !property.panoramicImages.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arkit")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(property.panoramicImages.count) AR views")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 12)
    }
    
    private var liveAuctionTimingInfo: some View {
        Group {
            if let propertyId = property.id {
                let timerService = biddingService.auctionTimerService
                let timeRemainingText = timerService.getTimeRemainingText(for: propertyId)
                
                HStack(spacing: 4) {
                    // Dynamic icon based on status
                    Image(systemName: iconForStatus)
                        .font(.caption2)
                        .foregroundColor(timingTextColor)
                    
                    Text(timeRemainingText)
                        .fontWeight(.medium)
                        .foregroundColor(timingTextColor)
                    
                    // Add pulsing effect for active auctions
                    if property.status == .active,
                       let timeRemaining = timerService.auctionTimeRemaining[propertyId],
                       timeRemaining > 0 && timeRemaining <= 300 {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .symbolEffect(.pulse, options: .repeating)
                    }
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text("Loading...")
                }
            }
        }
    }
    
    private var iconForStatus: String {
        switch property.status {
        case .upcoming:
            return "clock.fill"
        case .active:
            if let propertyId = property.id,
               let timeRemaining = biddingService.auctionTimerService.auctionTimeRemaining[propertyId],
               timeRemaining <= 300 {
                return "timer" // Critical time
            }
            return "timer"
        case .ended:
            return "checkmark.circle.fill"
        case .sold:
            return "bag.fill"
        case .cancelled:
            return "xmark.circle.fill"
        }
    }
    
    private var timingTextColor: Color {
        guard let propertyId = property.id else { return .gray }
        
        switch property.status {
        case .upcoming:
            return .blue
        case .active:
            if let timeRemaining = biddingService.auctionTimerService.auctionTimeRemaining[propertyId] {
                if timeRemaining <= 60 {
                    return .red
                } else if timeRemaining <= 300 {
                    return .orange
                } else {
                    return .green
                }
            }
            return .green
        case .ended:
            return .gray
        case .sold:
            return .purple
        case .cancelled:
            return .red
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
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
