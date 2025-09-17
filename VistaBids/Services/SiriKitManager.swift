//
//  SiriKitManager.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-15.
//

import Foundation
import Intents
import IntentsUI

@available(iOS 13.0, *)
class SiriKitManager: NSObject, ObservableObject {
    
    static let shared = SiriKitManager()
    
    override init() {
        super.init()
        setupSiriShortcuts()
    }
    
   
    
    func setupSiriShortcuts() {
        print("SiriKit: Setting up Siri shortcuts using NSUserActivity")
        createPlaceBidShortcut()
    }
    
   
    
    func createPlaceBidShortcut() {
        print(" SiriKit: Creating place bid shortcut")
        
        let activity = VistaBidsSiriManager.shared.createPlaceBidActivity()
        activity.becomeCurrent()
        
        print("SiriKit: Place bid shortcut created successfully")
    }
    
    // MARK: - Quick Bid Methods
    
    func createQuickBidShortcut(amount: String, propertyTitle: String) {
        print("🎤 SiriKit: Creating quick bid shortcut for \(amount)")
        
        let activity = VistaBidsSiriManager.shared.createPlaceBidActivity(bidAmount: amount)
        activity.becomeCurrent()
        
        print(" SiriKit: Quick bid shortcut created for \(amount)")
    }
    
    
    
    func createBiddingUserActivity(property: AuctionProperty) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "com.vistabids.bidding")
        activity.title = "Bid on \(property.title)"
        activity.userInfo = [
            "propertyId": property.id ?? "",
            "propertyTitle": property.title,
            "currentBid": property.currentBid
        ]
        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "Place bid on \(property.title)"
        
        return activity
    }
    
    //  Voice Command Handling
    
    func handleVoiceCommand(_ command: String) -> String? {
        print("🎤 SiriKit: Processing voice command: \(command)")
        
        let lowercaseCommand = command.lowercased()
        
        // Extract bid amount from voice command
        let patterns = [
            #"place bid (\d+(?:\.\d+)?)\s*(?:million|m)"#,
            #"place bid (\d+(?:\.\d+)?)\s*(?:thousand|k)"#,
            #"place bid (\d+(?:\.\d+)?)"#,
            #"bid (\d+(?:\.\d+)?)\s*(?:million|m)"#,
            #"bid (\d+(?:\.\d+)?)\s*(?:thousand|k)"#,
            #"bid (\d+(?:\.\d+)?)"#
        ]
        
        for (index, pattern) in patterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: lowercaseCommand.utf16.count)
                if let match = regex.firstMatch(in: lowercaseCommand, options: [], range: range) {
                    let amountRange = Range(match.range(at: 1), in: lowercaseCommand)!
                    let amountString = String(lowercaseCommand[amountRange])
                    
                    if let amount = Double(amountString) {
                        switch index {
                        case 0, 3: // Million
                            return "\(Int(amount))M"
                        case 1, 4: // Thousand
                            return "\(Int(amount))K"
                        case 2, 5: // Regular number
                            return String(Int(amount))
                        default:
                            return String(Int(amount))
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // Handle User Activity (Called when Siri triggers the activity)
    
    func handleUserActivity(_ userActivity: NSUserActivity) -> String? {
        return VistaBidsSiriManager.shared.handleBidActivity(userActivity)
    }
}
