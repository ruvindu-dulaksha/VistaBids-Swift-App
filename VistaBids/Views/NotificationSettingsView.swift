//
//  NotificationSettingsView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-09-13.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationService = NotificationService.shared
    
    @State private var pushNotificationsEnabled = true
    @State private var emailNotificationsEnabled = true
    @State private var smsNotificationsEnabled = false
    
    // Notification type preferences
    @State private var biddingNotifications = true
    @State private var auctionNotifications = true
    @State private var paymentNotifications = true
    @State private var communityNotifications = true
    @State private var marketingNotifications = false
    
    // Quiet hours
    @State private var quietHoursEnabled = false
    @State private var quietStartTime = Date()
    @State private var quietEndTime = Date()
    
    // Notification sound
    @State private var selectedSound = "Default"
    private let availableSounds = ["Default", "Chime", "Bell", "Alert", "Note"]
    
    @State private var showingPermissionAlert = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                // Push Notification Status
                pushNotificationSection
                
                // Notification Types
                notificationTypesSection
                
                // Delivery Methods
                deliveryMethodsSection
                
                // Quiet Hours
                quietHoursSection
                
                // Sound Settings
                soundSettingsSection
                
                // Advanced Settings
                advancedSettingsSection
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive push notifications, please enable them in Settings.")
        }
    }
    
    // MARK: - Push Notification Section
    private var pushNotificationSection: some View {
        Section {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Push Notifications")
                        .font(.headline)
                    
                    Text(pushNotificationsEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $pushNotificationsEnabled)
                    .onChange(of: pushNotificationsEnabled) { _, newValue in
                        handlePushNotificationToggle(newValue)
                    }
            }
            .padding(.vertical, 4)
            
            if !pushNotificationsEnabled {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    
                    Text("You won't receive real-time updates about bids, auctions, and payments.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Notification Status")
        }
    }
    
    // MARK: - Notification Types Section
    private var notificationTypesSection: some View {
        Section {
            NotificationTypeRow(
                icon: "hammer.fill",
                title: "Bidding Activity",
                subtitle: "New bids, outbid alerts",
                isEnabled: $biddingNotifications,
                color: .orange
            )
            
            NotificationTypeRow(
                icon: "clock.fill",
                title: "Auction Updates",
                subtitle: "Auction start, end, and winner announcements",
                isEnabled: $auctionNotifications,
                color: .purple
            )
            
            NotificationTypeRow(
                icon: "creditcard.fill",
                title: "Payment Reminders",
                subtitle: "Payment deadlines and confirmations",
                isEnabled: $paymentNotifications,
                color: .green
            )
            
            NotificationTypeRow(
                icon: "person.3.fill",
                title: "Community Activity",
                subtitle: "Events, messages, and updates",
                isEnabled: $communityNotifications,
                color: .indigo
            )
            
            NotificationTypeRow(
                icon: "megaphone.fill",
                title: "Marketing & Promotions",
                subtitle: "Special offers and new features",
                isEnabled: $marketingNotifications,
                color: .pink
            )
        } header: {
            Text("Notification Types")
        } footer: {
            Text("Choose which types of notifications you want to receive.")
        }
    }
    
    // MARK: - Delivery Methods Section
    private var deliveryMethodsSection: some View {
        Section {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Email Notifications")
                        .font(.subheadline)
                    
                    Text("Daily summaries and important updates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $emailNotificationsEnabled)
            }
            .padding(.vertical, 4)
            
            HStack {
                Image(systemName: "message.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("SMS Notifications")
                        .font(.subheadline)
                    
                    Text("Critical alerts only")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $smsNotificationsEnabled)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Delivery Methods")
        }
    }
    
    // MARK: - Quiet Hours Section
    private var quietHoursSection: some View {
        Section {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.indigo)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quiet Hours")
                        .font(.subheadline)
                    
                    Text("Pause non-urgent notifications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $quietHoursEnabled)
            }
            .padding(.vertical, 4)
            
            if quietHoursEnabled {
                HStack {
                    Text("Start Time")
                    Spacer()
                    DatePicker("", selection: $quietStartTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                HStack {
                    Text("End Time")
                    Spacer()
                    DatePicker("", selection: $quietEndTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        } header: {
            Text("Quiet Hours")
        } footer: {
            if quietHoursEnabled {
                Text("Urgent notifications (like auction endings) will still be delivered during quiet hours.")
            }
        }
    }
    
    // MARK: - Sound Settings Section
    private var soundSettingsSection: some View {
        Section {
            HStack {
                Image(systemName: "speaker.2.fill")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                Text("Notification Sound")
                
                Spacer()
                
                Picker("Sound", selection: $selectedSound) {
                    ForEach(availableSounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.vertical, 4)
        } header: {
            Text("Sound Settings")
        }
    }
    
    // MARK: - Advanced Settings Section
    private var advancedSettingsSection: some View {
        Section {
            Button(action: {
                Task {
                    await testNotification()
                }
            }) {
                HStack {
                    Image(systemName: "bell.and.waves.left.and.right")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Send Test Notification")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(isLoading)
            
            Button(action: clearAllNotifications) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Clear All Notifications")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
            
            NavigationLink(destination: NotificationHistoryView()) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    Text("Notification History")
                    
                    Spacer()
                }
            }
        } header: {
            Text("Advanced")
        }
    }
    
    // MARK: - Helper Methods
    private func loadCurrentSettings() {
        // Load settings from UserDefaults or service
        pushNotificationsEnabled = UserDefaults.standard.bool(forKey: "pushNotificationsEnabled")
        emailNotificationsEnabled = UserDefaults.standard.bool(forKey: "emailNotificationsEnabled")
        smsNotificationsEnabled = UserDefaults.standard.bool(forKey: "smsNotificationsEnabled")
        
        biddingNotifications = UserDefaults.standard.bool(forKey: "biddingNotifications")
        auctionNotifications = UserDefaults.standard.bool(forKey: "auctionNotifications")
        paymentNotifications = UserDefaults.standard.bool(forKey: "paymentNotifications")
        communityNotifications = UserDefaults.standard.bool(forKey: "communityNotifications")
        marketingNotifications = UserDefaults.standard.bool(forKey: "marketingNotifications")
        
        quietHoursEnabled = UserDefaults.standard.bool(forKey: "quietHoursEnabled")
        selectedSound = UserDefaults.standard.string(forKey: "selectedSound") ?? "Default"
        
        // Set default values if first time
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            pushNotificationsEnabled = true
            emailNotificationsEnabled = true
            biddingNotifications = true
            auctionNotifications = true
            paymentNotifications = true
            communityNotifications = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    private func saveSettings() {
        isLoading = true
        
        // Save to UserDefaults
        UserDefaults.standard.set(pushNotificationsEnabled, forKey: "pushNotificationsEnabled")
        UserDefaults.standard.set(emailNotificationsEnabled, forKey: "emailNotificationsEnabled")
        UserDefaults.standard.set(smsNotificationsEnabled, forKey: "smsNotificationsEnabled")
        
        UserDefaults.standard.set(biddingNotifications, forKey: "biddingNotifications")
        UserDefaults.standard.set(auctionNotifications, forKey: "auctionNotifications")
        UserDefaults.standard.set(paymentNotifications, forKey: "paymentNotifications")
        UserDefaults.standard.set(communityNotifications, forKey: "communityNotifications")
        UserDefaults.standard.set(marketingNotifications, forKey: "marketingNotifications")
        
        UserDefaults.standard.set(quietHoursEnabled, forKey: "quietHoursEnabled")
        UserDefaults.standard.set(selectedSound, forKey: "selectedSound")
        
        // Update notification service
        Task {
            await notificationService.updateNotificationPreferences()
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
    
    private func handlePushNotificationToggle(_ enabled: Bool) {
        if enabled {
            requestNotificationPermission()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    pushNotificationsEnabled = false
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func testNotification() async {
        isLoading = true
        
        let testNotification = AppNotification(
            id: UUID().uuidString,
            userId: "current-user",
            title: "Test Notification",
            body: "This is a test notification to verify your settings are working correctly.",
            type: .general,
            data: nil,
            timestamp: Date(),
            isRead: false,
            priority: .medium
        )
        
        await notificationService.sendLocalNotification(testNotification)
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func clearAllNotifications() {
        Task {
            await notificationService.clearAllNotifications()
        }
    }
}

// MARK: - Supporting Views

struct NotificationTypeRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isEnabled: Bool
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
        }
        .padding(.vertical, 4)
    }
}

struct NotificationHistoryView: View {
    var body: some View {
        List {
            // Implementation for notification history
            Text("Notification history will be implemented here")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Notification History")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NotificationSettingsView()
}
