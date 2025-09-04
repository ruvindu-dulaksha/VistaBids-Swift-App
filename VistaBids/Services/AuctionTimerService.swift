//
//  AuctionTimerService.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-08-24.
//

import Foundation
import Combine
import UserNotifications
import SwiftUI

@MainActor
class AuctionTimerService: ObservableObject {
    @Published var activeAuctions: [String: AuctionTimer] = [:]
    @Published var auctionTimeRemaining: [String: TimeInterval] = [:]
    
    private var timers: [String: Timer] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Clean up inactive timers periodically
        Task {
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                Task { @MainActor in
                    self.cleanupExpiredTimers()
                }
            }
        }
    }
    
    deinit {
        Task { @MainActor in
            self.stopAllTimers()
        }
    }
    
    // MARK: - Timer Management
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
        let timeRemaining: TimeInterval
        
        switch auctionTimer.status {
        case .upcoming:
            timeRemaining = auctionTimer.startTime.timeIntervalSince(now)
            if timeRemaining <= 0 {
                // Auction should start
                auctionTimer.status = .active
                activeAuctions[propertyId] = auctionTimer
                scheduleAuctionStartNotification(for: auctionTimer)
            }
            
        case .active:
            timeRemaining = auctionTimer.endTime.timeIntervalSince(now)
            if timeRemaining <= 0 {
                // Auction should end
                auctionTimer.status = .ended
                activeAuctions[propertyId] = auctionTimer
                stopTimer(for: propertyId)
                scheduleAuctionEndNotification(for: auctionTimer)
                return
            }
            
        default:
            timeRemaining = 0
            stopTimer(for: propertyId)
            return
        }
        
        auctionTimeRemaining[propertyId] = max(0, timeRemaining)
        
        // Schedule warning notifications
        scheduleWarningNotifications(for: auctionTimer, timeRemaining: timeRemaining)
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
    
    // MARK: - Time Formatting
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
    
    // MARK: - Notification Scheduling
    private func scheduleAuctionStartNotification(for timer: AuctionTimer) {
        let content = UNMutableNotificationContent()
        content.title = "Auction Started!"
        content.body = "The auction for \(timer.propertyTitle) has begun. Start bidding now!"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "auction_start_\(timer.propertyId)",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleAuctionEndNotification(for timer: AuctionTimer) {
        let content = UNMutableNotificationContent()
        content.title = "Auction Ended"
        content.body = "The auction for \(timer.propertyTitle) has ended. Check the results!"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "auction_end_\(timer.propertyId)",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request)
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
        
        if timeRemaining <= 60 {
            content.title = "⚡ Last Chance!"
            content.body = "Only \(Int(timeRemaining)) seconds left for \(timer.propertyTitle)"
        } else {
            let minutes = Int(timeRemaining / 60)
            content.title = "Auction Ending Soon"
            content.body = "\(minutes) minute\(minutes == 1 ? "" : "s") left for \(timer.propertyTitle)"
        }
        
        let request = UNNotificationRequest(
            identifier: "auction_warning_\(timer.propertyId)_\(Int(timeRemaining))",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Auction Timer Model
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
