//
//  NotificationSystemDemo.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-09-13.
//

import SwiftUI

struct NotificationSystemDemo: View {
    @StateObject private var notificationService = NotificationService.shared
    @State private var showingImprovedNotifications = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("VistaBids Notifications")
                        .font(.largeTitle.weight(.bold))
                    
                    Text("Enhanced notification system with real-time updates")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Stats
                HStack(spacing: 20) {
                    StatView(
                        title: "Total",
                        value: "\(notificationService.notifications.count)",
                        color: .blue
                    )
                    
                    StatView(
                        title: "Unread",
                        value: "\(notificationService.unreadCount)",
                        color: .red
                    )
                    
                    StatView(
                        title: "Today",
                        value: "\(getTodayCount())",
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        showingImprovedNotifications = true
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Open Enhanced Notifications")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    
                    Button(action: sendTestNotification) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Send Test Notification")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                    
                    Button(action: sendMultipleTestNotifications) {
                        HStack {
                            Image(systemName: "bell.badge")
                            Text("Send Multiple Test Notifications")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Features List
                VStack(alignment: .leading, spacing: 12) {
                    Text("✨ Features")
                        .font(.headline.weight(.bold))
                        .padding(.horizontal)
                    
                    FeatureRow(icon: "magnifyingglass", text: "Search notifications")
                    FeatureRow(icon: "slider.horizontal.3", text: "Smart filtering by type")
                    FeatureRow(icon: "hand.point.up.left", text: "Swipe actions (mark read/delete)")
                    FeatureRow(icon: "clock", text: "Real-time updates")
                    FeatureRow(icon: "gear", text: "Customizable settings")
                    FeatureRow(icon: "bell.slash", text: "Quiet hours support")
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingImprovedNotifications) {
            ImprovedNotificationView()
        }
    }
    
    private func getTodayCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return notificationService.notifications.filter { notification in
            Calendar.current.isDate(notification.timestamp, inSameDayAs: today)
        }.count
    }
    
    private func sendTestNotification() {
        Task {
            let notification = AppNotification(
                id: UUID().uuidString,
                userId: "current-user",
                title: "🎉 Test Notification",
                body: "This is a test notification to demonstrate the enhanced notification system!",
                type: .general,
                data: ["test": "true"],
                timestamp: Date(),
                isRead: false,
                priority: .medium
            )
            
            await notificationService.sendLocalNotification(notification)
        }
    }
    
    private func sendMultipleTestNotifications() {
        Task {
            let notifications = [
                AppNotification(
                    id: UUID().uuidString,
                    userId: "current-user",
                    title: "🏠 New Property Available",
                    body: "Beautiful downtown condo with city views is now available for auction!",
                    type: .newBidding,
                    data: ["propertyId": "prop123", "startingBid": "350000"],
                    timestamp: Date(),
                    isRead: false,
                    priority: .medium
                ),
                AppNotification(
                    id: UUID().uuidString,
                    userId: "current-user",
                    title: "⚠️ You've been outbid!",
                    body: "Someone placed a higher bid on Luxury Villa. Current bid: $750,000",
                    type: .outbid,
                    data: ["propertyId": "prop456", "currentBid": "750000"],
                    timestamp: Date().addingTimeInterval(-300),
                    isRead: false,
                    priority: .urgent
                ),
                AppNotification(
                    id: UUID().uuidString,
                    userId: "current-user",
                    title: "🎉 Auction Won!",
                    body: "Congratulations! You won the auction for Modern Apartment with a bid of $425,000",
                    type: .auctionWon,
                    data: ["propertyId": "prop789", "winningBid": "425000"],
                    timestamp: Date().addingTimeInterval(-600),
                    isRead: false,
                    priority: .high
                ),
                AppNotification(
                    id: UUID().uuidString,
                    userId: "current-user",
                    title: "💬 New Community Message",
                    body: "John Doe: Has anyone checked out the new property listings in downtown?",
                    type: .groupMessage,
                    data: ["groupId": "group123", "senderName": "John Doe"],
                    timestamp: Date().addingTimeInterval(-900),
                    isRead: false,
                    priority: .medium
                ),
                AppNotification(
                    id: UUID().uuidString,
                    userId: "current-user",
                    title: "📅 Community Event",
                    body: "Real Estate Investment Workshop - Join us tomorrow at 2 PM to learn investment strategies!",
                    type: .communityEvent,
                    data: ["eventId": "event456", "eventTitle": "Investment Workshop"],
                    timestamp: Date().addingTimeInterval(-1800),
                    isRead: true,
                    priority: .medium
                )
            ]
            
            for notification in notifications {
                await notificationService.sendLocalNotification(notification)
                try? await Task.sleep(nanoseconds: 500_000_000) // Slight delay between notifications
            }
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title.weight(.bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    NotificationSystemDemo()
}
