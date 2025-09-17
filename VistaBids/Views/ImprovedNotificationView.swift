//
//  ImprovedNotificationView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-13.
//

import SwiftUI
import FirebaseFirestore

struct ImprovedNotificationView: View {
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var biddingService = BiddingService()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedFilter: NotificationFilter = .all
    @State private var showingDeleteConfirmation = false
    @State private var notificationToDelete: AppNotification?
    @State private var isLoading = false
    @State private var winnerNotifications: [AuctionWinnerNotification] = []
    @State private var showPaymentView = false
    @State private var selectedWinnerNotification: AuctionWinnerNotification?
    @State private var searchText = ""
    @State private var showingNotificationSettings = false
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case bidding = "Bidding"
        case auctions = "Auctions"
        case payments = "Payments"
        case community = "Community"
        case urgent = "Urgent"
        
        var icon: String {
            switch self {
            case .all: return "bell"
            case .unread: return "bell.badge"
            case .bidding: return "hammer"
            case .auctions: return "clock"
            case .payments: return "creditcard"
            case .community: return "person.3"
            case .urgent: return "exclamationmark.triangle"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .unread: return .red
            case .bidding: return .orange
            case .auctions: return .purple
            case .payments: return .green
            case .community: return .indigo
            case .urgent: return .red
            }
        }
    }
    
    var filteredNotifications: [AppNotification] {
        var notifications = notificationService.notifications
        
        // Apply text search
        if !searchText.isEmpty {
            notifications = notifications.filter { notification in
                notification.title.localizedCaseInsensitiveContains(searchText) ||
                notification.body.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply filter
        switch selectedFilter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.isRead }
        case .bidding:
            return notifications.filter { $0.type == .newBidding || $0.type == .outbid }
        case .auctions:
            return notifications.filter { $0.type == .auctionWon || $0.type == .auctionEnded }
        case .payments:
            return notifications.filter { $0.type == .general && $0.title.contains("Payment") }
        case .community:
            return notifications.filter { $0.type == .communityEvent || $0.type == .groupMessage }
        case .urgent:
            return notifications.filter { $0.priority == .urgent || $0.priority == .high }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Filter Tabs
                filterTabs
                
                // Statistics Bar
                statisticsBar
                
                // Notifications Content
                notificationsContent
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { markAllAsRead() }) {
                            Label("Mark All Read", systemImage: "checkmark.circle")
                        }
                        .disabled(notificationService.unreadCount == 0)
                        
                        Button(action: { clearAllNotifications() }) {
                            Label("Clear All", systemImage: "trash")
                        }
                        .disabled(filteredNotifications.isEmpty)
                        
                        Divider()
                        
                        Button(action: { showingNotificationSettings = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body.weight(.medium))
                    }
                }
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            .onAppear {
                loadNotifications()
            }
            .refreshable {
                await refreshNotifications()
            }
        }
        .alert("Delete Notification", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let notification = notificationToDelete {
                    Task {
                        await notificationService.deleteNotification(notification.id)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this notification?")
        }
        .sheet(isPresented: $showPaymentView) {
            if let winner = selectedWinnerNotification {
                PaymentView(
                    property: createAuctionPropertyFromWinner(winner),
                    showPaymentView: $showPaymentView
                )
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
    }
    
    // Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search notifications...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // Filter Tabs
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    NotificationFilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: getFilterCount(filter),
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    // Statistics Bar
    private var statisticsBar: some View {
        HStack {
            NotificationStatCard(
                title: "Total",
                value: "\(notificationService.notifications.count)",
                icon: "bell",
                color: .blue
            )
            
            NotificationStatCard(
                title: "Unread",
                value: "\(notificationService.unreadCount)",
                icon: "bell.badge",
                color: .red
            )
            
            NotificationStatCard(
                title: "Urgent",
                value: "\(notificationService.notifications.filter { $0.priority == .urgent }.count)",
                icon: "exclamationmark.triangle",
                color: .orange
            )
            
            NotificationStatCard(
                title: "Today",
                value: "\(getTodayNotificationCount())",
                icon: "calendar",
                color: .green
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // Notifications Content
    private var notificationsContent: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if filteredNotifications.isEmpty && winnerNotifications.isEmpty {
                EmptyNotificationsView(filter: selectedFilter)
            } else {
                notificationsList
            }
        }
    }
    
    //  Notifications List
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Winner notifications (high priority)
                ForEach(winnerNotifications.filter { $0.actionRequired }, id: \.id) { winner in
                    EnhancedWinnerNotificationCard(
                        notification: winner,
                        onPaymentTap: {
                            selectedWinnerNotification = winner
                            showPaymentView = true
                        },
                        onDismiss: {
                            
                            dismissWinnerNotification(winner)
                        }
                    )
                    .padding(.horizontal)
                }
                
                // Regular notifications
                ForEach(filteredNotifications, id: \.id) { notification in
                    EnhancedNotificationCard(
                        notification: notification,
                        onTap: {
                            handleNotificationTap(notification)
                        },
                        onDelete: {
                            notificationToDelete = notification
                            showingDeleteConfirmation = true
                        },
                        onMarkRead: {
                            if !notification.isRead {
                                Task {
                                    await notificationService.markAsRead(notification.id)
                                }
                            }
                        }
                    )
                    .padding(.horizontal)
                }
                
                // Load more button if there are more notifications
                if notificationService.notifications.count >= 50 {
                    Button("Load More") {
                        // Implement pagination
                        loadMoreNotifications()
                    }
                    .foregroundColor(.blue)
                    .padding()
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helper Methods
    private func loadNotifications() {
        isLoading = true
        Task {
            do {
                let winners = try await loadWinnerNotifications()
                await MainActor.run {
                    winnerNotifications = winners
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
    
    private func refreshNotifications() async {
        // The real-time listener should automatically refresh
        try? await Task.sleep(nanoseconds: 500_000_000) // Brief delay for visual feedback
    }
    
    private func loadWinnerNotifications() async throws -> [AuctionWinnerNotification] {
        guard !biddingService.currentUserId.isEmpty else { return [] }
        let userId = biddingService.currentUserId
        
        let query = Firestore.firestore().collection("auction_winners")
            .whereField("winnerId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: AuctionWinnerNotification.self)
        }
    }
    
    private func loadMoreNotifications() {
        
        print("Loading more notifications...")
    }
    
    private func getFilterCount(_ filter: NotificationFilter) -> Int {
        switch filter {
        case .all:
            return notificationService.notifications.count
        case .unread:
            return notificationService.unreadCount
        case .bidding:
            return notificationService.notifications.filter { $0.type == .newBidding || $0.type == .outbid }.count
        case .auctions:
            return notificationService.notifications.filter { $0.type == .auctionWon || $0.type == .auctionEnded }.count
        case .payments:
            return notificationService.notifications.filter { $0.type == .general && $0.title.contains("Payment") }.count
        case .community:
            return notificationService.notifications.filter { $0.type == .communityEvent || $0.type == .groupMessage }.count
        case .urgent:
            return notificationService.notifications.filter { $0.priority == .urgent || $0.priority == .high }.count
        }
    }
    
    private func getTodayNotificationCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return notificationService.notifications.filter { notification in
            Calendar.current.isDate(notification.timestamp, inSameDayAs: today)
        }.count
    }
    
    private func markAllAsRead() {
        Task {
            await notificationService.markAllAsRead()
        }
    }
    
    private func clearAllNotifications() {
        Task {
            for notification in filteredNotifications {
                await notificationService.deleteNotification(notification.id)
            }
        }
    }
    
    private func handleNotificationTap(_ notification: AppNotification) {
        
        if !notification.isRead {
            Task {
                await notificationService.markAsRead(notification.id)
            }
        }
        
        // Handle navigation
        switch notification.type {
        case .newBidding, .outbid, .auctionWon, .auctionEnded:
            if let propertyId = notification.data?["propertyId"] {
                // Navigate to property detail
                print("Navigate to property: \(propertyId)")
                
            }
        case .communityEvent:
            if let eventId = notification.data?["eventId"] {
                // Navigate to event detail
                print("Navigate to event: \(eventId)")
                
            }
        case .groupMessage:
            if let groupId = notification.data?["groupId"] {
                // Navigate to group chat
                print("Navigate to group: \(groupId)")
                
            }
        default:
            break
        }
        
        // Dismiss after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
    
    private func dismissWinnerNotification(_ winner: AuctionWinnerNotification) {
        // Mark winner notification as completed
        winnerNotifications.removeAll { $0.id == winner.id }
    }
    
    private func createAuctionPropertyFromWinner(_ winner: AuctionWinnerNotification) -> AuctionProperty {
        return AuctionProperty(
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

// Supporting Views

struct NotificationFilterChip: View {
    let filter: ImprovedNotificationView.NotificationFilter
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption.weight(.medium))
                
                Text(filter.rawValue)
                    .font(.caption.weight(.medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(isSelected ? filter.color : .white)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(
                            Circle()
                                .fill(isSelected ? .white : filter.color)
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? filter.color : Color(.systemGray5))
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading notifications...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyNotificationsView: View {
    let filter: ImprovedNotificationView.NotificationFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: filter == .all ? "bell.slash" : "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if filter != .all {
                Button("Show All Notifications") {
                    // This would need to be passed back to parent
                }
                .foregroundColor(.blue)
                .font(.subheadline.weight(.medium))
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all: return "No Notifications"
        case .unread: return "All Caught Up!"
        case .bidding: return "No Bidding Notifications"
        case .auctions: return "No Auction Updates"
        case .payments: return "No Payment Notifications"
        case .community: return "No Community Updates"
        case .urgent: return "No Urgent Notifications"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all: return "When you have notifications, they'll appear here."
        case .unread: return "You've read all your notifications. Great job staying on top of things!"
        case .bidding: return "No new bidding activity to show."
        case .auctions: return "No auction updates at the moment."
        case .payments: return "No payment-related notifications."
        case .community: return "No community events or messages."
        case .urgent: return "No urgent notifications requiring immediate attention."
        }
    }
}

#Preview {
    ImprovedNotificationView()
}
