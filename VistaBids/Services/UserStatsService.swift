//
//  UserStatsService.swift
//  VistaBids
//
//  Created by Assistant on 2025-08-21.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

struct UserStats {
    let propertiesSold: Int
    let activeBids: Int
    let watchlistItems: Int
    let totalEarnings: Double
    let successfulTransactions: Int
    let favoriteProperties: Int
}

@MainActor
class UserStatsService: ObservableObject {
    static let shared = UserStatsService()
    
    @Published var userStats = UserStats(
        propertiesSold: 0,
        activeBids: 0,
        watchlistItems: 0,
        totalEarnings: 0.0,
        successfulTransactions: 0,
        favoriteProperties: 0
    )
    
    @Published var myProperties: [SaleProperty] = []
    @Published var favoriteProperties: [SaleProperty] = []
    @Published var transactionHistory: [TransactionRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadUserStats()
    }
    
    // MARK: - User Stats Loading
    func loadUserStats() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user for stats")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            await fetchAllUserData(userId: userId)
        }
    }
    
    private func fetchAllUserData(userId: String) async {
        async let propertiesSold = fetchPropertiesSold(userId: userId)
        async let activeBids = fetchActiveBids(userId: userId)
        async let watchlistItems = fetchWatchlistItems(userId: userId)
        async let favoriteProperties = fetchFavoriteProperties(userId: userId)
        async let transactionHistory = fetchTransactionHistory(userId: userId)
        async let myProperties = fetchMyProperties(userId: userId)
        
        do {
            let results = try await (
                propertiesSold: propertiesSold,
                activeBids: activeBids,
                watchlistItems: watchlistItems,
                favoriteProperties: favoriteProperties,
                transactionHistory: transactionHistory,
                myProperties: myProperties
            )
            
            await MainActor.run {
                self.userStats = UserStats(
                    propertiesSold: results.propertiesSold,
                    activeBids: results.activeBids,
                    watchlistItems: results.watchlistItems,
                    totalEarnings: results.transactionHistory.reduce(0) { $0 + $1.amount },
                    successfulTransactions: results.transactionHistory.count,
                    favoriteProperties: results.favoriteProperties.count
                )
                
                self.myProperties = results.myProperties
                self.favoriteProperties = results.favoriteProperties
                self.transactionHistory = results.transactionHistory
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load user data: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Error loading user stats: \(error)")
            }
        }
    }
    
    // MARK: - Individual Data Fetchers
    private func fetchPropertiesSold(userId: String) async throws -> Int {
        let snapshot = try await db.collection("saleProperties")
            .whereField("seller.id", isEqualTo: userId)
            .whereField("status", isEqualTo: "sold")
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    private func fetchActiveBids(userId: String) async throws -> Int {
        let snapshot = try await db.collection("bids")
            .whereField("bidderId", isEqualTo: userId)
            .whereField("status", isEqualTo: "active")
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    private func fetchWatchlistItems(userId: String) async throws -> Int {
        let snapshot = try await db.collection("watchlist")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    private func fetchFavoriteProperties(userId: String) async throws -> [SaleProperty] {
        // Get user's favorite property IDs
        let favoritesSnapshot = try await db.collection("favorites")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let favoriteIds = favoritesSnapshot.documents.compactMap { document in
            document.data()["propertyId"] as? String
        }
        
        guard !favoriteIds.isEmpty else { return [] }
        
        // Fetch the actual properties
        let propertiesSnapshot = try await db.collection("saleProperties")
            .whereField("id", in: favoriteIds)
            .getDocuments()
        
        return propertiesSnapshot.documents.compactMap { document in
            try? document.data(as: SaleProperty.self)
        }
    }
    
    private func fetchTransactionHistory(userId: String) async throws -> [TransactionRecord] {
        let snapshot = try await db.collection("transactions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: TransactionRecord.self)
        }
    }
    
    private func fetchMyProperties(userId: String) async throws -> [SaleProperty] {
        let snapshot = try await db.collection("saleProperties")
            .whereField("seller.id", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: SaleProperty.self)
        }
    }
    
    // MARK: - User Actions
    func addToFavorites(propertyId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let favoriteData: [String: Any] = [
                "userId": userId,
                "propertyId": propertyId,
                "addedAt": Timestamp(date: Date())
            ]
            
            try await db.collection("favorites").addDocument(data: favoriteData)
            
            // Refresh stats
            loadUserStats()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to add to favorites: \(error.localizedDescription)"
            }
        }
    }
    
    func removeFromFavorites(propertyId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("favorites")
                .whereField("userId", isEqualTo: userId)
                .whereField("propertyId", isEqualTo: propertyId)
                .getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
            // Refresh stats
            loadUserStats()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to remove from favorites: \(error.localizedDescription)"
            }
        }
    }
    
    func addToWatchlist(propertyId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let watchlistData: [String: Any] = [
                "userId": userId,
                "propertyId": propertyId,
                "addedAt": Timestamp(date: Date())
            ]
            
            try await db.collection("watchlist").addDocument(data: watchlistData)
            
            // Refresh stats
            loadUserStats()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to add to watchlist: \(error.localizedDescription)"
            }
        }
    }
    
    func removeFromWatchlist(propertyId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("watchlist")
                .whereField("userId", isEqualTo: userId)
                .whereField("propertyId", isEqualTo: propertyId)
                .getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
            // Refresh stats
            loadUserStats()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to remove from watchlist: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Profile Management
    func updateUserProfile(displayName: String?, photoURL: String?) async throws {
        guard let user = Auth.auth().currentUser else {
            throw UserStatsError.notAuthenticated
        }
        
        let changeRequest = user.createProfileChangeRequest()
        
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        
        if let photoURL = photoURL, let url = URL(string: photoURL) {
            changeRequest.photoURL = url
        }
        
        try await changeRequest.commitChanges()
        
        // Also update in Firestore for additional profile data
        let userData: [String: Any] = [
            "displayName": displayName ?? "",
            "photoURL": photoURL ?? "",
            "lastUpdated": Timestamp(date: Date())
        ]
        
        try await db.collection("userProfiles").document(user.uid).setData(userData, merge: true)
    }
    
    func updateExtendedProfile(
        displayName: String,
        photoURL: String,
        phoneNumber: String,
        location: String,
        bio: String
    ) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw UserStatsError.notAuthenticated
        }
        
        let userData: [String: Any] = [
            "displayName": displayName,
            "photoURL": photoURL,
            "phoneNumber": phoneNumber,
            "location": location,
            "bio": bio,
            "profileCompleteness": calculateProfileCompleteness(
                displayName: displayName,
                photoURL: photoURL,
                phoneNumber: phoneNumber,
                location: location,
                bio: bio
            ),
            "lastUpdated": Timestamp(date: Date())
        ]
        
        try await db.collection("userProfiles").document(userId).setData(userData, merge: true)
    }
    
    func loadExtendedProfile() async throws -> ExtendedUserProfile {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw UserStatsError.notAuthenticated
        }
        
        let document = try await db.collection("userProfiles").document(userId).getDocument()
        
        if let data = document.data() {
            return ExtendedUserProfile(
                displayName: data["displayName"] as? String ?? "",
                photoURL: data["photoURL"] as? String ?? "",
                phoneNumber: data["phoneNumber"] as? String ?? "",
                location: data["location"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                profileCompleteness: data["profileCompleteness"] as? Int ?? 0,
                lastUpdated: data["lastUpdated"] as? Timestamp ?? Timestamp(date: Date())
            )
        } else {
            return ExtendedUserProfile()
        }
    }
    
    func calculateProfileCompleteness(
        displayName: String,
        photoURL: String,
        phoneNumber: String,
        location: String,
        bio: String
    ) -> Int {
        var completeness = 0
        
        if !displayName.isEmpty { completeness += 20 }
        if !photoURL.isEmpty { completeness += 20 }
        if !phoneNumber.isEmpty { completeness += 20 }
        if !location.isEmpty { completeness += 20 }
        if !bio.isEmpty { completeness += 20 }
        
        return completeness
    }
    
    func getNotificationSettings() async -> UserNotificationSettings? {
        guard let userId = Auth.auth().currentUser?.uid else {
            return UserNotificationSettings()
        }
        
        do {
            let document = try await db.collection("userSettings").document(userId).getDocument()
            
            if let data = document.data() {
                return UserNotificationSettings(
                    bidOutbid: data["bidOutbid"] as? Bool ?? true,
                    auctionEnding: data["auctionEnding"] as? Bool ?? true,
                    newProperties: data["newProperties"] as? Bool ?? false,
                    priceDrops: data["priceDrops"] as? Bool ?? true,
                    auctionWon: data["auctionWon"] as? Bool ?? true,
                    auctionLost: data["auctionLost"] as? Bool ?? false,
                    marketUpdates: data["marketUpdates"] as? Bool ?? false,
                    emailNotifications: data["emailNotifications"] as? Bool ?? true,
                    pushNotifications: data["pushNotifications"] as? Bool ?? true
                )
            }
        } catch {
            print("❌ Error fetching notification settings: \(error)")
        }
        
        return UserNotificationSettings()
    }
    
    func updateNotificationSettings(_ settings: UserNotificationSettings) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let settingsData: [String: Any] = [
                "bidOutbid": settings.bidOutbid,
                "auctionEnding": settings.auctionEnding,
                "newProperties": settings.newProperties,
                "priceDrops": settings.priceDrops,
                "auctionWon": settings.auctionWon,
                "auctionLost": settings.auctionLost,
                "marketUpdates": settings.marketUpdates,
                "emailNotifications": settings.emailNotifications,
                "pushNotifications": settings.pushNotifications,
                "lastUpdated": Timestamp(date: Date())
            ]
            
            try await db.collection("userSettings").document(userId).setData(settingsData, merge: true)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update notification settings: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Supporting Models
struct TransactionRecord: Identifiable, Codable {
    let id: String
    let userId: String
    let propertyId: String
    let propertyTitle: String
    let amount: Double
    let type: TransactionType
    let status: TransactionStatus
    let timestamp: Timestamp
    
    enum TransactionType: String, Codable {
        case purchase = "purchase"
        case sale = "sale"
        case bid = "bid"
        case refund = "refund"
    }
    
    enum TransactionStatus: String, Codable {
        case completed = "completed"
        case pending = "pending"
        case cancelled = "cancelled"
        case failed = "failed"
    }
}



struct ExtendedUserProfile: Codable {
    var displayName: String = ""
    var photoURL: String = ""
    var phoneNumber: String = ""
    var location: String = ""
    var bio: String = ""
    var profileCompleteness: Int = 0
    var lastUpdated: Timestamp = Timestamp(date: Date())
    
    init() {}
    
    init(displayName: String, photoURL: String, phoneNumber: String, location: String, bio: String, profileCompleteness: Int, lastUpdated: Timestamp) {
        self.displayName = displayName
        self.photoURL = photoURL
        self.phoneNumber = phoneNumber
        self.location = location
        self.bio = bio
        self.profileCompleteness = profileCompleteness
        self.lastUpdated = lastUpdated
    }
}

enum UserStatsError: LocalizedError {
    case notAuthenticated
    case dataNotFound
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .dataNotFound:
            return "User data not found"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
