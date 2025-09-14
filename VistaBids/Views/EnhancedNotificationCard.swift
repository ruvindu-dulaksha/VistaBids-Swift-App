//
//  EnhancedNotificationCard.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-09-13.
//

import SwiftUI

struct EnhancedNotificationCard: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMarkRead: () -> Void
    
    @State private var showingActions = false
    @State private var offset: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    private var notificationColor: Color {
        switch notification.priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
    
    private var notificationIcon: String {
        switch notification.type {
        case .newBidding: return "hammer.fill"
        case .newSelling: return "house.fill"
        case .outbid: return "exclamationmark.triangle.fill"
        case .auctionWon: return "trophy.fill"
        case .auctionEnded: return "clock.fill"
        case .communityEvent: return "calendar"
        case .groupMessage: return "message.fill"
        case .general: return "bell.fill"
        }
    }
    
    private var timeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.timestamp, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Main notification content
            notificationContent
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if value.translation.width < -100 {
                                    // Show actions
                                    offset = -120
                                    showingActions = true
                                } else if value.translation.width > 100 {
                                    // Mark as read
                                    onMarkRead()
                                    offset = 0
                                    showingActions = false
                                } else {
                                    // Reset
                                    offset = 0
                                    showingActions = false
                                }
                            }
                        }
                )
            
            // Action buttons (revealed on swipe)
            if showingActions {
                actionButtons
                    .transition(.move(edge: .trailing))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            if !showingActions {
                onTap()
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 0
                    showingActions = false
                }
            }
        }
    }
    
    private var notificationContent: some View {
        HStack(spacing: 16) {
            // Priority indicator and icon
            VStack {
                ZStack {
                    Circle()
                        .fill(notificationColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: notificationIcon)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(notificationColor)
                }
                
                if !notification.isRead {
                    Circle()
                        .fill(notificationColor)
                        .frame(width: 8, height: 8)
                        .offset(y: -5)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if notification.priority == .urgent {
                            Text("URGENT")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.red)
                                )
                        }
                    }
                }
                
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Additional metadata
                if let metadata = notification.data {
                    HStack {
                        ForEach(Array(metadata.prefix(2)), id: \.key) { key, value in
                            if key != "propertyId" && key != "eventId" && key != "groupId" {
                                Text("\(key): \(value)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemGray6))
                                    )
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(notification.isRead ? 
                      Color(.systemBackground) : 
                      notificationColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            notification.isRead ? 
                            Color(.systemGray5) : 
                            notificationColor.opacity(0.3),
                            lineWidth: notification.isRead ? 1 : 2
                        )
                )
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Mark as read/unread button
            Button(action: onMarkRead) {
                VStack {
                    Image(systemName: notification.isRead ? "envelope.badge" : "envelope.open")
                        .font(.title3)
                    Text(notification.isRead ? "Unread" : "Read")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
            
            // Delete button
            Button(action: onDelete) {
                VStack {
                    Image(systemName: "trash")
                        .font(.title3)
                    Text("Delete")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                )
            }
        }
    }
}

struct EnhancedWinnerNotificationCard: View {
    let notification: AuctionWinnerNotification
    let onPaymentTap: () -> Void
    let onDismiss: () -> Void
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    // Since paymentDeadline is not in the model, we'll calculate it
    private let paymentDeadlineHours: TimeInterval = 24 * 3600 // 24 hours
    
    private var isExpired: Bool {
        timeRemaining <= 0
    }
    
    private var formattedTimeRemaining: String {
        if isExpired {
            return "Payment Overdue"
        }
        
        let hours = Int(timeRemaining) / 3600
        let minutes = Int(timeRemaining) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
    
    private var urgencyColor: Color {
        if isExpired {
            return .red
        } else if timeRemaining < 3600 { // Less than 1 hour
            return .orange
        } else if timeRemaining < 7200 { // Less than 2 hours
            return .yellow
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with trophy icon
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎉 Auction Won!")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text("Payment Required")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )
                }
            }
            .padding(16)
            
            Divider()
            
            // Property details
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notification.propertyTitle)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text("Winning Bid: $\(Int(notification.winningBid).formatted())")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
                
                // Payment deadline
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(urgencyColor)
                    
                    Text(formattedTimeRemaining)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(urgencyColor)
                    
                    Spacer()
                    
                    Text("Payment Deadline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(urgencyColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(urgencyColor.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onPaymentTap) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                            Text("Make Payment")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
                    
                    Button(action: {
                        // Navigate to property details
                        print("Navigate to property details: \(notification.propertyID)")
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("View Property")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [urgencyColor, urgencyColor.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: urgencyColor.opacity(0.2), radius: 8, x: 0, y: 4)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        updateTimeRemaining()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        let deadline = notification.timestamp.addingTimeInterval(paymentDeadlineHours)
        timeRemaining = deadline.timeIntervalSince(Date())
    }
}

// MARK: - Preview

#Preview("Enhanced Notification Card") {
    VStack(spacing: 16) {
        EnhancedNotificationCard(
            notification: AppNotification(
                id: "1",
                userId: "user1",
                title: "New Bid on Your Property",
                body: "Someone just placed a bid of $450,000 on your Downtown Condo listing",
                type: .newBidding,
                data: ["propertyId": "prop123", "bidAmount": "450000"],
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false,
                priority: .high
            ),
            onTap: { print("Tapped") },
            onDelete: { print("Delete") },
            onMarkRead: { print("Mark read") }
        )
        
        EnhancedNotificationCard(
            notification: AppNotification(
                id: "2",
                userId: "user1",
                title: "You've been outbid!",
                body: "Your bid on Luxury Villa has been exceeded. The current highest bid is $750,000",
                type: .outbid,
                data: ["propertyId": "prop456", "currentBid": "750000"],
                timestamp: Date().addingTimeInterval(-7200),
                isRead: true,
                priority: .urgent
            ),
            onTap: { print("Tapped") },
            onDelete: { print("Delete") },
            onMarkRead: { print("Mark read") }
        )
    }
    .padding()
}

#Preview("Enhanced Winner Card") {
    EnhancedWinnerNotificationCard(
        notification: AuctionWinnerNotification(
            id: "winner1",
            propertyID: "prop123",
            propertyTitle: "Beautiful Downtown Condo with City Views",
            winningBid: 425000,
            timestamp: Date().addingTimeInterval(-1800), // 30 minutes ago
            isRead: false,
            actionRequired: true
        ),
        onPaymentTap: { print("Payment tapped") },
        onDismiss: { print("Dismissed") }
    )
    .padding()
}
