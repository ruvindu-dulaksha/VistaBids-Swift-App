//
//  BiddingService.swift
//  VistaBids
//
//  Created by Assistant on 2025-08-08.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import UserNotifications

@MainActor
class BiddingService: ObservableObject {
    private let db = Firestore.firestore()
    private let propertyDataService = AuctionPropertyDataService()
    private let auctionTimerService = AuctionTimerService()
    private let paymentService = PaymentService()
    
    @Published var auctionProperties: [AuctionProperty] = []
    @Published var userBids: [UserBid] = []
    @Published var watchlist: [WatchlistItem] = []
    @Published var bidHistory: [BidHistoryItem] = []
    @Published var winnerNotifications: [AuctionWinnerNotification] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Enhanced data creation properties
    @Published var isCreatingData = false
    @Published var dataCreationProgress: Double = 0.0
    
    private var listeners: [ListenerRegistration] = []
    
    // Current user properties
    var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    var currentUserName: String {
        return Auth.auth().currentUser?.displayName ?? "Anonymous"
    }
    
    init() {
        setupBasicListeners()
    }
    
    deinit {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Basic Real-time Listeners
    private func setupBasicListeners() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Listen to auction properties
        let auctionListener = db.collection("auction_properties")
            .whereField("status", in: ["upcoming", "active"])
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.auctionProperties = documents.compactMap { document in
                    try? document.data(as: AuctionProperty.self)
                }.sorted(by: { $0.auctionStartTime < $1.auctionStartTime })
            }
        
        listeners = [auctionListener]
    }
    
    // MARK: - Basic Methods (Simplified for checkpoint restoration)
    
    func placeBid(on propertyId: String, amount: Double, maxAutoBid: Double?) async throws {
        guard !currentUserId.isEmpty else {
            throw BiddingError.userNotAuthenticated
        }
        
        // Create user bid record
        let bid = [
            "id": UUID().uuidString,
            "userId": currentUserId,
            "propertyId": propertyId,
            "bidAmount": amount,
            "timestamp": Timestamp(date: Date()),
            "status": "active",
            "isWinning": false
        ] as [String : Any]
        
        try await db.collection("user_bids").addDocument(data: bid)
        print("Bid placed: $\(amount) on property \(propertyId)")
    }
    
    func addToWatchlist(propertyId: String) async throws {
        guard !currentUserId.isEmpty else {
            throw BiddingError.userNotAuthenticated
        }
        
        let watchlistItem = [
            "id": UUID().uuidString,
            "propertyID": propertyId,
            "userID": currentUserId,
            "addedDate": Timestamp(date: Date()),
            "notificationsEnabled": true
        ] as [String : Any]
        
        try await db.collection("watchlist").addDocument(data: watchlistItem)
        print("Added to watchlist: \(propertyId)")
    }
    
    func removeFromWatchlist(propertyId: String) async throws {
        guard !currentUserId.isEmpty else {
            throw BiddingError.userNotAuthenticated
        }
        
        let snapshot = try await db.collection("watchlist")
            .whereField("propertyID", isEqualTo: propertyId)
            .whereField("userID", isEqualTo: currentUserId)
            .getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
        
        print("Removed from watchlist: \(propertyId)")
    }
    
    func isInWatchlist(propertyId: String) -> Bool {
        return watchlist.contains { $0.propertyID == propertyId }
    }
    
    func fetchAuctionProperties() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let snapshot = try await db.collection("auction_properties").getDocuments()
        auctionProperties = snapshot.documents.compactMap { document in
            try? document.data(as: AuctionProperty.self)
        }
    }
    
    // Alias for fetchAuctionProperties to maintain compatibility
    func loadAuctionProperties() async {
        do {
            try await fetchAuctionProperties()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func fetchUserBids() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let snapshot = try await db.collection("user_bids")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        userBids = snapshot.documents.compactMap { document in
            try? document.data(as: UserBid.self)
        }
    }
    
    func createEnhancedAuctionData() async throws {
        // TODO: Implement enhanced data creation after restoration
        print("Enhanced auction data creation - to be implemented")
    }
    
    func createAuctionProperty(_ property: AuctionProperty) async throws {
        try await db.collection("auction_properties").addDocument(from: property)
        print("Auction property created successfully")
    }
    
    func startListeningToAuctionUpdates(for propertyId: String) {
        // TODO: Implement real-time auction updates after restoration
        print("Started listening to auction updates for property: \(propertyId)")
    }
    
    func stopListeningToAuctionUpdates() {
        // TODO: Implement stopping auction updates after restoration
        print("Stopped listening to auction updates")
    }
    
    func createAuctionProperty(
        title: String,
        description: String,
        startingPrice: Double,
        images: [String],
        videos: [String],
        arModelURL: String?,
        address: PropertyAddress,
        location: GeoPoint,
        features: PropertyFeatures,
        auctionStartTime: Date,
        auctionEndTime: Date,
        auctionDuration: AuctionDuration,
        category: PropertyCategory,
        panoramicImages: [PanoramicImage],
        walkthroughVideoURL: String?
    ) async throws {
        guard !currentUserId.isEmpty else {
            throw BiddingError.userNotAuthenticated
        }
        
        let property = AuctionProperty(
            sellerId: currentUserId,
            sellerName: currentUserName,
            title: title,
            description: description,
            startingPrice: startingPrice,
            currentBid: startingPrice,
            highestBidderId: nil,
            highestBidderName: nil,
            images: images,
            videos: videos,
            arModelURL: arModelURL,
            address: address,
            location: location,
            features: features,
            auctionStartTime: auctionStartTime,
            auctionEndTime: auctionEndTime,
            auctionDuration: auctionDuration,
            status: .upcoming,
            category: category,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: Date(),
            updatedAt: Date(),
            winnerId: nil,
            winnerName: nil,
            finalPrice: nil,
            paymentStatus: nil,
            transactionId: nil,
            panoramicImages: panoramicImages,
            walkthroughVideoURL: walkthroughVideoURL
        )
        
        try await createAuctionProperty(property)
    }
    
    // MARK: - Chat Methods
    func getChatMessages(for propertyId: String) async throws -> [AuctionChatMessage] {
        // Placeholder implementation - returns empty array
        return []
    }
    
    func listenToChatMessages(propertyId: String, completion: @escaping ([AuctionChatMessage]) -> Void) async {
        // Placeholder implementation - calls completion with empty array
        completion([])
    }
    
    func getAuctionChatRoom(for propertyId: String) async -> AuctionChatRoom? {
        // Placeholder implementation - returns nil
        return nil
    }
    
    func sendChatMessage(message: AuctionChatMessage) async throws {
        // Placeholder implementation - does nothing
        print("Sending message: \(message.message)")
    }
}

// MARK: - Error Types
enum BiddingError: LocalizedError {
    case userNotAuthenticated
    case invalidBidAmount
    case auctionNotActive
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to place bids"
        case .invalidBidAmount:
            return "Invalid bid amount"
        case .auctionNotActive:
            return "Auction is not currently active"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
