//
//  PlaceBidIntentHandler.swift
//  VistaBidsIntentExtension
//
//  Created by Ruvindu Dulaksha on 2025-09-15.
//

import Foundation
import Intents
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@available(iOS 13.0, *)
class PlaceBidIntentHandler: NSObject, PlaceBidIntentHandling {
    
    private let db = Firestore.firestore()
    
    override init() {
        super.init()
        // Initialize Firebase if not already initialized
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    //  Intent Handling
    
    func handle(intent: PlaceBidIntent, completion: @escaping (PlaceBidIntentResponse) -> Void) {
        print("🎤 SiriKit: Handling place bid intent")
        
        guard let bidAmountString = intent.bidAmount,
              let bidAmount = Double(bidAmountString.replacingOccurrences(of: "M", with: "000000").replacingOccurrences(of: "K", with: "000")) else {
            print("❌ SiriKit: Invalid bid amount")
            completion(PlaceBidIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        print("💰 SiriKit: Processing bid amount: \(bidAmount)")
        
        // Check if user is authenticated
        guard Auth.auth().currentUser != nil else {
            print("❌ SiriKit: User not authenticated")
            let response = PlaceBidIntentResponse(code: .failure, userActivity: nil)
            response.failureReason = "Please sign in to place bids"
            completion(response)
            return
        }
        
        // Get current active auction
        getCurrentActiveAuction { [weak self] property in
            guard let self = self, let property = property else {
                print("❌ SiriKit: No active auction found")
                let response = PlaceBidIntentResponse(code: .failure, userActivity: nil)
                response.failureReason = "No active auction found"
                completion(response)
                return
            }
            
            print("🏠 SiriKit: Found active auction: \(property.title)")
            
            // Validate bid amount
            if bidAmount <= property.currentBid {
                print("❌ SiriKit: Bid too low")
                let response = PlaceBidIntentResponse(code: .failure, userActivity: nil)
                response.failureReason = "Bid must be higher than current bid of $\(Int(property.currentBid))"
                completion(response)
                return
            }
            
            // Place the bid
            self.placeBid(propertyId: property.id ?? "", amount: bidAmount, property: property) { success in
                if success {
                    print("✅ SiriKit: Bid placed successfully")
                    let response = PlaceBidIntentResponse(code: .success, userActivity: nil)
                    response.bidAmount = bidAmountString
                    response.propertyTitle = property.title
                    completion(response)
                } else {
                    print("❌ SiriKit: Failed to place bid")
                    let response = PlaceBidIntentResponse(code: .failure, userActivity: nil)
                    response.failureReason = "Failed to place bid. Please try again."
                    completion(response)
                }
            }
        }
    }
    
    func confirm(intent: PlaceBidIntent, completion: @escaping (PlaceBidIntentResponse) -> Void) {
        print("🎤 SiriKit: Confirming place bid intent")
        completion(PlaceBidIntentResponse(code: .ready, userActivity: nil))
    }
    
    func resolveBidAmount(for intent: PlaceBidIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let bidAmount = intent.bidAmount else {
            completion(INStringResolutionResult.needsValue())
            return
        }
        
        // Validate bid amount format
        let cleanAmount = bidAmount.replacingOccurrences(of: "M", with: "000000").replacingOccurrences(of: "K", with: "000")
        if Double(cleanAmount) != nil {
            completion(INStringResolutionResult.success(with: bidAmount))
        } else {
            completion(INStringResolutionResult.unsupported())
        }
    }
    
    //  Helper Methods
    
    private func getCurrentActiveAuction(completion: @escaping (AuctionProperty?) -> Void) {
        db.collection("auction_properties")
            .whereField("status", isEqualTo: "active")
            .order(by: "auctionStartTime", descending: false)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ SiriKit: Error fetching auction: \(error)")
                    completion(nil)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("❌ SiriKit: No active auctions found")
                    completion(nil)
                    return
                }
                
                do {
                    let property = try documents[0].data(as: AuctionProperty.self)
                    completion(property)
                } catch {
                    print("❌ SiriKit: Error decoding property: \(error)")
                    completion(nil)
                }
            }
    }
    
    private func placeBid(propertyId: String, amount: Double, property: AuctionProperty, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let bidData: [String: Any] = [
            "bidderId": currentUser.uid,
            "bidderName": currentUser.displayName ?? "Anonymous Bidder",
            "amount": amount,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        let propertyData: [String: Any] = [
            "currentBid": amount,
            "highestBidderId": currentUser.uid,
            "highestBidderName": currentUser.displayName ?? "Anonymous Bidder",
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        let batch = db.batch()
        
        // Add to bid history
        let bidRef = db.collection("auction_properties")
            .document(propertyId)
            .collection("bids")
            .document()
        batch.setData(bidData, forDocument: bidRef)
        
        // Update property
        let propertyRef = db.collection("auction_properties").document(propertyId)
        batch.updateData(propertyData, forDocument: propertyRef)
        
        batch.commit { error in
            if let error = error {
                print("❌ SiriKit: Error placing bid: \(error)")
                completion(false)
            } else {
                print("✅ SiriKit: Bid placed successfully")
                completion(true)
            }
        }
    }
}

// AuctionProperty Model (Simplified for Intent Extension)

struct AuctionProperty: Codable {
    let id: String?
    let title: String
    let currentBid: Double
    let status: String
}
