//
//  BiddingService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-08.
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
    let auctionTimerService = AuctionTimerService() 
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
        // Try to setup listeners, but also add auth state change observer
        setupBasicListeners()
        setupAuthStateListener()
    }
    
    deinit {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    //  Auth State Management
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            if user != nil {
                print("🔐 BiddingService: User authenticated, setting up listeners")
                self.restartListeners()
            } else {
                print("🔐 BiddingService: User signed out, removing listeners")
                self.stopListeners()
            }
        }
    }
    
    // Public Methods for Listener Management
    public func restartListeners() {
        stopListeners()
        setupBasicListeners()
    }
    
    private func stopListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    //  Basic Real-time Listeners
    private func setupBasicListeners() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("⚠️ BiddingService: No authenticated user, skipping listener setup")
            return 
        }
        
        print("🔄 BiddingService: Setting up listeners for user: \(userId)")
        
        // Listen to auction properties - ALL STATUSES for real-time updates
        let auctionListener = db.collection("auction_properties")
            .order(by: "auctionStartTime", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ BiddingService: Error listening to auctions: \(error)")
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("⚠️ BiddingService: No auction documents found")
                    return 
                }
                
                print("🔄 BiddingService: Received \(documents.count) auction updates")
                
                let allProperties = documents.compactMap { document -> AuctionProperty? in
                    do {
                        var property = try document.data(as: AuctionProperty.self)
                        // Manually set the document ID
                        property.id = document.documentID
                        return property
                    } catch {
                        print("❌ Error decoding property \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    self.auctionProperties = allProperties.sorted(by: { $0.auctionStartTime < $1.auctionStartTime })
                    self.objectWillChange.send() 
                    print(" BiddingService: Updated \(self.auctionProperties.count) auction properties")
                    print(" BiddingService: Forced UI refresh")
                }
            }
        
        listeners = [auctionListener]
    }
    
    //  Basic Methods (Simplified for checkpoint restoration)
    
    func placeBid(on propertyId: String, amount: Double, maxAutoBid: Double?) async throws {
        guard !currentUserId.isEmpty else {
            throw BiddingError.userNotAuthenticated
        }
        
        // Get current user info
        let currentUser = Auth.auth().currentUser
        let userName = currentUser?.displayName ?? "Anonymous Bidder"
        
        // First, verify the property exists and is active
        let propertyRef = db.collection("auction_properties").document(propertyId)
        let propertySnapshot = try await propertyRef.getDocument()
        
        guard propertySnapshot.exists,
              let propertyData = propertySnapshot.data(),
              let currentBid = propertyData["currentBid"] as? Double,
              let status = propertyData["status"] as? String,
              status == "active" else {
            throw BiddingError.auctionNotActive
        }
        
        // Verify bid amount is higher than current bid
        guard amount > currentBid else {
            throw BiddingError.invalidBidAmount
        }
        
        // Create user bid record
        let bid = [
            "id": UUID().uuidString,
            "userId": currentUserId,
            "userName": userName,
            "propertyId": propertyId,
            "bidAmount": amount,
            "timestamp": Timestamp(date: Date()),
            "status": "active",
            "isWinning": true,  
            "maxAutoBid": maxAutoBid ?? 0
        ] as [String : Any]
        
        try await db.collection("user_bids").addDocument(data: bid)
        
        // Update the auction property with new highest bid
        try await propertyRef.updateData([
            "currentBid": amount,
            "highestBidderId": currentUserId,
            "highestBidderName": userName,
            "updatedAt": Timestamp(date: Date())
        ])
        
        // Add to bid history
        let bidHistoryItem: [String: Any] = [
            "bidAmount": amount,
            "bidderId": currentUserId,
            "bidderName": userName,
            "timestamp": Timestamp(date: Date())
        ]
        
        try await propertyRef.updateData([
            "bidHistory": FieldValue.arrayUnion([bidHistoryItem])
        ])
        
        print("Bid placed successfully: $\(amount) on property \(propertyId) by \(userName)")
        
        // Send notifications to other bidders about being outbid
        await sendOutbidNotifications(propertyId: propertyId, newBidAmount: amount, newBidderName: userName)
        
        // Force immediate refresh to ensure UI updates quickly
        DispatchQueue.main.async {
            // Update the local property immediately for instant UI feedback
            if let index = self.auctionProperties.firstIndex(where: { $0.id == propertyId }) {
                self.auctionProperties[index].currentBid = amount
                self.auctionProperties[index].highestBidderId = self.currentUserId
                self.auctionProperties[index].highestBidderName = userName
                
                // Add to bid history locally
                let newBid = BidEntry(
                    id: UUID().uuidString,
                    bidderId: self.currentUserId,
                    bidderName: userName,
                    amount: amount,
                    timestamp: Date(),
                    bidType: .regular
                )
                self.auctionProperties[index].bidHistory.append(newBid)
                
                print(" Updated local property data immediately")
            }
        }
        
        // Also trigger a refresh from server (listeners should handle this, but backup)
        Task {
            await loadAuctionProperties()
        }
    }
    
    //  Payment Processing
    
    func completePayment(for propertyId: String) async throws {
        guard !currentUserId.isEmpty else {
            throw BiddingError.userNotAuthenticated
        }
        
        print(" Starting payment completion for property: \(propertyId)")
        
        // Update property payment status in Firebase
        let propertyRef = db.collection("auction_properties").document(propertyId)
        
        try await propertyRef.updateData([
            "paymentStatus": "completed",
            "paymentDate": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ])
        
        print(" Payment completed successfully for property \(propertyId)")
        
        // Update local data immediately for instant UI feedback
        DispatchQueue.main.async {
            if let index = self.auctionProperties.firstIndex(where: { $0.id == propertyId }) {
                self.auctionProperties[index].paymentStatus = .completed
                print(" Updated local property payment status to completed")
            }
        }
        
        // Trigger a refresh to ensure data consistency
        Task {
            await loadAuctionProperties()
        }
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
        
        do {
            // First try to load from Firestore
            let snapshot = try await db.collection("auction_properties").getDocuments()
            let firestoreProperties = snapshot.documents.compactMap { document -> AuctionProperty? in
                do {
                    var property = try document.data(as: AuctionProperty.self)
                    // Manually set the document ID
                    property.id = document.documentID
                    return property
                } catch {
                    print(" Error decoding property from Firestore: \(error)")
                    return nil
                }
            }
            
            // If no properties in Firestore, use sample data as fallback
            if firestoreProperties.isEmpty {
                print("No auction properties found in Firestore, using sample data")
                auctionProperties = createSampleAuctionProperties()
                
                // Start timers for sample data
                for property in auctionProperties {
                    if property.status == AuctionStatus.active || property.status == AuctionStatus.upcoming {
                        auctionTimerService.startAuctionTimer(for: property)
                    }
                }
                
                // Auto-populate Firestore with enhanced sample data for future use
                print("Auto-populating Firestore with enhanced sample data")
                Task {
                    do {
                        try await createEnhancedAuctionData()
                    } catch {
                        print("Failed to auto-populate Firestore: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Loaded \(firestoreProperties.count) auction properties from Firestore")
                
                // Process properties to ensure we have proper statuses based on current time
                let currentTime = Date()
                print(" Processing \(firestoreProperties.count) properties at time: \(currentTime)")
                let processedProperties = firestoreProperties.map { property -> AuctionProperty in
                    var updatedProperty = property
                    
                    let oldStatus = property.status
                    // Update status based on current time
                    if property.auctionStartTime > currentTime {
                        updatedProperty.status = AuctionStatus.upcoming
                    } else if property.auctionEndTime < currentTime {
                        updatedProperty.status = AuctionStatus.ended
                    } else {
                        updatedProperty.status = AuctionStatus.active
                    }
                    
                    if oldStatus != updatedProperty.status {
                        print("Property \(property.id ?? "unknown"): \(oldStatus.rawValue) -> \(updatedProperty.status.rawValue)")
                        print("   Start: \(property.auctionStartTime), End: \(property.auctionEndTime), Now: \(currentTime)")
                    }
                    
                    return updatedProperty
                }
                
                // Only have 1-2 live auctions at a time to make it more realistic
                var propertyCount = [AuctionStatus.active: 0]
                let finalProperties = processedProperties.map { property -> AuctionProperty in
                    var updatedProperty = property
                    
                    if property.status == AuctionStatus.active {
                        propertyCount[AuctionStatus.active, default: 0] += 1
                        
                        // If we already have 2 active auctions, make others upcoming
                        if propertyCount[AuctionStatus.active, default: 0] > 2 {
                            updatedProperty.status = AuctionStatus.upcoming
                            // Adjust auction times to be in the future
                            let newStartTime = currentTime.addingTimeInterval(Double.random(in: 3600...86400))
                            updatedProperty.auctionStartTime = newStartTime
                            updatedProperty.auctionEndTime = newStartTime.addingTimeInterval(Double(updatedProperty.auctionDuration.seconds))
                        }
                    }
                    
                    return updatedProperty
                }
                
                auctionProperties = finalProperties
                
                // Start auction timers for active and upcoming auctions
                for property in finalProperties {
                    if property.status == AuctionStatus.active || property.status == AuctionStatus.upcoming {
                        auctionTimerService.startAuctionTimer(for: property)
                    }
                }
                
                // Update any changed properties in Firestore
                for (index, property) in processedProperties.enumerated() {
                    if property.status != finalProperties[index].status ||
                       property.auctionStartTime != finalProperties[index].auctionStartTime ||
                       property.auctionEndTime != finalProperties[index].auctionEndTime {
                        
                        // Find the document ID for this property
                        if let docID = snapshot.documents[index].documentID as String? {
                            try await db.collection("auction_properties").document(docID).updateData([
                                "status": finalProperties[index].status.rawValue,
                                "auctionStartTime": finalProperties[index].auctionStartTime,
                                "auctionEndTime": finalProperties[index].auctionEndTime,
                                "updatedAt": Date()
                            ])
                            print("Updated property status in Firestore: \(property.title)")
                        }
                    }
                }
            }
        } catch {
            print("Error fetching from Firestore: \(error.localizedDescription)")
            // Fallback to sample data in case of Firestore error
            auctionProperties = createSampleAuctionProperties()
            throw error
        }
    }
    
    // Alias for fetchAuctionProperties to maintain compatibility
    func loadAuctionProperties() async {
        do {
            try await fetchAuctionProperties()
        } catch {
            self.error = error.localizedDescription
            // Fallback to sample data on error
            auctionProperties = updateSampleDataStatuses(createSampleAuctionProperties())
            print("Using sample data due to Firestore error: \(error.localizedDescription)")
        }
    }
    
    // Update sample data statuses based on current time
    private func updateSampleDataStatuses(_ properties: [AuctionProperty]) -> [AuctionProperty] {
        let currentTime = Date()
        return properties.map { property in
            var updatedProperty = property
            
            // Update status based on current time
            if property.auctionStartTime > currentTime {
                updatedProperty.status = AuctionStatus.upcoming
            } else if property.auctionEndTime < currentTime {
                updatedProperty.status = AuctionStatus.ended
            } else {
                updatedProperty.status = AuctionStatus.active
            }
            
            return updatedProperty
        }
    }
    
    // Method to refresh a single property by ID
    func refreshProperty(propertyId: String) async throws {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("auction_properties").document(propertyId).getDocument()
        
        guard let data = snapshot.data(),
              let property = try? Firestore.Decoder().decode(AuctionProperty.self, from: data) else {
            throw BiddingError.dataDecodingFailed
        }
        
        // Update the property in our local array
        if let index = auctionProperties.firstIndex(where: { $0.id == propertyId }) {
            auctionProperties[index] = property
            objectWillChange.send()
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
        
        print("Creating sample auction properties...")
        
        let sampleProperties = createSampleAuctionProperties()
        let total = Double(sampleProperties.count)
        
        for (index, property) in sampleProperties.enumerated() {
            do {
                try await createAuctionProperty(property)
                dataCreationProgress = Double(index + 1) / total
                print("Created auction property: \(property.title)")
            } catch {
                print("Failed to create property \(property.title): \(error)")
            }
        }
        
        print(" Sample auction data creation completed!")
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
                description: "Stunning 4-bedroom villa with panoramic ocean views, modern amenities, and private pool. Located in the prestigious Galle Face area with easy access to Colombo city center. This exclusive property features high-end finishes, smart home automation, and 24/7 security.",
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
                status: AuctionStatus.active,
                category: .luxury,
                bidHistory: [
                    BidEntry(bidderId: "bidder-001", bidderName: "John Smith", amount: 4650000, timestamp: currentTime.addingTimeInterval(-900)),
                    BidEntry(bidderId: "bidder-004", bidderName: "Emma Davis", amount: 4575000, timestamp: currentTime.addingTimeInterval(-1200)),
                    BidEntry(bidderId: "bidder-007", bidderName: "Alex Thompson", amount: 4520000, timestamp: currentTime.addingTimeInterval(-1500))
                ],
                watchlistUsers: ["user-001", "user-002", "user-003", "user-007"],
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
                        description: "Spacious modern living room with ocean view and designer furniture",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-86400),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-villa-002",
                        imageURL: "https://images.unsplash.com/photo-1556912173-3bb406ef7e77?w=4000&h=2000&fit=crop",
                        title: "Villa Kitchen 360°",
                        description: "Modern chef's kitchen with island and premium appliances",
                        roomType: .kitchen,
                        captureDate: currentTime.addingTimeInterval(-86400),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-villa-003", 
                        imageURL: "https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?w=4000&h=2000&fit=crop",
                        title: "Villa Master Bedroom 360°",
                        description: "Luxury master bedroom with panoramic windows and ensuite bathroom",
                        roomType: .bedroom,
                        captureDate: currentTime.addingTimeInterval(-86400),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-villa-004",
                        imageURL: "https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=4000&h=2000&fit=crop",
                        title: "Villa Pool & Garden 360°",
                        description: "Infinity pool with ocean views and beautifully landscaped garden",
                        roomType: .outdoor,
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
                description: "Brand new 3-bedroom luxury apartment with modern kitchen, balcony garden, and 24/7 security. Perfect for families looking for comfort and convenience. Features include smart home technology, premium finishes, and access to exclusive community amenities.",
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
                status: AuctionStatus.upcoming,
                category: .residential,
                bidHistory: [],
                watchlistUsers: ["user-003", "user-009"],
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
                        description: "Modern apartment living space with city views and premium finishes",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-7200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-apt-002",
                        imageURL: "https://images.unsplash.com/photo-1493663284031-b7e3aaa4c4bc?w=4000&h=2000&fit=crop",
                        title: "Apartment Balcony 360°",
                        description: "Private balcony with garden view and outdoor seating area",
                        roomType: .balcony,
                        captureDate: currentTime.addingTimeInterval(-7200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-apt-003",
                        imageURL: "https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=4000&h=2000&fit=crop",
                        title: "Apartment Master Bedroom 360°",
                        description: "Elegant master bedroom with built-in wardrobe and en-suite bathroom",
                        roomType: .bedroom,
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
                description: "Beautiful traditional Sri Lankan house with wooden architecture, large garden, and mountain views. Perfect for those who love heritage and nature. Features include handcrafted woodwork, authentic Sri Lankan decor, and serene surroundings close to the Temple of the Tooth.",
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
                status: AuctionStatus.ended,
                category: .residential,
                bidHistory: [
                    BidEntry(bidderId: "bidder-003", bidderName: "Michael Chen", amount: 1420000, timestamp: currentTime.addingTimeInterval(-3900)),
                    BidEntry(bidderId: "bidder-004", bidderName: "Emma Davis", amount: 1350000, timestamp: currentTime.addingTimeInterval(-5400)),
                    BidEntry(bidderId: "bidder-008", bidderName: "Sam Wilson", amount: 1320000, timestamp: currentTime.addingTimeInterval(-6300))
                ],
                watchlistUsers: ["user-004", "user-005", "user-011"],
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
                        description: "Authentic Sri Lankan wooden living room with heritage furniture and carved details",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-172800),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-house-002",
                        imageURL: "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=4000&h=2000&fit=crop",
                        title: "Traditional Kitchen 360°",
                        description: "Authentic Sri Lankan kitchen with traditional wood fire setup and modern conveniences",
                        roomType: .kitchen,
                        captureDate: currentTime.addingTimeInterval(-172800),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-house-003",
                        imageURL: "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=4000&h=2000&fit=crop",
                        title: "Garden View 360°",
                        description: "Lush tropical garden with mountain views and native plantings",
                        roomType: .garden,
                        captureDate: currentTime.addingTimeInterval(-172800),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-house-004",
                        imageURL: "https://images.unsplash.com/photo-1565329921943-7e537b7a2ea9?w=4000&h=2000&fit=crop",
                        title: "Mountain View 360°",
                        description: "Breathtaking panoramic view of Knuckles Mountain Range from the property",
                        roomType: .outdoor,
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
                description: "Prime beachfront land perfect for hotel or resort development. Direct beach access with 100m of pristine coastline. Excellent investment opportunity with approved zoning for commercial development and all necessary permits already secured.",
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
                status: AuctionStatus.upcoming,
                category: .investment,
                bidHistory: [],
                watchlistUsers: ["user-006", "user-007", "user-012"],
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
                        imageURL: "https://images.unsplash.com/photo-1566843577390-81ddef6fcc8c?w=4000&h=2000&fit=crop",
                        title: "Beach Front View 360°",
                        description: "Pristine coastline with crystal clear waters and white sand beaches",
                        roomType: .outdoor,
                        captureDate: currentTime.addingTimeInterval(-43200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-beach-002",
                        imageURL: "https://images.unsplash.com/photo-1484821582734-6692f9b19454?w=4000&h=2000&fit=crop",
                        title: "Sunset Beach 360°",
                        description: "Stunning sunset views over the Indian Ocean with silhouettes of fishing boats",
                        roomType: .outdoor,
                        captureDate: currentTime.addingTimeInterval(-43200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-beach-003",
                        imageURL: "https://images.unsplash.com/photo-1610641818989-c2051b5e2cfd?w=4000&h=2000&fit=crop",
                        title: "Aerial View 360°",
                        description: "Drone captured panoramic aerial view showing the entire beachfront property",
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
                description: "Luxurious penthouse with 360-degree city views, private elevator, and rooftop terrace. Premium location in Cinnamon Gardens with access to elite shopping, dining, and entertainment. Includes smart home features, imported finishes, and dedicated concierge service.",
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
                status: AuctionStatus.active,
                category: .luxury,
                bidHistory: [
                    BidEntry(bidderId: "bidder-005", bidderName: "David Wilson", amount: 10200000, timestamp: currentTime.addingTimeInterval(-1800)),
                    BidEntry(bidderId: "bidder-006", bidderName: "Lisa Anderson", amount: 9800000, timestamp: currentTime.addingTimeInterval(-2700)),
                    BidEntry(bidderId: "bidder-010", bidderName: "Robert Zhang", amount: 9650000, timestamp: currentTime.addingTimeInterval(-3000))
                ],
                watchlistUsers: ["user-007", "user-008", "user-009", "user-013", "user-014"],
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
                        imageURL: "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=4000&h=2000&fit=crop",
                        title: "Penthouse Living Area 360°",
                        description: "Ultra-luxury penthouse living space with panoramic city views and designer furniture",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-259200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-penthouse-002",
                        imageURL: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=4000&h=2000&fit=crop",
                        title: "Rooftop Terrace 360°",
                        description: "Private rooftop terrace with 360° city skyline views, lounging areas and infinity pool",
                        roomType: .balcony,
                        captureDate: currentTime.addingTimeInterval(-259200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-penthouse-003",
                        imageURL: "https://images.unsplash.com/photo-1560185893-a55cbc8c57e8?w=4000&h=2000&fit=crop",
                        title: "Master Suite 360°",
                        description: "Luxury master suite with floor-to-ceiling windows, walk-in closet and spa bathroom",
                        roomType: .bedroom,
                        captureDate: currentTime.addingTimeInterval(-259200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-penthouse-004",
                        imageURL: "https://images.unsplash.com/photo-1560448204-61dc36dc98c8?w=4000&h=2000&fit=crop",
                        title: "Gourmet Kitchen 360°",
                        description: "Chef's kitchen with custom cabinetry, marble countertops and premium appliances",
                        roomType: .kitchen,
                        captureDate: currentTime.addingTimeInterval(-259200),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-penthouse-005",
                        imageURL: "https://images.unsplash.com/photo-1569152811536-fb47aced8409?w=4000&h=2000&fit=crop",
                        title: "Cityscape Night View 360°",
                        description: "Breathtaking nighttime view of Colombo city lights from the penthouse windows",
                        roomType: .outdoor,
                        captureDate: currentTime.addingTimeInterval(-259200),
                        isAREnabled: true
                    )
                ],
                walkthroughVideoURL: nil
            ),
            
            AuctionProperty(
                sellerId: userId,
                sellerName: userName,
                title: "Commercial Building in Dehiwala",
                description: "Prime commercial property with excellent visibility and foot traffic. Perfect for retail, office space, or mixed-use development. Includes ample parking, modern infrastructure, and flexible floor layouts for multiple business types.",
                startingPrice: 3250000,
                currentBid: 3400000,
                highestBidderId: "bidder-011",
                highestBidderName: "James Kumar",
                images: [
                    "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800",
                    "https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=800",
                    "https://images.unsplash.com/photo-1577412647305-991150c7d163?w=800"
                ],
                videos: [],
                arModelURL: nil,
                address: PropertyAddress(
                    street: "78 Galle Road",
                    city: "Dehiwala",
                    state: "Western Province",
                    postalCode: "10350",
                    country: "Sri Lanka"
                ),
                location: GeoPoint(latitude: 6.8561, longitude: 79.8655),
                features: PropertyFeatures(
                    bedrooms: 0,
                    bathrooms: 4,
                    area: 3200,
                    yearBuilt: 2019,
                    parkingSpaces: 12,
                    hasGarden: false,
                    hasPool: false,
                    hasGym: false,
                    floorNumber: nil,
                    totalFloors: 3,
                    propertyType: "Commercial"
                ),
                auctionStartTime: currentTime.addingTimeInterval(-10800), // Started 3 hours ago
                auctionEndTime: currentTime.addingTimeInterval(-1800), // Ended 30 minutes ago
                auctionDuration: .threeHours,
                status: AuctionStatus.ended,
                category: .commercial,
                bidHistory: [
                    BidEntry(bidderId: "bidder-011", bidderName: "James Kumar", amount: 3400000, timestamp: currentTime.addingTimeInterval(-3600)),
                    BidEntry(bidderId: "bidder-012", bidderName: "Jennifer Lee", amount: 3350000, timestamp: currentTime.addingTimeInterval(-4800)),
                    BidEntry(bidderId: "bidder-013", bidderName: "Thomas Brown", amount: 3300000, timestamp: currentTime.addingTimeInterval(-7200))
                ],
                watchlistUsers: ["user-010", "user-015", "user-016"],
                createdAt: currentTime.addingTimeInterval(-172800),
                updatedAt: currentTime.addingTimeInterval(-1800),
                winnerId: "bidder-011",
                winnerName: "James Kumar",
                finalPrice: 3400000,
                paymentStatus: .completed,
                transactionId: "txn-384756299",
                panoramicImages: [
                    PanoramicImage(
                        id: "pano-commercial-001",
                        imageURL: "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=4000&h=2000&fit=crop",
                        title: "Commercial Lobby 360°",
                        description: "Modern reception area with marble floors and contemporary design",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-172800),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-commercial-002",
                        imageURL: "https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=4000&h=2000&fit=crop",
                        title: "Office Space 360°",
                        description: "Open-concept office area with natural lighting and flexible workstations",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-172800),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-commercial-003",
                        imageURL: "https://images.unsplash.com/photo-1606857521015-7f9fcf423740?w=4000&h=2000&fit=crop",
                        title: "Street View 360°",
                        description: "Busy Galle Road frontage showing the building's prime location and visibility",
                        roomType: .outdoor,
                        captureDate: currentTime.addingTimeInterval(-172800),
                        isAREnabled: true
                    )
                ],
                walkthroughVideoURL: nil
            ),
            
            AuctionProperty(
                sellerId: userId,
                sellerName: userName,
                title: "Mountain Retreat in Nuwara Eliya",
                description: "Secluded mountain retreat with breathtaking views of Sri Lanka's central highlands. This property includes 2 acres of landscaped gardens, a cozy cottage with traditional architecture, and modern comforts. Perfect for nature lovers and those seeking tranquility.",
                startingPrice: 2800000,
                currentBid: 2800000,
                highestBidderId: nil,
                highestBidderName: nil,
                images: [
                    "https://images.unsplash.com/photo-1518684079-3c830dcef090?w=800",
                    "https://images.unsplash.com/photo-1505903653889-3807cf8f2d44?w=800",
                    "https://images.unsplash.com/photo-1501389540257-dd4e195be3fe?w=800"
                ],
                videos: [],
                arModelURL: nil,
                address: PropertyAddress(
                    street: "Highland Estate, Shanthipura Road",
                    city: "Nuwara Eliya",
                    state: "Central Province",
                    postalCode: "22200",
                    country: "Sri Lanka"
                ),
                location: GeoPoint(latitude: 6.9497, longitude: 80.7891),
                features: PropertyFeatures(
                    bedrooms: 3,
                    bathrooms: 2,
                    area: 1800,
                    yearBuilt: 2005,
                    parkingSpaces: 2,
                    hasGarden: true,
                    hasPool: false,
                    hasGym: false,
                    floorNumber: nil,
                    totalFloors: 2,
                    propertyType: "House"
                ),
                auctionStartTime: currentTime.addingTimeInterval(172800), // Starts in 2 days
                auctionEndTime: currentTime.addingTimeInterval(259200), // Ends in 3 days
                auctionDuration: .oneDay,
                status: AuctionStatus.upcoming,
                category: .residential,
                bidHistory: [],
                watchlistUsers: ["user-005", "user-017"],
                createdAt: currentTime.addingTimeInterval(-86400),
                updatedAt: currentTime.addingTimeInterval(-43200),
                winnerId: nil,
                winnerName: nil,
                finalPrice: nil,
                paymentStatus: nil,
                transactionId: nil,
                panoramicImages: [
                    PanoramicImage(
                        id: "pano-mountain-001",
                        imageURL: "https://images.unsplash.com/photo-1502784444187-359ac186c5bb?w=4000&h=2000&fit=crop",
                        title: "Mountain View 360°",
                        description: "Panoramic view of the tea plantations and misty mountains from the property",
                        roomType: .outdoor,
                        captureDate: currentTime.addingTimeInterval(-86400),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-mountain-002",
                        imageURL: "https://images.unsplash.com/photo-1534512756722-1a2fb8e66d1e?w=4000&h=2000&fit=crop",
                        title: "Cottage Interior 360°",
                        description: "Cozy living area with stone fireplace and exposed wooden beams",
                        roomType: .livingRoom,
                        captureDate: currentTime.addingTimeInterval(-86400),
                        isAREnabled: true
                    ),
                    PanoramicImage(
                        id: "pano-mountain-003",
                        imageURL: "https://images.unsplash.com/photo-1486915309851-b0cc1f8a0084?w=4000&h=2000&fit=crop",
                        title: "Garden View 360°",
                        description: "Beautifully landscaped gardens with native flora and mountain backdrop",
                        roomType: .garden,
                        captureDate: currentTime.addingTimeInterval(-86400),
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
        //  Implement real-time auction updates after restoration
        print("Started listening to auction updates for property: \(propertyId)")
    }
    
    func stopListeningToAuctionUpdates() {
        // Implement stopping auction updates after restoration
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
            status: AuctionStatus.upcoming,
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
    
    // Notification Methods
    private func sendOutbidNotifications(propertyId: String, newBidAmount: Double, newBidderName: String) async {
        do {
            // Get the property title
            let propertySnapshot = try await db.collection("auction_properties").document(propertyId).getDocument()
            guard let propertyData = propertySnapshot.data(),
                  let propertyTitle = propertyData["title"] as? String else {
                print(" Could not get property title for notifications")
                return
            }
            
            // Get all users who have bid on this property (excluding the new bidder)
            let bidsSnapshot = try await db.collection("user_bids")
                .whereField("propertyId", isEqualTo: propertyId)
                .whereField("status", isEqualTo: "active")
                .getDocuments()
            
            var outbidUsers = Set<String>()
            
            for document in bidsSnapshot.documents {
                if let userId = document.data()["userId"] as? String,
                   userId != currentUserId { // Don't notify the bidder who just placed the bid
                    outbidUsers.insert(userId)
                }
            }
            
            // Send notification to each outbid user
            for userId in outbidUsers {
                await sendOutbidNotification(
                    to: userId,
                    propertyTitle: propertyTitle,
                    propertyId: propertyId,
                    newBidAmount: newBidAmount,
                    newBidderName: newBidderName
                )
            }
            
        } catch {
            print("Error sending outbid notifications: \(error)")
        }
    }
    
    private func sendOutbidNotification(to userId: String, propertyTitle: String, propertyId: String, newBidAmount: Double, newBidderName: String) async {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "You've been outbid!"
        content.body = "\(newBidderName) placed a higher bid of $\(String(format: "%.0f", newBidAmount)) on \(propertyTitle)"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "OUTBID_NOTIFICATION"
        
        // Add custom data
        content.userInfo = [
            "propertyId": propertyId,
            "propertyTitle": propertyTitle,
            "newBidAmount": newBidAmount,
            "type": "outbid"
        ]
        
        let request = UNNotificationRequest(
            identifier: "outbid_\(propertyId)_\(userId)_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(" Failed to send outbid notification: \(error)")
            } else {
                print(" Sent outbid notification to user \(userId) for \(propertyTitle)")
            }
        }
    }
    
    // Cart Management
    func addPropertyToCart(propertyId: String) async throws {
        guard !currentUserId.isEmpty else {
            throw BiddingError.userNotAuthenticated
        }
        
        print("🛒 Adding property \(propertyId) to cart for user \(currentUserId)")
        
        try await db.collection("auction_properties").document(propertyId).updateData([
            "status": "ended",
            "winnerId": currentUserId,
            "paymentStatus": "pending",
            "auctionEndTime": Timestamp()
        ])
        
        // Update local state
        if let index = auctionProperties.firstIndex(where: { $0.id == propertyId }) {
            auctionProperties[index].status = .ended
            auctionProperties[index].winnerId = currentUserId
            auctionProperties[index].paymentStatus = .pending
            auctionProperties[index].auctionEndTime = Date()
        }
        
        print("Property \(propertyId) added to cart successfully")
    }
}

// Error Types
enum BiddingError: LocalizedError {
    case userNotAuthenticated
    case invalidBidAmount
    case dataDecodingFailed
    case auctionNotActive
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to place bids"
        case .invalidBidAmount:
            return "Bid amount must be higher than the current bid"
        case .auctionNotActive:
            return "Auction is not currently active"
        case .dataDecodingFailed:
            return "Failed to decode auction data"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
