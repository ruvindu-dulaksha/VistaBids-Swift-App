//
//  PlaceBidIntent.swift
//  VistaBids
//
//  Created by Assistant on 2025-09-15.
//

import Foundation
import Intents
import IntentsUI

// MARK: - Place Bid Intent (Using NSUserActivity for free SiriKit)

@available(iOS 13.0, *)
class VistaBidsSiriManager: NSObject {
    
    static let shared = VistaBidsSiriManager()
    
    // Create user activity for placing bids (free SiriKit approach)
    func createPlaceBidActivity(bidAmount: String? = nil) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "com.vistabids.placebid")
        activity.title = "Place Bid on VistaBids"
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        
        if let amount = bidAmount {
            activity.userInfo = ["bidAmount": amount]
            activity.suggestedInvocationPhrase = "Place bid \(amount) on VistaBids"
        } else {
            activity.suggestedInvocationPhrase = "Place bid on VistaBids"
        }
        
        return activity
    }
    
    // Handle user activity when triggered by Siri
    func handleBidActivity(_ userActivity: NSUserActivity) -> String? {
        guard userActivity.activityType == "com.vistabids.placebid" else {
            return nil
        }
        
        if let bidAmount = userActivity.userInfo?["bidAmount"] as? String {
            return bidAmount
        }
        
        return nil
    }
}
