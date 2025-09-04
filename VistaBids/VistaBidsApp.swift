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

@main
struct VistaBidsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var userStatsService = UserStatsService.shared
    
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
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(userStatsService)
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
    
    // MARK: - Auto Start Auction
    private func autoStartAuctionOnLaunch() async {
        print("🚀 Starting automatic auction on app launch...")
        
        // Create a new auction property that starts immediately
        let biddingService = BiddingService()
        
        // Create auto-start auction property
        let property = createAutoStartAuctionProperty()
        
        do {
            // Add the property to Firebase
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
            
        } catch {
            print("❌ Error creating auto-start auction: \(error)")
        }
    }
    
    private func createAutoStartAuctionProperty() -> AuctionProperty {
        let now = Date()
        let startTime = now.addingTimeInterval(30) // Start in 30 seconds
        let endTime = now.addingTimeInterval(3600) // End in 1 hour
        
        return AuctionProperty(
            sellerId: "auto_system",
            sellerName: "VistaBids System",
            title: "🏠 Featured Luxury Villa - AUTO AUCTION",
            description: "Stunning modern villa with panoramic ocean views. This automated auction showcases the power of VistaBids real-time bidding system. Features include a spacious living area, modern kitchen, 4 bedrooms, and a beautiful garden. Don't miss this opportunity to own a piece of paradise!",
            startingPrice: 750000,
            currentBid: 750000,
            highestBidderId: nil as String?,
            highestBidderName: nil as String?,
            images: [
                "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800",
                "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800",
                "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800"
            ],
            videos: [],
            arModelURL: nil as String?,
            address: PropertyAddress(
                street: "123 Ocean View Drive",
                city: "Malibu",
                state: "California",
                postalCode: "90265",
                country: "USA"
            ),
            location: GeoPoint(latitude: 34.0259, longitude: -118.7798),
            features: PropertyFeatures(
                bedrooms: 4,
                bathrooms: 3,
                area: 3500,
                yearBuilt: 2020,
                parkingSpaces: 2,
                hasGarden: true,
                hasPool: true,
                hasGym: false,
                floorNumber: nil as Int?,
                totalFloors: 2,
                propertyType: "Villa"
            ),
            auctionStartTime: startTime,
            auctionEndTime: endTime,
            auctionDuration: .thirtyMinutes, // Add the required auctionDuration field
            status: AuctionStatus.upcoming,
            category: PropertyCategory.luxury,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: now,
            updatedAt: now,
            panoramicImages: [
                PanoramicImage(
                    id: UUID().uuidString,
                    imageURL: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800",
                    title: "Living Room View",
                    description: "360° view of the spacious living area",
                    roomType: .livingRoom,
                    captureDate: now,
                    isAREnabled: true
                )
            ],
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
}
