//
//  NotificationManager.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-09-12.
//

import Foundation
import SwiftUI
import UserNotifications
import Firebase
import FirebaseFirestore
import FirebaseAuth

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var showBidWinnerNotification = false
    @Published var winningProperty: AuctionProperty?
    
    private init() {
        requestNotificationPermission()
        setupNotificationCategories()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }
    
    func showWinNotification(for property: AuctionProperty) {
        winningProperty = property
        showBidWinnerNotification = true
    }
    
    func dismissWinNotification() {
        showBidWinnerNotification = false
        winningProperty = nil
    }
    
    // Simulate winning a bid for testing
    func simulateWinningBid(property: AuctionProperty) {
        var winningProperty = property
        winningProperty.winnerId = "current_user_id"
        winningProperty.winnerName = "Current User"
        winningProperty.finalPrice = property.currentBid + 10000 // Add some to current bid
        winningProperty.status = .sold
        winningProperty.paymentStatus = PaymentStatus.pending
        
        showWinNotification(for: winningProperty)
        
        // Schedule local notification
        let content = UNMutableNotificationContent()
        content.title = "🎉 Congratulations!"
        content.body = "You won the auction for \(property.title)!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "auction_win_\(property.id ?? UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Payment Reminder Notifications
    
    func schedulePaymentReminders() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("auctions")
                .whereField("winnerId", isEqualTo: userId)
                .whereField("paymentStatus", isEqualTo: "pending")
                .getDocuments()
            
            for document in snapshot.documents {
                let data = document.data()
                
                guard let auctionEndTime = (data["endTime"] as? Timestamp)?.dateValue(),
                      let propertyTitle = data["propertyTitle"] as? String,
                      let winningBid = data["winningBid"] as? Double else {
                    continue
                }
                
                // Schedule notifications at different intervals
                await schedulePaymentNotification(
                    auctionId: document.documentID,
                    propertyTitle: propertyTitle,
                    amount: winningBid,
                    auctionEndTime: auctionEndTime
                )
            }
        } catch {
            print("Error scheduling payment reminders: \(error)")
        }
    }
    
    private func schedulePaymentNotification(
        auctionId: String,
        propertyTitle: String,
        amount: Double,
        auctionEndTime: Date
    ) async {
        let paymentDeadline = auctionEndTime.addingTimeInterval(24 * 60 * 60) // 24 hours after auction end
        
        // Schedule notification 2 hours before deadline
        let twoHoursBefore = paymentDeadline.addingTimeInterval(-2 * 60 * 60)
        if twoHoursBefore > Date() {
            await scheduleNotification(
                identifier: "payment_reminder_2h_\(auctionId)",
                title: "⏰ Payment Reminder",
                body: "You have 2 hours left to complete payment for \(propertyTitle). Amount: $\(String(format: "%.2f", amount))",
                triggerDate: twoHoursBefore,
                isUrgent: true
            )
        }
        
        // Schedule notification 30 minutes before deadline
        let thirtyMinutesBefore = paymentDeadline.addingTimeInterval(-30 * 60)
        if thirtyMinutesBefore > Date() {
            await scheduleNotification(
                identifier: "payment_reminder_30m_\(auctionId)",
                title: "🚨 URGENT: Payment Due Soon",
                body: "Only 30 minutes left to complete payment for \(propertyTitle)!",
                triggerDate: thirtyMinutesBefore,
                isUrgent: true
            )
        }
        
        // Schedule notification at deadline
        if paymentDeadline > Date() {
            await scheduleNotification(
                identifier: "payment_overdue_\(auctionId)",
                title: "❌ Payment Overdue",
                body: "Payment deadline has passed for \(propertyTitle). Please contact support.",
                triggerDate: paymentDeadline,
                isUrgent: true
            )
        }
    }
    
    private func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        triggerDate: Date,
        isUrgent: Bool = false
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = isUrgent ? .defaultCritical : .default
        content.categoryIdentifier = "PAYMENT_REMINDER"
        
        if isUrgent {
            content.badge = 1
        }
        
        // Create trigger for specific date
        let triggerDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled payment reminder: \(identifier) for \(triggerDate)")
        } catch {
            print("Error scheduling notification \(identifier): \(error)")
        }
    }
    
    func cancelPaymentReminders(for auctionId: String) {
        let identifiers = [
            "payment_reminder_2h_\(auctionId)",
            "payment_reminder_30m_\(auctionId)",
            "payment_overdue_\(auctionId)"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Cancelled payment reminders for auction: \(auctionId)")
    }
    
    // MARK: - Bid Status Notifications
    
    func scheduleAuctionEndNotification(for property: AuctionProperty, endTime: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Auction Ending Soon"
        content.body = "The auction for \(property.title) ends in 10 minutes!"
        content.sound = .default
        content.categoryIdentifier = "AUCTION_ENDING"
        
        let tenMinutesBefore = endTime.addingTimeInterval(-10 * 60)
        if tenMinutesBefore > Date() {
            let triggerDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: tenMinutesBefore
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "auction_ending_\(property.id ?? UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
    
    func setupNotificationCategories() {
        let paymentAction = UNNotificationAction(
            identifier: "PAY_NOW",
            title: "Pay Now",
            options: [.foreground]
        )
        
        let paymentCategory = UNNotificationCategory(
            identifier: "PAYMENT_REMINDER",
            actions: [paymentAction],
            intentIdentifiers: [],
            options: []
        )
        
        let auctionAction = UNNotificationAction(
            identifier: "VIEW_AUCTION",
            title: "View Auction",
            options: [.foreground]
        )
        
        let auctionCategory = UNNotificationCategory(
            identifier: "AUCTION_ENDING",
            actions: [auctionAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([paymentCategory, auctionCategory])
    }
}
