//
//  NotificationView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-21.
//

import SwiftUI

struct NotificationView: View {
    @StateObject private var notificationService = NotificationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: AppNotification.NotificationType? = nil
    @State private var showingDeleteConfirmation = false
    @State private var notificationToDelete: AppNotification?
    
    var filteredNotifications: [AppNotification] {
        if let selectedFilter = selectedFilter {
            return notificationService.notifications.filter { $0.type == selectedFilter }
        }
        return notificationService.notifications
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Tabs
                filterTabs
                
                // Notifications List
                if filteredNotifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Mark All Read") {
                            Task {
                                await notificationService.markAllAsRead()
                            }
                        }
                        
                        Button("Clear Filter") {
                            selectedFilter = nil
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
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
    }
    
    // Filter Tabs
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All tab
                filterTab(title: "All", type: nil, count: notificationService.notifications.count)
                
                // Type-specific tabs
                ForEach(AppNotification.NotificationType.allCases, id: \.self) { type in
                    let count = notificationService.notifications.filter { $0.type == type }.count
                    if count > 0 {
                        filterTab(title: type.displayName, type: type, count: count)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.navigationBackground)
    }
    
    private func filterTab(title: String, type: AppNotification.NotificationType?, count: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = type
            }
        }) {
            HStack(spacing: 6) {
                if let type = type {
                    Image(systemName: type.icon)
                        .font(.caption)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentBlues)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedFilter == type ? Color.accentBlues : Color.inputFields
            )
            .foregroundColor(
                selectedFilter == type ? .white : .textPrimary
            )
            .cornerRadius(20)
        }
    }
    
    // Notifications List
    private var notificationsList: some View {
        List {
            ForEach(filteredNotifications) { notification in
                NotificationRowView(
                    notification: notification,
                    onTap: {
                        if !notification.isRead {
                            Task {
                                await notificationService.markAsRead(notification.id)
                            }
                        }
                        handleNotificationTap(notification)
                    },
                    onDelete: {
                        notificationToDelete = notification
                        showingDeleteConfirmation = true
                    }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            
        }
    }
    
    // Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(selectedFilter == nil ? "No notifications yet" : "No \(selectedFilter?.displayName.lowercased() ?? "") notifications")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text(selectedFilter == nil ? 
                 "When you have notifications, they'll appear here" :
                 "No notifications of this type found")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if selectedFilter != nil {
                Button("Show All Notifications") {
                    withAnimation {
                        selectedFilter = nil
                    }
                }
                .foregroundColor(.accentBlues)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    //  Handle Notification Tap
    private func handleNotificationTap(_ notification: AppNotification) {
        // Handle navigation based on notification type
        switch notification.type {
        case .newBidding, .outbid, .auctionWon, .auctionEnded:
            if let propertyId = notification.data?["propertyId"] {
                // Navigate to bidding screen or property detail
                print("Navigate to property: \(propertyId)")
            }
        case .newSelling:
            if let propertyId = notification.data?["propertyId"] {
                // Navigate to property detail
                print("Navigate to sale property: \(propertyId)")
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
        case .general:
            // Handle general notifications
            break
        }
        
        // Close notification view after handling
        dismiss()
    }
}

// Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var typeColor: Color {
        switch notification.type.color {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "yellow": return .yellow
        case "purple": return .purple
        case "gray": return .gray
        default: return .accentBlues
        }
    }
    
    private var priorityIndicator: some View {
        Group {
            if notification.priority == .urgent {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            } else if notification.priority == .high {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(typeColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 16, weight: notification.isRead ? .medium : .semibold))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            priorityIndicator
                            
                            Text(timeAgoString(from: notification.timestamp))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text(notification.body)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Unread indicator
                    if !notification.isRead {
                        HStack {
                            Circle()
                                .fill(Color.accentBlues)
                                .frame(width: 6, height: 6)
                            
                            Text("New")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.accentBlues)
                            
                            Spacer()
                        }
                    }
                }
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .opacity(0.7)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(notification.isRead ? Color.clear : Color.accentBlues.opacity(0.05))
                    .stroke(notification.isRead ? Color.clear : Color.accentBlues.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationView()
        .environmentObject(ThemeManager())
}
