import SwiftUI

struct UserActivityView: View {
    @ObservedObject var biddingService: BiddingService
    @ObservedObject var paymentService: PaymentService
    @State private var isLoading = true
    @State private var selectedFilter: ActivityFilter = .all
    
    enum ActivityFilter: String, CaseIterable {
        case all = "All"
        case bids = "Bids"
        case purchases = "Purchases"
        case watchlist = "Watchlist"
        
        var systemImage: String {
            switch self {
            case .all: return "list.bullet"
            case .bids: return "hammer"
            case .purchases: return "bag"
            case .watchlist: return "heart"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ActivityFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            withAnimation {
                                selectedFilter = filter
                            }
                        }) {
                            HStack {
                                Image(systemName: filter.systemImage)
                                Text(filter.rawValue)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.accentBlues : Color.secondaryBackground)
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            
            Divider()
            
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if filteredActivities.isEmpty {
                emptyStateView
            } else {
                activityList
            }
        }
        .navigationTitle("Your Activity")
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(emptyStateMessage)
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text(emptyStateDescription)
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredActivities) { activity in
                    ActivityRow(activity: activity, biddingService: biddingService)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Helper Properties
    
    private var filteredActivities: [ActivityItem] {
        switch selectedFilter {
        case .all:
            return combinedActivities
        case .bids:
            return biddingService.userBids.map { ActivityItem(from: $0) }
        case .purchases:
            return paymentService.purchaseHistory.map { ActivityItem(from: $0) }
        case .watchlist:
            return biddingService.watchlist.map { ActivityItem(from: $0) }
        }
    }
    
    private var combinedActivities: [ActivityItem] {
        var activities: [ActivityItem] = []
        
        // Add bids
        activities.append(contentsOf: biddingService.userBids.map { ActivityItem(from: $0) })
        
        // Add purchases
        activities.append(contentsOf: paymentService.purchaseHistory.map { ActivityItem(from: $0) })
        
        // Add watchlist items
        activities.append(contentsOf: biddingService.watchlist.map { ActivityItem(from: $0) })
        
        // Sort by date (newest first)
        return activities.sorted { $0.date > $1.date }
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "list.bullet"
        case .bids: return "hammer"
        case .purchases: return "bag"
        case .watchlist: return "heart"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all: return "No activity yet"
        case .bids: return "No bids yet"
        case .purchases: return "No purchases yet"
        case .watchlist: return "Nothing in watchlist"
        }
    }
    
    private var emptyStateDescription: String {
        switch selectedFilter {
        case .all: 
            return "Your bidding, purchase, and watchlist activity will appear here"
        case .bids: 
            return "When you place bids on properties, they will appear here"
        case .purchases: 
            return "Properties you have purchased will be listed here"
        case .watchlist: 
            return "Add properties to your watchlist to keep track of them"
        }
    }
    
    // MARK: - Methods
    
    private func loadData() {
        isLoading = true
        
        Task {
            do {
                try await biddingService.fetchUserBids()
                try await biddingService.fetchAuctionProperties()
                // Note: PaymentService already has listeners set up in init()
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print("Error loading activity data: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - ActivityItem Model

struct ActivityItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let date: Date
    let type: ActivityType
    let status: String
    let statusColor: Color
    let propertyId: String
    let imageURL: String?
    
    enum ActivityType {
        case bid
        case purchase
        case watchlist
        
        var icon: String {
            switch self {
            case .bid: return "hammer.fill"
            case .purchase: return "bag.fill"
            case .watchlist: return "heart.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .bid: return .blue
            case .purchase: return .green
            case .watchlist: return .red
            }
        }
    }
    
    init(from bid: UserBid) {
        self.id = bid.id
        self.title = "Bid on \(bid.propertyTitle)"
        self.description = "Bid Amount: $\(Int(bid.bidAmount))"
        self.date = bid.bidTime
        self.type = .bid
        self.status = bid.status.displayText
        self.statusColor = Color(bid.status.color)
        self.propertyId = bid.propertyId
        self.imageURL = nil
    }
    
    init(from purchase: UserPurchaseHistory) {
        self.id = purchase.id ?? UUID().uuidString
        self.title = "Purchased \(purchase.propertyTitle)"
        self.description = "Purchase Amount: $\(Int(purchase.purchasePrice))"
        self.date = purchase.purchaseDate
        self.type = .purchase
        self.status = purchase.paymentStatus.displayText
        self.statusColor = Color(purchase.paymentStatus.color)
        self.propertyId = purchase.propertyId
        self.imageURL = purchase.propertyImages.first
    }
    
    init(from watchlist: WatchlistItem) {
        self.id = watchlist.id
        self.title = "Added to Watchlist"
        self.description = "Property ID: \(watchlist.propertyID)"
        self.date = watchlist.addedDate
        self.type = .watchlist
        self.status = "Watching"
        self.statusColor = .orange
        self.propertyId = watchlist.propertyID
        self.imageURL = nil
    }
}

// MARK: - Activity Row View

struct ActivityRow: View {
    let activity: ActivityItem
    @ObservedObject var biddingService: BiddingService
    @State private var navigateToDetail = false
    @State private var selectedProperty: AuctionProperty?
    
    var body: some View {
        ZStack {
            // Main content
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(activity.type.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: activity.type.icon)
                        .foregroundColor(activity.type.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(activity.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(activity.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status
                Text(activity.status)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(activity.statusColor.opacity(0.2))
                    .foregroundColor(activity.statusColor)
                    .cornerRadius(4)
            }
            .padding()
            .background(Color.secondaryBackground)
            .cornerRadius(12)
            .onTapGesture {
                loadPropertyAndNavigate(propertyId: activity.propertyId)
            }
            
            // Navigation link (hidden)
            if let property = selectedProperty {
                NavigationLink(
                    destination: PropertyDetailView(property: property, biddingService: biddingService),
                    isActive: $navigateToDetail
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
    }
    
    private func loadPropertyAndNavigate(propertyId: String) {
        Task {
            do {
                try await biddingService.fetchAuctionProperties()
                if let property = biddingService.auctionProperties.first(where: { $0.id == propertyId }) {
                    await MainActor.run {
                        selectedProperty = property
                        navigateToDetail = true
                    }
                }
            } catch {
                print("Error loading property: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NavigationView {
        UserActivityView(
            biddingService: BiddingService(),
            paymentService: PaymentService()
        )
    }
}
