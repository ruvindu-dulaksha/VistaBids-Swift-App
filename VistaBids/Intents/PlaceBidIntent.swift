//
//  PlaceBidIntent.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-15.
//

import Foundation
import Intents
import IntentsUI

// Place Bid Intent (Using NSUserActivity for free SiriKit)

@available(iOS 13.0, *)
class VistaBidsSiriManager: NSObject, ObservableObject {
    
    static let shared = VistaBidsSiriManager()
    
    // User Activity Constants
    
    private let placeBidActivityType = "com.vistabids.placeBid"
    private let viewAuctionsActivityType = "com.vistabids.viewAuctions"
    private let checkBidsActivityType = "com.vistabids.checkBids"
    
    override init() {
        super.init()
        setupSiriDonations()
    }
    
    // Setup Methods
    
    func setupSiriDonations() {
        print("🎤 VistaBidsSiri: Setting up Siri donations")
        
        // Donate common activities to Siri
        donateViewAuctionsActivity()
        donateCheckBidsActivity()
    }
    
    // Place Bid Activity
    
    func createPlaceBidActivity(bidAmount: String? = nil) -> NSUserActivity {
        let activity = NSUserActivity(activityType: placeBidActivityType)
        activity.title = "Place Bid"
        activity.suggestedInvocationPhrase = "Place a bid on VistaBids"
        
        if let amount = bidAmount {
            activity.title = "Place Bid of $\(amount)"
            activity.suggestedInvocationPhrase = "Place a \(amount) dollar bid"
            activity.userInfo = ["bidAmount": amount]
        }
        
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = "place-bid-\(bidAmount ?? "default")"
        
        print("VistaBidsSiri: Created place bid activity with amount: \(bidAmount ?? "none")")
        return activity
    }
    
    func donatePlaceBidActivity(amount: String, propertyTitle: String) {
        let activity = createPlaceBidActivity(bidAmount: amount)
        activity.title = "Place $\(amount) bid on \(propertyTitle)"
        activity.userInfo = [
            "bidAmount": amount,
            "propertyTitle": propertyTitle
        ]
        
        // Donate to Siri
        activity.becomeCurrent()
        
        print("VistaBidsSiri: Donated place bid activity for \(propertyTitle)")
    }
    
    // View Auctions Activity
    
    func createViewAuctionsActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: viewAuctionsActivityType)
        activity.title = "View Live Auctions"
        activity.suggestedInvocationPhrase = "Show me live auctions on VistaBids"
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = "view-auctions"
        
        return activity
    }
    
    func donateViewAuctionsActivity() {
        let activity = createViewAuctionsActivity()
        activity.becomeCurrent()
        
        print(" VistaBidsSiri: Donated view auctions activity")
    }
    
    // Check Bids Activity
    
    func createCheckBidsActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: checkBidsActivityType)
        activity.title = "Check My Bids"
        activity.suggestedInvocationPhrase = "Check my bids on VistaBids"
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = "check-bids"
        
        return activity
    }
    
    func donateCheckBidsActivity() {
        let activity = createCheckBidsActivity()
        activity.becomeCurrent()
        
        print(" VistaBidsSiri: Donated check bids activity")
    }
    
    // Activity Handling
    
    func handleBidActivity(_ activity: NSUserActivity) -> String? {
        print("🎤 VistaBidsSiri: Handling bid activity")
        
        // Extract property information from activity
        if let userInfo = activity.userInfo {
            if let propertyId = userInfo["propertyId"] as? String,
               let propertyTitle = userInfo["propertyTitle"] as? String {
                print("🎤 VistaBidsSiri: Bid activity for property: \(propertyTitle)")
                
                // Notify the app to navigate to property and show bidding
                NotificationCenter.default.post(
                    name: .siriBidOnProperty,
                    object: nil,
                    userInfo: [
                        "propertyId": propertyId,
                        "propertyTitle": propertyTitle
                    ]
                )
                
                return "Opening bidding for \(propertyTitle)"
            }
        }
        
        return nil
    }
    
    func handleUserActivity(_ activity: NSUserActivity) -> Bool {
        guard activity.activityType != nil else { return false }
        
        print("🎤 VistaBidsSiri: Handling user activity: \(activity.activityType ?? "unknown")")
        
        switch activity.activityType {
        case placeBidActivityType:
            return handlePlaceBidActivity(activity)
        case viewAuctionsActivityType:
            return handleViewAuctionsActivity(activity)
        case checkBidsActivityType:
            return handleCheckBidsActivity(activity)
        default:
            print("❌ VistaBidsSiri: Unknown activity type: \(activity.activityType ?? "nil")")
            return false
        }
    }
    
    private func handlePlaceBidActivity(_ activity: NSUserActivity) -> Bool {
        print("🎤 VistaBidsSiri: Handling place bid activity")
        
        // Extract bid amount if available
        if let userInfo = activity.userInfo,
           let bidAmount = userInfo["bidAmount"] as? String {
            print("🎤 VistaBidsSiri: Place bid with amount: \(bidAmount)")
            
            // Notify the app to show bidding screen with pre-filled amount
            NotificationCenter.default.post(
                name: .siriPlaceBid,
                object: nil,
                userInfo: ["bidAmount": bidAmount]
            )
        } else {
            // Show general bidding screen
            NotificationCenter.default.post(
                name: .siriPlaceBid,
                object: nil
            )
        }
        
        return true
    }
    
    private func handleViewAuctionsActivity(_ activity: NSUserActivity) -> Bool {
        print("🎤 VistaBidsSiri: Handling view auctions activity")
        
        // Navigate to auctions tab
        NotificationCenter.default.post(name: .siriViewAuctions, object: nil)
        
        return true
    }
    
    private func handleCheckBidsActivity(_ activity: NSUserActivity) -> Bool {
        print("🎤 VistaBidsSiri: Handling check bids activity")
        
        // Navigate to user's bid history
        NotificationCenter.default.post(name: .siriCheckBids, object: nil)
        
        return true
    }
}

// Notification Names

extension Notification.Name {
    static let siriPlaceBid = Notification.Name("siriPlaceBid")
    static let siriViewAuctions = Notification.Name("siriViewAuctions")
    static let siriCheckBids = Notification.Name("siriCheckBids")
    static let siriBidOnProperty = Notification.Name("siriBidOnProperty")
}
