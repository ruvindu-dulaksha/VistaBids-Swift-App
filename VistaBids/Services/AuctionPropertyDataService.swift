//
//  AuctionPropertyDataService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-19.
//  Service for creating and managing auction property data with Firebase integration
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine
import UIKit

@MainActor
class AuctionPropertyDataService: ObservableObject {
    
    // MARK: - Dependencies
    private let db = Firestore.firestore()
    private let imageUploadService = ImageUploadService()
    
    // MARK: - Published Properties
    @Published var isCreatingProperties = false
    @Published var creationProgress: Double = 0.0
    @Published var lastError: Error?
    @Published var createdPropertiesCount = 0
    
    // MARK: - Property Templates
    private let propertyTemplates: [(
        title: String,
        description: String,
        startingPrice: Double,
        bedrooms: Int,
        bathrooms: Int,
        area: Double,
        city: String,
        state: String,
        propertyType: String,
        category: PropertyCategory,
        features: [String: Any]
    )] = [
        (
            title: "Luxury Oceanfront Villa",
            description: "Stunning 5-bedroom villa with panoramic ocean views, private beach access, infinity pool, and contemporary design. Perfect for luxury living with world-class amenities.",
            startingPrice: 750000.0,
            bedrooms: 5,
            bathrooms: 4,
            area: 3500.0,
            city: "Galle",
            state: "Southern Province",
            propertyType: "Villa",
            category: .luxury,
            features: [
                "hasPool": true,
                "hasGarden": true,
                "hasGym": true,
                "beachAccess": true,
                "smartHome": true
            ]
        ),
        (
            title: "Modern Downtown Penthouse",
            description: "Exclusive penthouse apartment in the heart of Colombo with 360° city views, rooftop terrace, premium finishes, and smart home technology.",
            startingPrice: 580000.0,
            bedrooms: 3,
            bathrooms: 3,
            area: 2200.0,
            city: "Colombo",
            state: "Western Province",
            propertyType: "Apartment",
            category: .luxury,
            features: [
                "hasPool": false,
                "hasGarden": false,
                "hasGym": true,
                "rooftopTerrace": true,
                "smartHome": true
            ]
        ),
        (
            title: "Heritage Colonial Mansion",
            description: "Beautifully restored colonial mansion with original architecture, sprawling gardens, servant quarters, and rich historical significance. A rare investment opportunity.",
            startingPrice: 650000.0,
            bedrooms: 6,
            bathrooms: 5,
            area: 4200.0,
            city: "Kandy",
            state: "Central Province",
            propertyType: "House",
            category: .investment,
            features: [
                "hasPool": false,
                "hasGarden": true,
                "hasGym": false,
                "heritage": true,
                "servantQuarters": true
            ]
        ),
        (
            title: "Contemporary Family Home",
            description: "Brand new 4-bedroom family home in a prestigious gated community with modern amenities, children's playground, and 24/7 security.",
            startingPrice: 420000.0,
            bedrooms: 4,
            bathrooms: 3,
            area: 2800.0,
            city: "Nugegoda",
            state: "Western Province",
            propertyType: "House",
            category: .residential,
            features: [
                "hasPool": true,
                "hasGarden": true,
                "hasGym": false,
                "gatedCommunity": true,
                "playground": true
            ]
        ),
        (
            title: "Eco-Friendly Sustainable Home",
            description: "Award-winning eco-friendly home with solar panels, rainwater harvesting, organic garden, and carbon-neutral design. Perfect for environmentally conscious buyers.",
            startingPrice: 380000.0,
            bedrooms: 3,
            bathrooms: 2,
            area: 2000.0,
            city: "Matara",
            state: "Southern Province",
            propertyType: "House",
            category: .residential,
            features: [
                "hasPool": false,
                "hasGarden": true,
                "hasGym": false,
                "solarPanels": true,
                "rainwaterHarvesting": true,
                "organicGarden": true
            ]
        ),
        (
            title: "Commercial Office Complex",
            description: "Prime commercial property with modern office spaces, underground parking, conference facilities, and excellent connectivity to major business districts.",
            startingPrice: 950000.0,
            bedrooms: 0,
            bathrooms: 8,
            area: 5000.0,
            city: "Colombo",
            state: "Western Province",
            propertyType: "Commercial",
            category: .commercial,
            features: [
                "hasPool": false,
                "hasGarden": false,
                "hasGym": false,
                "conferenceRooms": true,
                "undergroundParking": true,
                "elevators": true
            ]
        ),
        (
            title: "Beachfront Resort Property",
            description: "Established beachfront resort with 20 rooms, restaurant, spa facilities, and direct beach access. Excellent income-generating investment opportunity.",
            startingPrice: 1200000.0,
            bedrooms: 20,
            bathrooms: 25,
            area: 8000.0,
            city: "Bentota",
            state: "Southern Province",
            propertyType: "Resort",
            category: .commercial,
            features: [
                "hasPool": true,
                "hasGarden": true,
                "hasGym": true,
                "restaurant": true,
                "spa": true,
                "beachAccess": true
            ]
        ),
        (
            title: "Mountain View Tea Estate",
            description: "Historic tea plantation with colonial bungalow, processing facilities, and stunning mountain views. Includes 50 acres of productive tea cultivation.",
            startingPrice: 850000.0,
            bedrooms: 4,
            bathrooms: 3,
            area: 3000.0,
            city: "Nuwara Eliya",
            state: "Central Province",
            propertyType: "Estate",
            category: .investment,
            features: [
                "hasPool": false,
                "hasGarden": true,
                "hasGym": false,
                "teaPlantation": true,
                "mountainView": true,
                "colonial": true
            ]
        )
    ]
    
    // MARK: - High-Quality Sample Images
    private let sampleImageSets: [[String]] = [
        // Luxury Oceanfront Villa
        [
            "https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1582063289852-62e3ba2747f8?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1520637836862-4d197d17c38a?w=800&h=600&fit=crop"
        ],
        // Modern Downtown Penthouse
        [
            "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1567767292278-a4f21aa2d36e?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1493663284031-b7e3aae4c4ff?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&h=600&fit=crop"
        ],
        // Heritage Colonial Mansion
        [
            "https://images.unsplash.com/photo-1601084881623-936d8d40bc98?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1593696140826-c58b021acf8b?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1571055107559-3e67626fa8be?w=800&h=600&fit=crop"
        ],
        // Contemporary Family Home
        [
            "https://images.unsplash.com/photo-1502005229762-cf1b2da0513e?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1523712999610-f77fbcfc3843?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1560184897-ae75f418493e?w=800&h=600&fit=crop"
        ],
        // Eco-Friendly Sustainable Home
        [
            "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1515263487990-61b07816b324?w=800&h=600&fit=crop"
        ],
        // Commercial Office Complex
        [
            "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&h=600&fit=crop"
        ],
        // Beachfront Resort Property
        [
            "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&h=600&fit=crop"
        ],
        // Mountain View Tea Estate
        [
            "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1416331108676-a22ccb276e35?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800&h=600&fit=crop",
            "https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?w=800&h=600&fit=crop"
        ]
    ]
    
    // MARK: - Panoramic Image URLs
    private let panoramicImageSets: [[String]] = [
        // Luxury Villa panoramic images
        [
            "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1920&h=960&fit=crop",
            "https://images.unsplash.com/photo-1571055107559-3e67626fa8be?w=1920&h=960&fit=crop"
        ],
        // Penthouse panoramic images
        [
            "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1920&h=960&fit=crop",
            "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=1920&h=960&fit=crop"
        ],
        // Colonial Mansion panoramic images
        [
            "https://images.unsplash.com/photo-1560184897-ae75f418493e?w=1920&h=960&fit=crop",
            "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1920&h=960&fit=crop"
        ],
        // Family Home panoramic images
        [
            "https://images.unsplash.com/photo-1515263487990-61b07816b324?w=1920&h=960&fit=crop"
        ],
        // Eco Home panoramic images
        [
            "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1920&h=960&fit=crop"
        ],
        // Office Complex panoramic images
        [
            "https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=1920&h=960&fit=crop"
        ],
        // Resort panoramic images
        [
            "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1920&h=960&fit=crop",
            "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=1920&h=960&fit=crop"
        ],
        // Tea Estate panoramic images
        [
            "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=1920&h=960&fit=crop"
        ]
    ]
    
    // MARK: - Public Methods
    
    /// Create a comprehensive set of auction properties with Firebase storage
    func createEnhancedAuctionProperties() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuctionPropertyError.notAuthenticated
        }
        
        isCreatingProperties = true
        creationProgress = 0.0
        createdPropertiesCount = 0
        
        defer {
            isCreatingProperties = false
            creationProgress = 0.0
        }
        
        let totalProperties = propertyTemplates.count
        
        for (index, template) in propertyTemplates.enumerated() {
            do {
                print("🏠 Creating property \(index + 1)/\(totalProperties): \(template.title)")
                
                // Update progress
                await MainActor.run {
                    creationProgress = Double(index) / Double(totalProperties)
                }
                
                try await createSingleAuctionProperty(
                    template: template,
                    imageSet: sampleImageSets[safe: index] ?? sampleImageSets[0],
                    panoramicSet: panoramicImageSets[safe: index] ?? [],
                    propertyIndex: index,
                    user: user
                )
                
                await MainActor.run {
                    createdPropertiesCount += 1
                }
                
                print("✅ Successfully created property: \(template.title)")
                
                // Small delay to prevent overwhelming Firebase
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
            } catch {
                print("❌ Failed to create property \(template.title): \(error)")
                lastError = error
                // Continue with other properties instead of failing completely
            }
        }
        
        await MainActor.run {
            creationProgress = 1.0
        }
        
        print("🎉 Completed creating \(createdPropertiesCount)/\(totalProperties) auction properties")
    }
    
    /// Create a custom auction property with Firebase storage
    func createCustomAuctionProperty(
        title: String,
        description: String,
        startingPrice: Double,
        propertyImages: [UIImage],
        panoramicImages: [UIImage],
        address: PropertyAddress,
        features: PropertyFeatures,
        auctionStartTime: Date,
        auctionEndTime: Date,
        category: PropertyCategory
    ) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AuctionPropertyError.notAuthenticated
        }
        
        isCreatingProperties = true
        creationProgress = 0.0
        
        defer {
            isCreatingProperties = false
        }
        
        // Generate unique property ID
        let propertyId = UUID().uuidString
        
        // Upload property images
        await MainActor.run { creationProgress = 0.2 }
        let imageUrls = try await imageUploadService.uploadPropertyImages(propertyImages, propertyId: propertyId)
        
        // Upload panoramic images
        await MainActor.run { creationProgress = 0.6 }
        var panoramicImageArray: [PanoramicImage] = []
        
        for (index, image) in panoramicImages.enumerated() {
            let imageUrl = try await imageUploadService.uploadPanoramicImage(
                image,
                propertyId: propertyId,
                roomType: index == 0 ? .livingRoom : .bedroom
            )
            
            panoramicImageArray.append(PanoramicImage(
                id: UUID().uuidString,
                imageURL: imageUrl,
                title: "360° View \(index + 1)",
                description: "Panoramic view of the property",
                roomType: index == 0 ? .livingRoom : .bedroom,
                captureDate: Date(),
                isAREnabled: true
            ))
        }
        
        // Create location with some randomization
        let baseLocation = GeoPoint(latitude: 6.9271, longitude: 79.8612)
        let location = GeoPoint(
            latitude: baseLocation.latitude + Double.random(in: -0.1...0.1),
            longitude: baseLocation.longitude + Double.random(in: -0.1...0.1)
        )
        
        // Create auction property
        await MainActor.run { creationProgress = 0.8 }
        let property = AuctionProperty(
            sellerId: user.uid,
            sellerName: user.displayName ?? "Property Owner",
            title: title,
            description: description,
            startingPrice: startingPrice,
            currentBid: startingPrice,
            highestBidderId: nil,
            highestBidderName: nil,
            images: imageUrls,
            videos: [],
            arModelURL: nil,
            address: address,
            location: location,
            features: features,
            auctionStartTime: auctionStartTime,
            auctionEndTime: auctionEndTime,
            auctionDuration: .thirtyMinutes, // Default duration
            status: auctionStartTime <= Date() ? .active : .upcoming,
            category: category,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: Date(),
            updatedAt: Date(),
            panoramicImages: panoramicImageArray,
            walkthroughVideoURL: nil
        )
        
        // Store in Firebase
        let documentRef = try await db.collection("auction_properties").addDocument(from: property)
        
        await MainActor.run { creationProgress = 1.0 }
        
        print("✅ Custom auction property created with ID: \(documentRef.documentID)")
        return documentRef.documentID
    }
    
    // MARK: - Private Methods
    
    private func createSingleAuctionProperty(
        template: (
            title: String,
            description: String,
            startingPrice: Double,
            bedrooms: Int,
            bathrooms: Int,
            area: Double,
            city: String,
            state: String,
            propertyType: String,
            category: PropertyCategory,
            features: [String: Any]
        ),
        imageSet: [String],
        panoramicSet: [String],
        propertyIndex: Int,
        user: User
    ) async throws {
        
        // Create unique property ID
        let propertyId = "sample_\(propertyIndex)_\(UUID().uuidString.prefix(8))"
        
        // Create panoramic images array
        var panoramicImages: [PanoramicImage] = []
        
        for (index, panoramicUrl) in panoramicSet.enumerated() {
            let roomTypes: [PanoramicImage.RoomType] = [.livingRoom, .bedroom, .kitchen, .exterior]
            let roomType = roomTypes[index % roomTypes.count]
            
            panoramicImages.append(PanoramicImage(
                id: UUID().uuidString,
                imageURL: panoramicUrl,
                title: "\(roomType.displayName) 360°",
                description: "Panoramic view of the \(roomType.displayName.lowercased())",
                roomType: roomType,
                captureDate: Date(),
                isAREnabled: true
            ))
        }
        
        // Create auction start time (staggered for variety)
        let hoursFromNow = Double((propertyIndex % 4) + 1) // 1-4 hours from now
        let auctionStartTime = Date().addingTimeInterval(hoursFromNow * 3600)
        let auctionEndTime = auctionStartTime.addingTimeInterval(259200) // 3 days duration
        
        // Create location with geographic diversity
        let locationVariations = [
            GeoPoint(latitude: 6.9271, longitude: 79.8612), // Colombo
            GeoPoint(latitude: 7.2906, longitude: 80.6337), // Kandy
            GeoPoint(latitude: 6.0535, longitude: 80.2210), // Galle
            GeoPoint(latitude: 6.8345, longitude: 79.9085), // Nugegoda
            GeoPoint(latitude: 5.9485, longitude: 80.5353), // Matara
            GeoPoint(latitude: 6.9319, longitude: 79.8478), // Colombo CBD
            GeoPoint(latitude: 6.2088, longitude: 81.1210), // Bentota
            GeoPoint(latitude: 6.9497, longitude: 80.7891)  // Nuwara Eliya
        ]
        
        let location = locationVariations[propertyIndex % locationVariations.count]
        
        // Create auction property
        let property = AuctionProperty(
            sellerId: user.uid,
            sellerName: user.displayName ?? "VistaBids Admin",
            title: template.title,
            description: template.description,
            startingPrice: template.startingPrice,
            currentBid: template.startingPrice,
            highestBidderId: nil,
            highestBidderName: nil,
            images: imageSet,
            videos: propertyIndex == 1 ? ["https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"] : [],
            arModelURL: nil,
            address: PropertyAddress(
                street: "\(100 + propertyIndex * 25) \(template.propertyType) Street",
                city: template.city,
                state: template.state,
                postalCode: String(format: "%05d", 10000 + propertyIndex * 100),
                country: "Sri Lanka"
            ),
            location: location,
            features: PropertyFeatures(
                bedrooms: template.bedrooms,
                bathrooms: template.bathrooms,
                area: template.area,
                yearBuilt: 2020 - (propertyIndex % 5), // Variety in build years
                parkingSpaces: template.bedrooms > 3 ? 2 : 1,
                hasGarden: template.features["hasGarden"] as? Bool ?? false,
                hasPool: template.features["hasPool"] as? Bool ?? false,
                hasGym: template.features["hasGym"] as? Bool ?? false,
                floorNumber: template.propertyType == "Apartment" ? propertyIndex % 10 + 1 : nil,
                totalFloors: template.propertyType == "Apartment" ? 15 : nil,
                propertyType: template.propertyType
            ),
            auctionStartTime: auctionStartTime,
            auctionEndTime: auctionEndTime,
            auctionDuration: .thirtyMinutes, // Default duration
            status: auctionStartTime <= Date() ? .active : .upcoming,
            category: template.category,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: Date(),
            updatedAt: Date(),
            panoramicImages: panoramicImages,
            walkthroughVideoURL: propertyIndex == 2 ? "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4" : nil
        )
        
        // Store in Firebase Firestore
        try await db.collection("auction_properties").addDocument(from: property)
        
        // Log success
        print("📝 Stored in Firestore: \(property.title)")
    }
}

// MARK: - Array Safe Subscript Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Error Types
enum AuctionPropertyError: LocalizedError {
    case notAuthenticated
    case imageUploadFailed
    case firestoreError(Error)
    case invalidPropertyData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be authenticated to create auction properties"
        case .imageUploadFailed:
            return "Failed to upload property images"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        case .invalidPropertyData:
            return "Invalid property data provided"
        }
    }
}
