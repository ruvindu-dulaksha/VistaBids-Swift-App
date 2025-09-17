//
//  EnhancedProfileView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-24.
//

import SwiftUI

struct EnhancedProfileView: View {
    @StateObject private var paymentService = PaymentService()
    @StateObject private var biddingService = BiddingService()
    @State private var selectedTab = 0
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    private let tabs = ["Overview", "Purchases", "Bids", "Watchlist", "Transactions"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Profile Header
                profileHeader
                
                // Tab Selection
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Overview Tab
                    OverviewTab(
                        purchases: paymentService.purchaseHistory,
                        bids: biddingService.userBids,
                        watchlist: biddingService.watchlist
                    )
                    .tag(0)
                    
                    // Purchases Tab
                    PurchasesTab(purchases: paymentService.purchaseHistory)
                        .tag(1)
                    
                    // Bids Tab
                    BidsTab(bids: biddingService.userBids)
                        .tag(2)
                    
                    // Watchlist Tab
                    WatchlistTab(watchlist: biddingService.watchlist)
                        .tag(3)
                    
                    // Transactions Tab
                    TransactionsTab(transactions: paymentService.transactions)
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Profile", systemImage: "person.circle") {
                            showingEditProfile = true
                        }
                        
                        Button("Settings", systemImage: "gear") {
                            showingSettings = true
                        }
                        
                        Button("Help & Support", systemImage: "questionmark.circle") {
                            // Navigate to help
                        }
                        
                        Divider()
                        
                        Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") {
                            // Sign out logic
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image and Info
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("John Doe") // Replace with actual user name
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Member since March 2024")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("4.8")
                        Text("(24 reviews)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
                
                Spacer()
            }
            
            // Quick Stats
            HStack(spacing: 20) {
                StatCard(
                    title: "Properties\nPurchased",
                    value: "\(paymentService.purchaseHistory.count)",
                    color: .green
                )
                
                StatCard(
                    title: "Active\nBids",
                    value: "\(biddingService.userBids.filter { $0.status == .active }.count)",
                    color: .blue
                )
                
                StatCard(
                    title: "Watching",
                    value: "\(biddingService.watchlist.count)",
                    color: .orange
                )
                
                StatCard(
                    title: "Total\nSpent",
                    value: String(format: "$%.0fK", totalSpent),
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(tabs[index])
                                .font(.subheadline)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? .blue : .secondary)
                            
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedTab == index ? .blue : .clear)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var totalSpent: Double {
        return paymentService.purchaseHistory.reduce(0) { $0 + $1.purchasePrice } / 1000
    }
}

// Overview Tab
struct OverviewTab: View {
    let purchases: [UserPurchaseHistory]
    let bids: [UserBid]
    let watchlist: [WatchlistItem]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Recent Activity
                RecentActivitySection(purchases: purchases, bids: bids)
                
                // Achievement Section
                AchievementsSection(purchases: purchases, bids: bids)
                
                // Quick Actions
                QuickActionsSection()
            }
            .padding()
        }
    }
}

// Purchases Tab
struct PurchasesTab: View {
    let purchases: [UserPurchaseHistory]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(purchases) { purchase in
                    PurchaseCard(purchase: purchase)
                }
            }
            .padding()
        }
    }
}

// Bids Tab
struct BidsTab: View {
    let bids: [UserBid]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(bids) { bid in
                    BidCard(bid: bid)
                }
            }
            .padding()
        }
    }
}

//  Watchlist Tab
struct WatchlistTab: View {
    let watchlist: [WatchlistItem]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(watchlist) { item in
                    WatchlistCard(item: item)
                }
            }
            .padding()
        }
    }
}

//  Transactions Tab
struct TransactionsTab: View {
    let transactions: [TransactionHistory]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(transactions) { transaction in
                    TransactionCard(transaction: transaction)
                }
            }
            .padding()
        }
    }
}

// Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct PurchaseCard: View {
    let purchase: UserPurchaseHistory
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: purchase.propertyImages.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(purchase.propertyTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Purchased: \(purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("$\(purchase.purchasePrice, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(purchase.paymentStatus.displayText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(purchase.paymentStatus.color).opacity(0.2))
                        .foregroundColor(Color(purchase.paymentStatus.color))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BidCard: View {
    let bid: UserBid
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bid.propertyTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Bid: $\(bid.bidAmount, specifier: "%.0f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(bid.bidTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(bid.status.displayText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(bid.status.color).opacity(0.2))
                    .foregroundColor(Color(bid.status.color))
                    .cornerRadius(4)
                
                if bid.isWinning {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WatchlistCard: View {
    let item: WatchlistItem
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Property ID: \(item.propertyID)")
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Added: \(item.addedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Notifications: \(item.notificationsEnabled ? "On" : "Off")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if item.notificationsEnabled {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.blue)
                }
                
                Button("Place Bid") {
                    // Navigate to bidding
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TransactionCard: View {
    let transaction: TransactionHistory
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                                        Text(transaction.type.rawValue.capitalized)
                    .font(.headline)
                
                Text(transaction.propertyTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(transaction.amount, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(transaction.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(getStatusColor(transaction.status).opacity(0.2))
                    .foregroundColor(getStatusColor(transaction.status))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getStatusColor(_ status: TransactionStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        case .refunded:
            return .blue
        }
    }
}

struct RecentActivitySection: View {
    let purchases: [UserPurchaseHistory]
    let bids: [UserBid]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
            
            // Show recent purchases and bids separately
            let recentPurchases = Array(purchases.prefix(3))
            let recentBids = Array(bids.prefix(3))
            
            if recentPurchases.isEmpty && recentBids.isEmpty {
                emptyActivityView
            } else {
                activityContentView(recentPurchases: recentPurchases, recentBids: recentBids)
            }
        }
    }
    
    private var emptyActivityView: some View {
        Text("No recent activity")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
    
    private func activityContentView(recentPurchases: [UserPurchaseHistory], recentBids: [UserBid]) -> some View {
        VStack(spacing: 8) {
            ForEach(recentPurchases) { purchase in
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(.green)
                    Text("Purchased \(purchase.propertyTitle)")
                        .lineLimit(1)
                    Spacer()
                    Text(purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ForEach(recentBids) { bid in
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.blue)
                    Text("Bid on \(bid.propertyTitle)")
                        .lineLimit(1)
                    Spacer()
                    Text(bid.bidTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AchievementsSection: View {
    let purchases: [UserPurchaseHistory]
    let bids: [UserBid]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AchievementBadge(
                    title: "First Purchase",
                    description: "Made your first property purchase",
                    icon: "house.fill",
                    color: .green,
                    isUnlocked: !purchases.isEmpty
                )
                
                AchievementBadge(
                    title: "Active Bidder",
                    description: "Placed 10+ bids",
                    icon: "hammer.fill",
                    color: .blue,
                    isUnlocked: bids.count >= 10
                )
                
                AchievementBadge(
                    title: "Big Spender",
                    description: "Spent over $1M",
                    icon: "dollarsign.circle.fill",
                    color: .purple,
                    isUnlocked: purchases.reduce(0) { $0 + $1.purchasePrice } > 1_000_000
                )
                
                AchievementBadge(
                    title: "Collector",
                    description: "Own 5+ properties",
                    icon: "building.2.fill",
                    color: .orange,
                    isUnlocked: purchases.count >= 5
                )
            }
        }
    }
}

struct AchievementBadge: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? color : .gray)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isUnlocked ? .primary : .gray)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(isUnlocked ? color.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Browse Auctions",
                    icon: "hammer",
                    color: .blue
                ) {
                    // Navigate to auctions
                }
                
                QuickActionButton(
                    title: "My Watchlist",
                    icon: "heart",
                    color: .red
                ) {
                    // Navigate to watchlist
                }
                
                QuickActionButton(
                    title: "Payment Methods",
                    icon: "creditcard",
                    color: .green
                ) {
                    // Navigate to payment methods
                }
                
                QuickActionButton(
                    title: "Settings",
                    icon: "gear",
                    color: .gray
                ) {
                    // Navigate to settings
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Supporting Views
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Edit Profile")
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") { dismiss() }
                    }
                }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Settings")
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    EnhancedProfileView()
}
