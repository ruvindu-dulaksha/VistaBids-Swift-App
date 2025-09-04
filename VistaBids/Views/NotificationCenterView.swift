import SwiftUI
import UserNotifications
import FirebaseFirestore

// MARK: - Notification Models
struct AuctionNotification: Codable, Identifiable {
    let id: String?
    let userId: String
    let title: String
    let body: String
    let type: NotificationType
    let data: [String: String]
    let isRead: Bool
    let createdAt: Date
    
    enum NotificationType: String, Codable {
        case auctionWin = "auction_win"
        case newBid = "new_bid"
        case outbid = "outbid"
        case auctionStart = "auction_start"
        case auctionEnd = "auction_end"
        case paymentSuccess = "payment_success"
        case paymentFailed = "payment_failed"
        case newBidding = "new_bidding"
    }
}

struct NotificationCenterView: View {
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var biddingService = BiddingService()
    @State private var notifications: [AuctionNotification] = []
    @State private var winnerNotifications: [AuctionWinnerNotification] = []
    @State private var isLoading = true
    @State private var selectedFilter: NotificationFilter = .all
    @State private var showPaymentView = false
    @State private var selectedPropertyId = ""
    @State private var selectedWinnerNotification: AuctionWinnerNotification?
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case wins = "Wins"
        case bids = "Bids"
        case auctions = "Auctions"
        case payments = "Payments"
        
        var icon: String {
            switch self {
            case .all: return "bell"
            case .wins: return "crown"
            case .bids: return "hammer"
            case .auctions: return "timer"
            case .payments: return "creditcard"
            }
        }
    }
    
    var filteredNotifications: [AuctionNotification] {
        switch selectedFilter {
        case .all:
            return notifications
        case .wins:
            return notifications.filter { $0.type == .auctionWin }
        case .bids:
            return notifications.filter { $0.type == .newBid || $0.type == .outbid }
        case .auctions:
            return notifications.filter { $0.type == .auctionStart || $0.type == .auctionEnd }
        case .payments:
            return notifications.filter { $0.type == .paymentSuccess || $0.type == .paymentFailed }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter tabs
                filterTabs
                
                // Notifications list
                if isLoading {
                    ProgressView("Loading notifications...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredNotifications.isEmpty && winnerNotifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        clearAllNotifications()
                    }
                    .disabled(notifications.isEmpty)
                }
            }
            .onAppear {
                loadNotifications()
                requestNotificationPermission()
            }
            .refreshable {
                loadNotifications()
            }
            .sheet(isPresented: $showPaymentView, onDismiss: {
                loadNotifications()
            }) {
                if let winner = selectedWinnerNotification {
                    PaymentView(
                        property: createAuctionPropertyFromWinner(winner),
                        winningAmount: winner.winningBid
                    )
                }
            }
        }
    }
    
    // MARK: - Filter Tabs
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: getNotificationCount(for: filter)
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Notifications List
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Winner notifications (priority)
                ForEach(winnerNotifications.filter { $0.actionRequired }, id: \.id) { winner in
                    WinnerNotificationCard(
                        notification: winner,
                        onPaymentTap: {
                            selectedWinnerNotification = winner
                            showPaymentView = true
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                
                // Regular notifications
                ForEach(filteredNotifications, id: \.id) { notification in
                    NotificationCard(notification: notification) {
                        handleNotificationTap(notification)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 1)
                }
            }
            .padding(.top, 12)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Notifications")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("You're all caught up! New notifications will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Methods
    private func loadNotifications() {
        isLoading = true
        
        Task {
            do {
                // Load winner notifications
                let loadedWinners = try await loadWinnerNotifications()
                
                await MainActor.run {
                    // notifications = notificationService.notifications // TODO: Convert AppNotification to AuctionNotification
                    notifications = [] // Temporary - need to implement proper conversion
                    winnerNotifications = loadedWinners
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Error loading notifications: \(error)")
            }
        }
    }
    
    private func loadWinnerNotifications() async throws -> [AuctionWinnerNotification] {
        guard !biddingService.currentUserId.isEmpty else { return [] }
        let userId = biddingService.currentUserId
        
        let query = Firestore.firestore().collection("auction_winners")
            .whereField("winnerId", isEqualTo: userId)
            .order(by: "auctionEndTime", descending: true)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: AuctionWinnerNotification.self)
        }
    }
    
    private func getNotificationCount(for filter: NotificationFilter) -> Int {
        switch filter {
        case .all:
            return notifications.count + winnerNotifications.count
        case .wins:
            return winnerNotifications.count + notifications.filter { $0.type == .auctionWin }.count
        case .bids:
            return notifications.filter { $0.type == .newBid || $0.type == .outbid }.count
        case .auctions:
            return notifications.filter { $0.type == .auctionStart || $0.type == .auctionEnd }.count
        case .payments:
            return notifications.filter { $0.type == .paymentSuccess || $0.type == .paymentFailed }.count
        }
    }
    
    private func handleNotificationTap(_ notification: AuctionNotification) {
        // Handle navigation based on notification type
        switch notification.type {
        case .auctionWin, .newBid, .outbid:
            // Navigate to property details
            break
        case .auctionStart, .auctionEnd:
            // Navigate to auction
            break
        case .paymentSuccess, .paymentFailed:
            // Navigate to transaction history
            break
        default:
            break
        }
        
        // Mark as read
        markAsRead(notification)
    }
    
    private func markAsRead(_ notification: AuctionNotification) {
        Task {
            // try await notificationService.markNotificationAsRead(notificationId: notification.id ?? "")
            // TODO: Implement markNotificationAsRead in NotificationService
            loadNotifications()
        }
    }
    
    private func clearAllNotifications() {
        Task {
            // try await notificationService.clearAllNotifications()
            // TODO: Implement clearAllNotifications in NotificationService
            await MainActor.run {
                notifications.removeAll()
                winnerNotifications.removeAll()
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct FilterTab: View {
    let filter: NotificationCenterView.NotificationFilter
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationCard: View {
    let notification: AuctionNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.1))
                    .clipShape(Circle())
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(notification.body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    Text(timeAgo(from: notification.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(notification.isRead ? Color(.systemBackground) : Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch notification.type {
        case .auctionWin:
            return "crown.fill"
        case .newBid:
            return "hammer.fill"
        case .outbid:
            return "exclamationmark.triangle.fill"
        case .auctionStart:
            return "play.circle.fill"
        case .auctionEnd:
            return "stop.circle.fill"
        case .paymentSuccess:
            return "checkmark.circle.fill"
        case .paymentFailed:
            return "xmark.circle.fill"
        default:
            return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .auctionWin:
            return .yellow
        case .newBid:
            return .blue
        case .outbid:
            return .orange
        case .auctionStart:
            return .green
        case .auctionEnd:
            return .gray
        case .paymentSuccess:
            return .green
        case .paymentFailed:
            return .red
        default:
            return .blue
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

struct WinnerNotificationCard: View {
    let notification: AuctionWinnerNotification
    let onPaymentTap: () -> Void
    
    private var timeRemaining: String {
        // Calculate deadline as 24 hours from notification timestamp
        let deadline = notification.timestamp.addingTimeInterval(24 * 60 * 60)
        let remaining = deadline.timeIntervalSince(Date())
        
        if remaining <= 0 {
            return "Payment overdue"
        } else if remaining < 3600 {
            let minutes = Int(remaining / 60)
            return "\(minutes) minutes left"
        } else {
            let hours = Int(remaining / 3600)
            return "\(hours) hours left"
        }
    }
    
    private var isOverdue: Bool {
        // Calculate deadline as 24 hours from notification timestamp
        let deadline = notification.timestamp.addingTimeInterval(24 * 60 * 60)
        return deadline < Date()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎉 Congratulations!")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("You won the auction!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if notification.actionRequired {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timeRemaining)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isOverdue ? .red : .orange)
                        
                        Text("to pay")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Property info
            VStack(alignment: .leading, spacing: 8) {
                Text(notification.propertyTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Winning Amount:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(notification.winningBid, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Action button
            if notification.actionRequired {
                Button(action: onPaymentTap) {
                    HStack {
                        Image(systemName: "creditcard")
                        Text("Complete Payment")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isOverdue ? Color.red : Color.green)
                    .cornerRadius(8)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Payment Completed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Helper Functions for NotificationCenterView
extension NotificationCenterView {
    private func createAuctionPropertyFromWinner(_ winner: AuctionWinnerNotification) -> AuctionProperty {
        return AuctionProperty(
            id: winner.propertyID,
            sellerId: "",
            sellerName: "",
            title: winner.propertyTitle,
            description: "",
            startingPrice: 0,
            currentBid: winner.winningBid,
            highestBidderId: "current-user",
            highestBidderName: "Current User",
            images: [],
            videos: [],
            arModelURL: nil,
            address: PropertyAddress(street: "", city: "", state: "", postalCode: "", country: ""),
            location: GeoPoint(latitude: 0, longitude: 0),
            features: PropertyFeatures(
                bedrooms: 0,
                bathrooms: 0,
                area: 0.0,
                yearBuilt: 2024,
                parkingSpaces: 0,
                hasGarden: false,
                hasPool: false,
                hasGym: false,
                floorNumber: 0,
                totalFloors: 0,
                propertyType: "Apartment"
            ),
            auctionStartTime: Date(),
            auctionEndTime: winner.timestamp,
            auctionDuration: .thirtyMinutes,
            status: .ended,
            category: .residential,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: Date(),
            updatedAt: Date(),
            winnerId: "current-user",
            winnerName: "Current User",
            finalPrice: winner.winningBid,
            paymentStatus: .pending,
            transactionId: nil,
            panoramicImages: [],
            walkthroughVideoURL: nil
        )
    }
}

#Preview {
    NotificationCenterView()
}
