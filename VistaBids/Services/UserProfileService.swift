//
//  UserProfileService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-12.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserProfileService: ObservableObject {
    static let shared = UserProfileService()
    
    @Published var userProfile: UserProfile?
    @Published var purchaseHistory: [UserPurchaseHistory] = []
    @Published var activities: [UserActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let currentUserId = "current_user_id" // In real app, get from Auth.auth().currentUser?.uid
    
    private init() {}
    
    func addPurchaseHistory(property: AuctionProperty) {
        let purchase = UserPurchaseHistory(
            id: nil,
            userId: currentUserId,
            propertyId: property.id ?? "",
            propertyTitle: property.title,
            propertyImages: property.images,
            purchasePrice: property.finalPrice ?? property.currentBid,
            purchaseDate: Date(),
            transactionId: generateTransactionID(),
            paymentStatus: .completed,
            deliveryStatus: .processing,
            propertyAddress: property.address,
            propertyFeatures: property.features
        )
        
        let activity = UserActivity(
            id: nil,
            userId: currentUserId,
            type: .purchase,
            title: "Property Purchased",
            description: "Successfully purchased \(property.title)",
            propertyId: property.id,
            propertyTitle: property.title,
            amount: property.finalPrice ?? property.currentBid,
            timestamp: Date(),
            status: .completed
        )
        
        // Add to local arrays first for immediate UI update
        purchaseHistory.insert(purchase, at: 0)
        activities.insert(activity, at: 0)
        
        // Save to Firestore
        Task {
            await savePurchaseToFirestore(purchase)
            await saveActivityToFirestore(activity)
            await updateUserStats(property: property)
        }
    }
    
    func loadUserProfile() async {
        isLoading = true
        
        do {
            // Load user profile
            let profileDoc = try await db.collection("users").document(currentUserId).getDocument()
            if let data = profileDoc.data() {
                userProfile = try Firestore.Decoder().decode(UserProfile.self, from: data)
            }
            
            // Load purchase history
            let purchaseQuery = db.collection("user_purchases")
                .whereField("userId", isEqualTo: currentUserId)
                .order(by: "purchaseDate", descending: true)
            
            let purchaseSnapshot = try await purchaseQuery.getDocuments()
            purchaseHistory = try purchaseSnapshot.documents.compactMap { doc in
                try Firestore.Decoder().decode(UserPurchaseHistory.self, from: doc.data())
            }
            
            // Load activities
            let activityQuery = db.collection("user_activities")
                .whereField("userId", isEqualTo: currentUserId)
                .order(by: "timestamp", descending: true)
                .limit(to: 50)
            
            let activitySnapshot = try await activityQuery.getDocuments()
            activities = try activitySnapshot.documents.compactMap { doc in
                try Firestore.Decoder().decode(UserActivity.self, from: doc.data())
            }
            
            isLoading = false
            
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func savePurchaseToFirestore(_ purchase: UserPurchaseHistory) async {
        do {
            try await db.collection("user_purchases").addDocument(from: purchase)
        } catch {
            print("Failed to save purchase: \(error.localizedDescription)")
        }
    }
    
    private func saveActivityToFirestore(_ activity: UserActivity) async {
        do {
            try await db.collection("user_activities").addDocument(from: activity)
        } catch {
            print("Failed to save activity: \(error.localizedDescription)")
        }
    }
    
    private func updateUserStats(property: AuctionProperty) async {
        do {
            let userRef = db.collection("users").document(currentUserId)
            
            // Update user statistics
            try await userRef.updateData([
                "totalPurchases": FieldValue.increment(Int64(1)),
                "totalSpent": FieldValue.increment(property.finalPrice ?? property.currentBid),
                "lastActivity": Timestamp(),
                "updatedAt": Timestamp()
            ])
            
        } catch {
            print("Failed to update user stats: \(error.localizedDescription)")
        }
    }
    
    private func generateTransactionID() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "VB\(timestamp)"
    }
}

// MARK: - User Profile Model
struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let name: String
    let email: String
    let profileImageURL: String?
    let joinedDate: Date
    var totalPurchases: Int
    var totalSpent: Double
    var lastActivity: Date
    let createdAt: Date
    var updatedAt: Date
    
    // Bidding statistics
    var totalBids: Int
    var wonAuctions: Int
    var watchlistCount: Int
    
    // Preferences
    var preferredCategories: [PropertyCategory]
    var maxBudget: Double?
    var notificationsEnabled: Bool
}

// MARK: - User Activity Model
struct UserActivity: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let type: ActivityType
    let title: String
    let description: String
    let propertyId: String?
    let propertyTitle: String?
    let amount: Double?
    let timestamp: Date
    let status: ActivityStatus
    
    enum ActivityType: String, Codable {
        case bid = "bid"
        case purchase = "purchase"
        case watchlist = "watchlist"
        case payment = "payment"
        case signup = "signup"
    }
    
    enum ActivityStatus: String, Codable {
        case pending = "pending"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
    }
    
    var icon: String {
        switch type {
        case .bid:
            return "hand.raised.fill"
        case .purchase:
            return "house.fill"
        case .watchlist:
            return "heart.fill"
        case .payment:
            return "creditcard.fill"
        case .signup:
            return "person.badge.plus.fill"
        }
    }
    
    var color: String {
        switch status {
        case .pending:
            return "orange"
        case .completed:
            return "green"
        case .failed:
            return "red"
        case .cancelled:
            return "gray"
        }
    }
}
