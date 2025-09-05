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
        let firestoreProperties = snapshot.documents.compactMap { document in
            try? document.data(as: AuctionProperty.self)
        }
        
        // If no properties in Firestore, use sample data as fallback
        if firestoreProperties.isEmpty {
            print("📦 No auction properties found in Firestore, using sample data")
            auctionProperties = createSampleAuctionProperties()
        } else {
            print("✅ Loaded \(firestoreProperties.count) auction properties from Firestore")
            auctionProperties = firestoreProperties
        }
    }
    
    // Alias for fetchAuctionProperties to maintain compatibility
    func loadAuctionProperties() async {
        do {
            try await fetchAuctionProperties()
        } catch {
            self.error = error.localizedDescription
            // Fallback to sample data on error
            auctionProperties = createSampleAuctionProperties()
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
        isCreatingData = true
        dataCreationProgress = 0.0
        defer { 
            isCreatingData = false
            dataCreationProgress = 0.0
        }
        
        print("🚀 Creating sample auction properties...")
        
        let sampleProperties = createSampleAuctionProperties()
        let total = Double(sampleProperties.count)
        
        for (index, property) in sampleProperties.enumerated() {
            do {
                try await createAuctionProperty(property)
                dataCreationProgress = Double(index + 1) / total
                print("✅ Created auction property: \(property.title)")
            } catch {
                print("❌ Failed to create property \(property.title): \(error)")
            }
        }
        
        print("🎉 Sample auction data creation completed!")
    }
    
    private func createSampleAuctionProperties() -> [AuctionProperty] {
        let currentTime = Date()
        let userId = currentUserId.isEmpty ? "sample-seller-1" : currentUserId
        let userName = currentUserName.isEmpty ? "Sample Seller" : currentUserName
        
        return [
            AuctionProperty(
                sellerId: userId,
                sellerName: userName,
                title: "Modern Villa with Ocean View",
                description: "Stunning 4-bedroom villa with panoramic ocean views, modern amenities, and private pool. Located in the prestigious Galle Face area with easy access to Colombo city center.",
                startingPrice: 4500000,
                currentBid: 4650000,
                highestBidderId: "bidder-001",
                highestBidderName: "John Smith",
                images: [
                    "https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800",
                    "https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?w=800",
                    "https://images.unsplash.com/photo-1505843795480-5cfb3c03f6ff?w=800"
                ],
                videos: [],
                arModelURL: nil,
                address: PropertyAddress(
                    street: "123 Galle Face Green",
                    city: "Colombo",
                    state: "Western Province",
                    postalCode: "00300",
                    country: "Sri Lanka"
                ),
                location: GeoPoint(latitude: 6.9271, longitude: 79.8612),
                features: PropertyFeatures(
                    bedrooms: 4,
                    bathrooms: 3,
                    area: 3500,
                    yearBuilt: 2022,
                    parkingSpaces: 2,
                    hasGarden: true,
                    hasPool: true,
                    hasGym: false,
                    floorNumber: nil,
                    totalFloors: 2,
                    propertyType: "Villa"
                ),
                auctionStartTime: currentTime.addingTimeInterval(-1800), // Started 30 min ago
                auctionEndTime: currentTime.addingTimeInterval(5400), // Ends in 1.5 hours
                auctionDuration: .twoHours,
                status: .active,
                category: .luxury,
                bidHistory: [
                    BidEntry(bidderId: "bidder-001", bidderName: "John Smith", amount: 4650000, timestamp: currentTime.addingTimeInterval(-900))
                ],
                watchlistUsers: ["user-001", "user-002"],
                createdAt: currentTime.addingTimeInterval(-3600),
                updatedAt: currentTime.addingTimeInterval(-900),
                winnerId: nil,
                winnerName: nil,
                finalPrice: nil,
                paymentStatus: nil,
                transactionId: nil,
                panoramicImages: [
                    PanoramicImage(
                        id: "pano-villa-001",
                        imageURL: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=4000&h=2000&fit=crop",
                        title: "Villa Living Room 360°",
                        description: "Spacious modern living room with ocean view",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-86400),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-villa-002",
                        imageURL: "https://images.unsplash.com/photo-1556912173-3bb406ef7e77?w=4000&h=2000&fit=crop",
                        title: "Villa Kitchen 360°",
                        description: "Modern kitchen with island and premium appliances",
                        roomType: .kitchen,
                        captureDate: currentTime.addingTimeInterval(-86400),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-villa-003", 
                        imageURL: "https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?w=4000&h=2000&fit=crop",
                        title: "Villa Master Bedroom 360°",
                        description: "Luxury master bedroom with panoramic windows",
                        roomType: .bedroom,
                        captureDate: currentTime.addingTimeInterval(-86400),
                        isAREnabled: true
                    )
                ],
                walkthroughVideoURL: nil
            ),
            
            AuctionProperty(
                sellerId: userId,
                sellerName: userName,
                title: "Luxury Apartment in Kiribathgoda",
                description: "Brand new 3-bedroom luxury apartment with modern kitchen, balcony garden, and 24/7 security. Perfect for families looking for comfort and convenience.",
                startingPrice: 1850000,
                currentBid: 1950000,
                highestBidderId: "bidder-002",
                highestBidderName: "Sarah Johnson",
                images: [
                    "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800",
                    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
                    "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800"
                ],
                videos: [],
                arModelURL: nil,
                address: PropertyAddress(
                    street: "456 Kiribathgoda Road",
                    city: "Kiribathgoda",
                    state: "Western Province",
                    postalCode: "11600",
                    country: "Sri Lanka"
                ),
                location: GeoPoint(latitude: 6.9804, longitude: 79.9297),
                features: PropertyFeatures(
                    bedrooms: 3,
                    bathrooms: 2,
                    area: 1800,
                    yearBuilt: 2023,
                    parkingSpaces: 1,
                    hasGarden: true,
                    hasPool: false,
                    hasGym: true,
                    floorNumber: 5,
                    totalFloors: 10,
                    propertyType: "Apartment"
                ),
                auctionStartTime: currentTime.addingTimeInterval(3600), // Starts in 1 hour
                auctionEndTime: currentTime.addingTimeInterval(7200), // Ends in 2 hours
                auctionDuration: .oneHour,
                status: .upcoming,
                category: .residential,
                bidHistory: [],
                watchlistUsers: ["user-003"],
                createdAt: currentTime.addingTimeInterval(-7200),
                updatedAt: currentTime,
                winnerId: nil,
                winnerName: nil,
                finalPrice: nil,
                paymentStatus: nil,
                transactionId: nil,
                panoramicImages: [
                    PanoramicImage(
                        id: "pano-apt-001",
                        imageURL: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=4000&h=2000&fit=crop",
                        title: "Apartment Living Area 360°",
                        description: "Modern apartment living space with city views",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-7200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-apt-002",
                        imageURL: "https://images.unsplash.com/photo-1493663284031-b7e3aaa4c4bc?w=4000&h=2000&fit=crop",
                        title: "Apartment Balcony 360°",
                        description: "Private balcony with garden view",
                        roomType: .balcony,
                        captureDate: currentTime.addingTimeInterval(-7200),
                        isAREnabled: true
                    )
                ],
                walkthroughVideoURL: nil
            ),
            
            AuctionProperty(
                sellerId: userId,
                sellerName: userName,
                title: "Traditional House in Kandy",
                description: "Beautiful traditional Sri Lankan house with wooden architecture, large garden, and mountain views. Perfect for those who love heritage and nature.",
                startingPrice: 1275000,
                currentBid: 1420000,
                highestBidderId: "bidder-003",
                highestBidderName: "Michael Chen",
                images: [
                    "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800",
                    "https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=800",
                    "https://images.unsplash.com/photo-1585128792020-803d29415281?w=800"
                ],
                videos: [],
                arModelURL: nil,
                address: PropertyAddress(
                    street: "789 Temple Road",
                    city: "Kandy",
                    state: "Central Province",
                    postalCode: "20000",
                    country: "Sri Lanka"
                ),
                location: GeoPoint(latitude: 7.2906, longitude: 80.6337),
                features: PropertyFeatures(
                    bedrooms: 5,
                    bathrooms: 2,
                    area: 2800,
                    yearBuilt: 1985,
                    parkingSpaces: 2,
                    hasGarden: true,
                    hasPool: false,
                    hasGym: false,
                    floorNumber: nil,
                    totalFloors: 1,
                    propertyType: "House"
                ),
                auctionStartTime: currentTime.addingTimeInterval(-7200), // Started 2 hours ago
                auctionEndTime: currentTime.addingTimeInterval(-3600), // Ended 1 hour ago
                auctionDuration: .oneDay,
                status: .ended,
                category: .residential,
                bidHistory: [
                    BidEntry(bidderId: "bidder-003", bidderName: "Michael Chen", amount: 1420000, timestamp: currentTime.addingTimeInterval(-3900)),
                    BidEntry(bidderId: "bidder-004", bidderName: "Emma Davis", amount: 1350000, timestamp: currentTime.addingTimeInterval(-5400))
                ],
                watchlistUsers: ["user-004", "user-005"],
                createdAt: currentTime.addingTimeInterval(-86400),
                updatedAt: currentTime.addingTimeInterval(-3600),
                winnerId: "bidder-003",
                winnerName: "Michael Chen",
                finalPrice: 1420000,
                paymentStatus: .pending,
                transactionId: nil,
                panoramicImages: [
                    PanoramicImage(
                        id: "pano-house-001",
                        imageURL: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=4000&h=2000&fit=crop",
                        title: "Traditional Living Room 360°",
                        description: "Authentic Sri Lankan wooden living room with heritage furniture",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-172800),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-house-002",
                        imageURL: "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=4000&h=2000&fit=crop",
                        title: "Traditional Kitchen 360°",
                        description: "Authentic Sri Lankan kitchen with traditional wood fire setup",
                        roomType: .kitchen,
                        captureDate: currentTime.addingTimeInterval(-172800),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-house-003",
                        imageURL: "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=4000&h=2000&fit=crop",
                        title: "Garden View 360°",
                        description: "Lush tropical garden with mountain views",
                        roomType: .garden,
                        captureDate: currentTime.addingTimeInterval(-172800),
                        isAREnabled: true
                    )
                ],
                walkthroughVideoURL: nil
            ),
            
            AuctionProperty(
                sellerId: userId,
                sellerName: userName,
                title: "Beach Front Land in Negombo",
                description: "Prime beachfront land perfect for hotel or resort development. Direct beach access with 100m of pristine coastline. Excellent investment opportunity.",
                startingPrice: 7500000,
                currentBid: 7500000,
                highestBidderId: nil,
                highestBidderName: nil,
                images: [
                    "https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800",
                    "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800",
                    "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800"
                ],
                videos: [],
                arModelURL: nil,
                address: PropertyAddress(
                    street: "Beachfront Plot 15",
                    city: "Negombo",
                    state: "Western Province",
                    postalCode: "11500",
                    country: "Sri Lanka"
                ),
                location: GeoPoint(latitude: 7.2084, longitude: 79.8385),
                features: PropertyFeatures(
                    bedrooms: 0,
                    bathrooms: 0,
                    area: 5000,
                    yearBuilt: nil,
                    parkingSpaces: 0,
                    hasGarden: false,
                    hasPool: false,
                    hasGym: false,
                    floorNumber: nil,
                    totalFloors: nil,
                    propertyType: "Land"
                ),
                auctionStartTime: currentTime.addingTimeInterval(86400), // Starts tomorrow
                auctionEndTime: currentTime.addingTimeInterval(90000), // Ends tomorrow + 1 hour
                auctionDuration: .oneHour,
                status: .upcoming,
                category: .investment,
                bidHistory: [],
                watchlistUsers: ["user-006"],
                createdAt: currentTime.addingTimeInterval(-43200),
                updatedAt: currentTime.addingTimeInterval(-3600),
                winnerId: nil,
                winnerName: nil,
                finalPrice: nil,
                paymentStatus: nil,
                transactionId: nil,
                panoramicImages: [
                    PanoramicImage(
                        id: "pano-beach-001",
                        imageURL: "https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=4000&h=2000&fit=crop",
                        title: "Beach Front View 360°",
                        description: "Pristine coastline with crystal clear waters",
                        roomType: .outdoor,
                        captureDate: currentTime.addingTimeInterval(-43200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-beach-002",
                        imageURL: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=4000&h=2000&fit=crop",
                        title: "Sunset Beach 360°",
                        description: "Stunning sunset views over the Indian Ocean",
                        roomType: .outdoor,
                        captureDate: currentTime.addingTimeInterval(-43200),
                        isAREnabled: true
                    )
                ],
                walkthroughVideoURL: nil
            ),
            
            AuctionProperty(
                sellerId: userId,
                sellerName: userName,
                title: "Penthouse in Colombo 07",
                description: "Luxurious penthouse with 360-degree city views, private elevator, and rooftop terrace. Premium location in Cinnamon Gardens.",
                startingPrice: 9500000,
                currentBid: 10200000,
                highestBidderId: "bidder-005",
                highestBidderName: "David Wilson",
                images: [
                    "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800",
                    "https://images.unsplash.com/photo-1507089947368-19c1da9775ae?w=800",
                    "https://images.unsplash.com/photo-1574362848149-11496d93a7c7?w=800"
                ],
                videos: [],
                arModelURL: nil,
                address: PropertyAddress(
                    street: "Penthouse 20A, Cinnamon Gardens",
                    city: "Colombo",
                    state: "Western Province",
                    postalCode: "00700",
                    country: "Sri Lanka"
                ),
                location: GeoPoint(latitude: 6.9147, longitude: 79.8757),
                features: PropertyFeatures(
                    bedrooms: 4,
                    bathrooms: 4,
                    area: 4800,
                    yearBuilt: 2021,
                    parkingSpaces: 3,
                    hasGarden: true,
                    hasPool: true,
                    hasGym: true,
                    floorNumber: 20,
                    totalFloors: 20,
                    propertyType: "Penthouse"
                ),
                auctionStartTime: currentTime.addingTimeInterval(-3600), // Started 1 hour ago
                auctionEndTime: currentTime.addingTimeInterval(1800), // Ends in 30 minutes
                auctionDuration: .twoHours,
                status: .active,
                category: .luxury,
                bidHistory: [
                    BidEntry(bidderId: "bidder-005", bidderName: "David Wilson", amount: 10200000, timestamp: currentTime.addingTimeInterval(-1800)),
                    BidEntry(bidderId: "bidder-006", bidderName: "Lisa Anderson", amount: 9800000, timestamp: currentTime.addingTimeInterval(-2700))
                ],
                watchlistUsers: ["user-007", "user-008", "user-009"],
                createdAt: currentTime.addingTimeInterval(-129600),
                updatedAt: currentTime.addingTimeInterval(-1800),
                winnerId: nil,
                winnerName: nil,
                finalPrice: nil,
                paymentStatus: nil,
                transactionId: nil,
                panoramicImages: [
                    PanoramicImage(
                        id: "pano-penthouse-001",
                        imageURL: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=4000&h=2000&fit=crop",
                        title: "Penthouse Living Area 360°",
                        description: "Ultra-luxury penthouse living space with panoramic city views",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-259200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-penthouse-002",
                        imageURL: "https://images.unsplash.com/photo-1507089947368-19c1da9775ae?w=4000&h=2000&fit=crop",
                        title: "Rooftop Terrace 360°",
                        description: "Private rooftop terrace with 360° city skyline views",
                        roomType: .balcony,
                        captureDate: currentTime.addingTimeInterval(-259200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-penthouse-003",
                        imageURL: "https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=4000&h=2000&fit=crop",
                        title: "Master Suite 360°",
                        description: "Luxury master suite with floor-to-ceiling windows",
                        roomType: .bedroom,
                        captureDate: currentTime.addingTimeInterval(-259200),
                        isAREnabled: true
                    )
                ],
                walkthroughVideoURL: nil
            )
        ]
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
