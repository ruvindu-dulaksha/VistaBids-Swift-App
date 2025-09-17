//
//  VistaBidsApp.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-22.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import UserNotifications
import Intents

@main
struct VistaBidsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var userStatsService = UserStatsService.shared
    @StateObject private var translationManager = TranslationManager.shared
    @StateObject private var biddingService = BiddingService()
    
    init() {
        print("🚀 Initializing VistaBids App...")
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")
        
        // Configure Google Sign-In
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            print("✅ Google Sign-In configured with client ID")
        } else {
            print("⚠️ Warning: No Google client ID found in Firebase configuration")
        }
        
        // Initialize SiriKit shortcuts
        if #available(iOS 13.0, *) {
            _ = SiriKitManager.shared
            print("✅ SiriKit Manager initialized")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(userStatsService)
                .environmentObject(translationManager)
                .environmentObject(biddingService)
                .preferredColorScheme(themeManager.currentTheme == .system ? nil : 
                                     (themeManager.isDarkMode ? .dark : .light))
                .task {
                    // Load sample property data first
                    await PropertyService.shared.loadSampleData()
                    print("✅ Sample property data loaded")
                    
                    // Auto-import sale properties if needed
                    await autoImportSalePropertiesIfNeeded()
                    
                    // Load properties from Firestore
                    await MainActor.run {
                        SalePropertyService.shared.loadPropertiesFromFirestore()
                    }
                    
                    // Create sample notifications for demonstration
                    await createSampleNotifications()
                    
                    // Auto-start auction on app launch
                    await autoStartAuctionOnLaunch()
                }
                .onOpenURL { url in
                    print("📱 Handling URL: \(url)")
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
    
    private func autoImportSalePropertiesIfNeeded() async {
        let db = Firestore.firestore()
        
        do {
            // For debugging, let's always re-import fresh data
            print("🗑️ Clearing existing sale_properties collection for fresh import...")
            let snapshot = try await db.collection("sale_properties").getDocuments()
            
            // Delete existing documents
            let batch = db.batch()
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            if !snapshot.documents.isEmpty {
                try await batch.commit()
                print("✅ Deleted \(snapshot.documents.count) existing documents")
            }
            
            // Import fresh sample data
            print("🏠 Importing fresh sale properties sample data...")
            let importer = DataImporter()
            importer.importSampleProperties()
            print("✅ Sample sale properties imported automatically")
            
        } catch {
            print("⚠️ Error in auto-import process: \(error)")
        }
    }
    
    // Auto Start Auction
    private func autoStartAuctionOnLaunch() async {
        print("🚀 Starting automatic auction on app launch...")
        
        do {
            // First, check if we need to clear auction properties
            let db = Firestore.firestore()
            let auctionSnapshot = try await db.collection("auction_properties").getDocuments()
            
           
            if auctionSnapshot.documents.count < 3 {
                print("🏠 Creating varied auction properties using AuctionPropertyDataService...")
                
                // Clear existing auction properties
                let batch = db.batch()
                for document in auctionSnapshot.documents {
                    batch.deleteDocument(document.reference)
                }
                if !auctionSnapshot.documents.isEmpty {
                    try await batch.commit()
                    print("✅ Deleted \(auctionSnapshot.documents.count) existing auction documents")
                }
                
                
                let auctionPropertyDataService = AuctionPropertyDataService()
                try await auctionPropertyDataService.createEnhancedAuctionProperties()
                print("✅ Created varied auction properties with different locations, images, and panoramic views")
                
               
                let property = createAutoStartAuctionProperty()
                
                try await biddingService.createAuctionProperty(
                    title: property.title,
                    description: property.description,
                    startingPrice: property.startingPrice,
                    images: property.images,
                    videos: property.videos,
                    arModelURL: property.arModelURL,
                    address: property.address,
                    location: property.location,
                    features: property.features,
                    auctionStartTime: property.auctionStartTime,
                    auctionEndTime: property.auctionEndTime,
                    auctionDuration: property.auctionDuration,
                    category: property.category,
                    panoramicImages: property.panoramicImages,
                    walkthroughVideoURL: property.walkthroughVideoURL
                )
                
                print("✅ Auto-start auction created successfully!")
                
                // Schedule push notification for auction start
                await scheduleAuctionStartNotification(for: property)
                
                // Show immediate "Let's Bid Now!" notification
                await showLetsBidNowNotification(for: property)
            } else {
                print("✅ Found \(auctionSnapshot.documents.count) existing auction properties, skipping recreation")
            }
            
        } catch {
            print("❌ Error in auction property setup: \(error)")
        }
    }
    
    private func createAutoStartAuctionProperty() -> AuctionProperty {
        let now = Date()
        let startTime = now.addingTimeInterval(30) // Start in 30 seconds
        let endTime = now.addingTimeInterval(3600) // End in 1 hour
        
        let variant = Int.random(in: 0...2)
        
        // Different property templates to choose from
        let propertyTypes = ["Luxury Villa", "Modern Penthouse", "Beach House"]
        let descriptions = [
            "Stunning modern villa with panoramic ocean views. This automated auction showcases the power of VistaBids real-time bidding system. Features include a spacious living area, modern kitchen, 4 bedrooms, and a beautiful garden. Don't miss this opportunity to own a piece of paradise!",
            "Exclusive penthouse in the heart of the city with 360° views, premium finishes, and smart home technology. This auction highlights VistaBids' real-time bidding capabilities. Featuring 3 bedrooms, a gourmet kitchen, and a private rooftop terrace.",
            "Charming beachfront property with direct access to pristine sands and crystal clear waters. This special auction demonstrates VistaBids' live auction technology. Includes 4 bedrooms, an open plan living area, and breathtaking sunset views."
        ]
        
        // Different image sets
        let imageSets = [
            [
                "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800",
                "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800", 
                "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800"
            ],
            [
                "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
                "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800",
                "https://images.unsplash.com/photo-1593696140826-c58b021acf8b?w=800"
            ],
            [
                "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800",
                "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=800",
                "https://images.unsplash.com/photo-1513584684374-8bab748fbf90?w=800"
            ]
        ]
        
        // Different panoramic image sets
        let panoramicSets = [
            [
                PanoramicImage(
                    id: UUID().uuidString,
                    imageURL: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1920&h=960&fit=crop",
                    title: "Living Room View",
                    description: "360° view of the spacious living area",
                    roomType: .livingRoom,
                    captureDate: now,
                    isAREnabled: true
                ),
                PanoramicImage(
                    id: UUID().uuidString,
                    imageURL: "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=1920&h=960&fit=crop",
                    title: "Exterior View",
                    description: "360° view of the property exterior",
                    roomType: .exterior,
                    captureDate: now,
                    isAREnabled: true
                )
            ],
            [
                PanoramicImage(
                    id: UUID().uuidString,
                    imageURL: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1920&h=960&fit=crop",
                    title: "Kitchen View",
                    description: "360° view of the gourmet kitchen",
                    roomType: .kitchen,
                    captureDate: now,
                    isAREnabled: true
                ),
                PanoramicImage(
                    id: UUID().uuidString,
                    imageURL: "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=1920&h=960&fit=crop",
                    title: "Master Bedroom",
                    description: "360° view of the master bedroom",
                    roomType: .bedroom,
                    captureDate: now,
                    isAREnabled: true
                )
            ],
            [
                PanoramicImage(
                    id: UUID().uuidString,
                    imageURL: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1920&h=960&fit=crop",
                    title: "Beach View",
                    description: "360° panoramic view of the beach",
                    roomType: .exterior,
                    captureDate: now,
                    isAREnabled: true
                ),
                PanoramicImage(
                    id: UUID().uuidString,
                    imageURL: "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=1920&h=960&fit=crop",
                    title: "Balcony View",
                    description: "360° view from the balcony",
                    roomType: .balcony,
                    captureDate: now,
                    isAREnabled: true
                )
            ]
        ]
        
        // Different locations
        let locations = [
            (city: "Malibu", state: "California", lat: 34.0259, lng: -118.7798),
            (city: "Manhattan", state: "New York", lat: 40.7831, lng: -73.9712),
            (city: "Miami Beach", state: "Florida", lat: 25.7907, lng: -80.1300)
        ]
        
        // Create the property using the random variant
        return AuctionProperty(
            sellerId: "auto_system",
            sellerName: "VistaBids System",
            title: "🔥 Featured \(propertyTypes[variant]) - LIVE AUCTION",
            description: descriptions[variant],
            startingPrice: Double([750000, 680000, 820000][variant]),
            currentBid: Double([750000, 680000, 820000][variant]),
            highestBidderId: nil as String?,
            highestBidderName: nil as String?,
            images: imageSets[variant],
            videos: [],
            arModelURL: nil as String?,
            address: PropertyAddress(
                street: "\(100 + variant * 23) \(["Ocean View", "Central Park", "Shoreline"][variant]) Drive",
                city: locations[variant].city,
                state: locations[variant].state,
                postalCode: ["90265", "10021", "33139"][variant],
                country: "USA"
            ),
            location: GeoPoint(latitude: locations[variant].lat, longitude: locations[variant].lng),
            features: PropertyFeatures(
                bedrooms: [4, 3, 4][variant],
                bathrooms: [3, 3, 4][variant],
                area: [3500, 2800, 3200][variant],
                yearBuilt: 2020 + variant,
                parkingSpaces: [2, 1, 2][variant],
                hasGarden: [true, false, true][variant],
                hasPool: [true, false, true][variant],
                hasGym: [false, true, false][variant],
                floorNumber: variant == 1 ? 15 : nil,
                totalFloors: variant == 1 ? 30 : nil,
                propertyType: ["Villa", "Penthouse", "Beach House"][variant]
            ),
            auctionStartTime: startTime,
            auctionEndTime: endTime,
            auctionDuration: .thirtyMinutes,
            status: AuctionStatus.upcoming,
            category: [PropertyCategory.luxury, PropertyCategory.luxury, PropertyCategory.residential][variant],
            bidHistory: [],
            watchlistUsers: [],
            createdAt: now,
            updatedAt: now,
            panoramicImages: panoramicSets[variant],
            walkthroughVideoURL: nil as String?
        )
    }
    
    private func scheduleAuctionStartNotification(for property: AuctionProperty) async {
        let notificationService = NotificationService.shared
        await notificationService.sendNotificationToAllUsers(
            title: "🔥 LIVE AUCTION STARTING!",
            body: "\(property.title) auction is starting now! Starting bid: $\(String(format: "%.0f", property.startingPrice))",
            type: .newBidding,
            data: [
                "propertyId": property.id ?? "",
                "action": "start_bidding",
                "startingPrice": String(format: "%.0f", property.startingPrice)
            ],
            priority: .high
        )
    }
    
    private func showLetsBidNowNotification(for property: AuctionProperty) async {
        // Schedule local notification for immediate display
        let content = UNMutableNotificationContent()
        content.title = "🎯 Let's Bid Now!"
        content.body = "\(property.title) is ready for bidding! Tap to start bidding and win this amazing property!"
        content.sound = .default
        content.badge = 1
        
        // Add action buttons
        let bidAction = UNNotificationAction(
            identifier: "BID_NOW",
            title: "🔥 Bid Now!",
            options: [.foreground]
        )
        let viewAction = UNNotificationAction(
            identifier: "VIEW_PROPERTY",
            title: "👀 View Details",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "AUCTION_CATEGORY",
            actions: [bidAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "AUCTION_CATEGORY"
        
        // Add custom data
        content.userInfo = [
            "propertyId": property.id ?? "",
            "propertyTitle": property.title,
            "startingPrice": property.startingPrice,
            "auctionType": "auto_start"
        ]
        
        // Schedule notification to appear in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "auto_auction_\(property.id ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ 'Let's Bid Now!' notification scheduled")
        } catch {
            print("❌ Error scheduling notification: \(error)")
        }
    }
    
    //Sample Notifications
    private func createSampleNotifications() async {
        print("📱 Creating sample notifications...")
        // Add a small delay to ensure authentication is complete
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await NotificationService.shared.createSampleNotifications()
    }
}
