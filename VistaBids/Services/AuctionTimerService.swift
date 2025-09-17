//
//  AuctionTimerService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on  2025-08-24.
//

import Foundation
import Combine
import UserNotifications
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AuctionTimerService: ObservableObject {
    @Published var activeAuctions: [String: AuctionTimer] = [:]
    @Published var auctionTimeRemaining: [String: TimeInterval] = [:]
    
    private var timers: [String: Timer] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Request notification permissions
        requestNotificationPermissions()
        
        // Clean up inactive timers periodically
        Task {
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                Task { @MainActor in
                    self.cleanupExpiredTimers()
                }
            }
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
            } else {
                print("❌ Notification permissions denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    deinit {
        Task { @MainActor in
            self.stopAllTimers()
        }
    }
    
    // Timer Management
    func startAuctionTimer(for property: AuctionProperty) {
        let propertyId = property.id ?? ""
        
        // Stop existing timer if any
        stopTimer(for: propertyId)
        
        let auctionTimer = AuctionTimer(
            propertyId: propertyId,
            propertyTitle: property.title,
            startTime: property.auctionStartTime,
            endTime: property.auctionEndTime,
            duration: property.auctionDuration,
            status: property.status
        )
        
        activeAuctions[propertyId] = auctionTimer
        
        // Create and start timer
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateAuctionTimer(propertyId: propertyId)
        }
        
        timers[propertyId] = timer
        
        // Initial update
        updateAuctionTimer(propertyId: propertyId)
    }
    
    private func updateAuctionTimer(propertyId: String) {
        guard var auctionTimer = activeAuctions[propertyId] else { return }
        
        let now = Date()
        var timeRemaining: TimeInterval
        var statusChanged = false
        
        switch auctionTimer.status {
        case .upcoming:
            timeRemaining = auctionTimer.startTime.timeIntervalSince(now)
            
            // Schedule 15-minute warning before auction starts
            if timeRemaining > 0 && timeRemaining <= 900 && timeRemaining > 870 { // Between 14.5-15 minutes
                schedulePreAuctionWarning(for: auctionTimer, timeRemaining: timeRemaining)
            }
            
            if timeRemaining <= 0 {
                // Auction should start - transition to active
                auctionTimer.status = .active
                activeAuctions[propertyId] = auctionTimer
                statusChanged = true
                print("🟢 Auction started: \(auctionTimer.propertyTitle)")
                scheduleAuctionStartNotification(for: auctionTimer)
                
                // Recalculate time remaining for active auction
                timeRemaining = auctionTimer.endTime.timeIntervalSince(now)
            }
            
        case .active:
            timeRemaining = auctionTimer.endTime.timeIntervalSince(now)
            if timeRemaining <= 0 {
                // Auction should end - transition to ended
                auctionTimer.status = .ended
                activeAuctions[propertyId] = auctionTimer
                statusChanged = true
                print("🔴 Auction ended: \(auctionTimer.propertyTitle)")
                scheduleAuctionEndNotification(for: auctionTimer)
                
                // Announce winner asynchronously
                Task {
                    await announceWinnerIfAvailable(for: propertyId)
                }
                
                // Stop the timer completely
                stopTimer(for: propertyId)
                return
            }
            
        default:
            // For ended, sold, cancelled - stop the timer
            stopTimer(for: propertyId)
            return
        }
        
        // Always use max(0, timeRemaining) to prevent negative values
        let displayTimeRemaining = max(0, timeRemaining)
        auctionTimeRemaining[propertyId] = displayTimeRemaining
        
        // Only schedule warning notifications for active auctions with time remaining
        if auctionTimer.status == .active && displayTimeRemaining > 0 {
            scheduleWarningNotifications(for: auctionTimer, timeRemaining: displayTimeRemaining)
        }
        
        // Debug logging
        if statusChanged {
            print("📊 Timer update: \(auctionTimer.propertyTitle) - Status: \(auctionTimer.status), Time: \(formatTimeRemaining(displayTimeRemaining))")
        }
    }
    
    func stopTimer(for propertyId: String) {
        timers[propertyId]?.invalidate()
        timers.removeValue(forKey: propertyId)
        activeAuctions.removeValue(forKey: propertyId)
        auctionTimeRemaining.removeValue(forKey: propertyId)
    }
    
    func stopAllTimers() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        activeAuctions.removeAll()
        auctionTimeRemaining.removeAll()
    }
    
    private func cleanupExpiredTimers() {
        let expiredPropertyIds = activeAuctions.compactMap { (propertyId, timer) in
            timer.status == .ended || timer.status == .sold ? propertyId : nil
        }
        
        expiredPropertyIds.forEach { propertyId in
            stopTimer(for: propertyId)
        }
    }
    
    //  Time Formatting
    func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "Ended"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    func getTimeRemainingText(for propertyId: String) -> String {
        guard let timeRemaining = auctionTimeRemaining[propertyId],
              let auctionTimer = activeAuctions[propertyId] else {
            return "Loading..."
        }
        
        switch auctionTimer.status {
        case .upcoming:
            return "Starts in \(formatTimeRemaining(timeRemaining))"
        case .active:
            if timeRemaining > 300 { // More than 5 minutes
                return "Ends in \(formatTimeRemaining(timeRemaining))"
            } else {
                return "⚡ \(formatTimeRemaining(timeRemaining)) remaining"
            }
        case .ended:
            return "Auction Ended"
        default:
            return "Not Available"
        }
    }
    
    //  Notification Scheduling
    private func scheduleAuctionStartNotification(for timer: AuctionTimer) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Auction Started!"
        content.body = "The auction for \(timer.propertyTitle) has begun. Start bidding now!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "AUCTION_START"
        
        let request = UNNotificationRequest(
            identifier: "auction_start_\(timer.propertyId)",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule auction start notification: \(error)")
            } else {
                print("✅ Scheduled auction start notification for: \(timer.propertyTitle)")
            }
        }
    }
    
    private func scheduleAuctionEndNotification(for timer: AuctionTimer) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Auction Ended"
        content.body = "The auction for \(timer.propertyTitle) has ended. Check the results!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "AUCTION_END"
        
        let request = UNNotificationRequest(
            identifier: "auction_end_\(timer.propertyId)",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule auction end notification: \(error)")
            } else {
                print("✅ Scheduled auction end notification for: \(timer.propertyTitle)")
            }
        }
    }
    
    private func scheduleWarningNotifications(for timer: AuctionTimer, timeRemaining: TimeInterval) {
        // Only schedule for active auctions
        guard timer.status == .active else { return }
        
        let warningTimes: [TimeInterval] = [300, 60, 30, 10] // 5 min, 1 min, 30 sec, 10 sec
        
        for warningTime in warningTimes {
            if abs(timeRemaining - warningTime) < 1.0 { // Within 1 second of warning time
                scheduleWarningNotification(for: timer, timeRemaining: warningTime)
            }
        }
    }
    
    private func scheduleWarningNotification(for timer: AuctionTimer, timeRemaining: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "AUCTION_WARNING"
        
        if timeRemaining <= 60 {
            content.title = "⚡ Last Chance!"
            content.body = "Only \(Int(timeRemaining)) seconds left for \(timer.propertyTitle)!"
            content.badge = 1
        } else {
            let minutes = Int(timeRemaining / 60)
            content.title = "⏰ Auction Ending Soon"
            content.body = "\(minutes) minute\(minutes == 1 ? "" : "s") left for \(timer.propertyTitle)"
        }
        
        let request = UNNotificationRequest(
            identifier: "auction_warning_\(timer.propertyId)_\(Int(timeRemaining))",
            content: content,
            trigger: nil 
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule warning notification: \(error)")
            } else {
                print("⚠️ Scheduled warning notification: \(Int(timeRemaining))s remaining for \(timer.propertyTitle)")
            }
        }
    }
    
    private func schedulePreAuctionWarning(for timer: AuctionTimer, timeRemaining: TimeInterval) {
        let minutes = Int(timeRemaining / 60)
        
        let content = UNMutableNotificationContent()
        content.title = "📅 Auction Starting Soon"
        content.body = "The auction for \(timer.propertyTitle) starts in \(minutes) minutes. Get ready to bid!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "AUCTION_UPCOMING"
        
        let request = UNNotificationRequest(
            identifier: "auction_upcoming_\(timer.propertyId)_15min",
            content: content,
            trigger: nil 
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule pre-auction warning: \(error)")
            } else {
                print("📅 Scheduled 15-minute warning for: \(timer.propertyTitle)")
            }
        }
    }
    
    private func scheduleWinnerNotification(for timer: AuctionTimer, winnerName: String, winningBid: Double) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Auction Complete!"
        content.body = "The winner of \(timer.propertyTitle) is \(winnerName) with a bid of $\(String(format: "%.2f", winningBid))"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "AUCTION_WINNER"
        
        let request = UNNotificationRequest(
            identifier: "auction_winner_\(timer.propertyId)",
            content: content,
            trigger: nil 
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule winner notification: \(error)")
            } else {
                print("🎉 Scheduled winner notification for: \(timer.propertyTitle)")
            }
        }
    }
    
    // Method to trigger winner notification when auction ends
    func announceAuctionWinner(propertyId: String, winnerName: String, winningBid: Double) {
        guard let timer = activeAuctions[propertyId] else { return }
        scheduleWinnerNotification(for: timer, winnerName: winnerName, winningBid: winningBid)
    }
    
    private func announceWinnerIfAvailable(for propertyId: String) async {
        do {
            let db = Firestore.firestore()
            let propertySnapshot = try await db.collection("auction_properties").document(propertyId).getDocument()
            
            guard let propertyData = propertySnapshot.data(),
                  let propertyTitle = propertyData["title"] as? String,
                  let highestBidderName = propertyData["highestBidderName"] as? String,
                  let highestBidderId = propertyData["highestBidderId"] as? String,
                  let currentBid = propertyData["currentBid"] as? Double else {
                print("❌ Could not get winner information for property \(propertyId)")
                return
            }
            
            // Create the timer object for notification
            if let timer = activeAuctions[propertyId] {
                scheduleWinnerNotification(for: timer, winnerName: highestBidderName, winningBid: currentBid)
            } else {
                // Create a temporary timer object if not found
                guard let startTime = propertyData["auctionStartTime"] as? Timestamp,
                      let endTime = propertyData["auctionEndTime"] as? Timestamp else { return }
                
                let tempTimer = AuctionTimer(
                    propertyId: propertyId,
                    propertyTitle: propertyTitle,
                    startTime: startTime.dateValue(),
                    endTime: endTime.dateValue(),
                    duration: .oneHour, // Default
                    status: .ended
                )
                scheduleWinnerNotification(for: tempTimer, winnerName: highestBidderName, winningBid: currentBid)
            }
            
            // Check if current user is the winner and trigger payment alert
            await checkAndTriggerPaymentAlert(propertyId: propertyId, winnerId: highestBidderId, propertyData: propertyData)
            
        } catch {
            print("❌ Error announcing winner for property \(propertyId): \(error)")
        }
    }
    
    /// Check if current user won and trigger payment alert
    private func checkAndTriggerPaymentAlert(propertyId: String, winnerId: String, propertyData: [String: Any]) async {
        // Get current user ID
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Check if current user is the winner
        if currentUserId == winnerId {
            print("🎉 Current user won the auction! Triggering payment alert...")
            
            // Create auction property object for payment view
            await MainActor.run {
                triggerWinnerPaymentAlert(propertyId: propertyId, propertyData: propertyData)
            }
        }
    }
    
    /// Trigger payment alert for auction winner
    @MainActor
    private func triggerWinnerPaymentAlert(propertyId: String, propertyData: [String: Any]) {
        // Create a winning notification that will trigger the payment view
        NotificationCenter.default.post(
            name: NSNotification.Name("AuctionWonPaymentRequired"),
            object: nil,
            userInfo: [
                "propertyId": propertyId,
                "propertyData": propertyData
            ]
        )
        
        print("🎯 Payment alert triggered for property: \(propertyId)")
    }
}

// Auction Timer Model
struct AuctionTimer {
    let propertyId: String
    let propertyTitle: String
    let startTime: Date
    let endTime: Date
    let duration: AuctionDuration
    var status: AuctionStatus
    
    var totalDuration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var progress: Double {
        let now = Date()
        let elapsed = now.timeIntervalSince(startTime)
        return min(max(elapsed / totalDuration, 0), 1)
    }
}
