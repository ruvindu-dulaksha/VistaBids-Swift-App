//
//  Property.swift
//  VistaBids
//
// Created by Ruvindu Dulaksha on 2025-09-04.
//

import Foundation
import MapKit

// MARK: - Property Model (General property type that can be used for both auctions and sales)
struct Property: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let price: Double
    let bedrooms: Int
    let bathrooms: Int
    let area: String
    let propertyType: PropertyType
    let address: PropertyAddressOld
    let coordinates: PropertyCoordinates
    let images: [String]
    let panoramicImages: [PanoramicImage]
    let walkthroughVideoURL: String?
    let features: [PropertyFeature]
    let seller: PropertySeller
    let createdAt: Date
    var updatedAt: Date
    let isForAuction: Bool
    let isForSale: Bool
    
    // Computed properties
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }
    
    var formattedPrice: String {
        "$\(Int(price).formatted())"
    }
    
    var primaryImage: String {
        images.first ?? ""
    }
    
    var location: String {
        "\(address.city), \(address.state)"
    }
    
    var hasWalkthroughVideo: Bool {
        walkthroughVideoURL != nil && !walkthroughVideoURL!.isEmpty
    }
    
    var hasPanoramicImages: Bool {
        !panoramicImages.isEmpty
    }
    
    var hasARContent: Bool {
        panoramicImages.contains { $0.isAREnabled }
    }
    
    // Sample data for previews and testing
    static var example: Property {
        Property(
            id: "prop1",
            title: "Modern Villa with Ocean View",
            description: "Stunning 4-bedroom villa with panoramic ocean views, modern amenities, and spacious outdoor areas perfect for entertaining.",
            price: 450000,
            bedrooms: 4,
            bathrooms: 3,
            area: "2,500 sq ft",
            propertyType: .house,
            address: PropertyAddressOld(
                street: "123 Ocean Drive",
                city: "Colombo",
                state: "Western Province",
                zipCode: "00300",
                country: "Sri Lanka"
            ),
            coordinates: PropertyCoordinates(latitude: 6.9271, longitude: 79.8612),
            images: ["https://images.unsplash.com/photo-1580587771525-78b9dba3b914"],
            panoramicImages: [
                PanoramicImage(
                    id: "pano1",
                    imageURL: "",
                    title: "Living Room 360°",
                    description: "Spacious living room with ocean view",
                    roomType: .livingRoom,
                    captureDate: Date(),
                    isAREnabled: true
                )
            ],
            walkthroughVideoURL: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
            features: [
                PropertyFeature(id: "1", name: "Swimming Pool", icon: "figure.pool.swim", category: .exterior),
                PropertyFeature(id: "2", name: "Garage", icon: "car.fill", category: .exterior),
                PropertyFeature(id: "3", name: "Fireplace", icon: "fireplace", category: .interior)
            ],
            seller: PropertySeller(
                id: "seller1",
                name: "John Smith",
                email: "john@example.com",
                phone: "+94771234567",
                profileImageURL: "avatar1",
                rating: 4.8,
                reviewCount: 12,
                verificationStatus: .verified
            ),
            createdAt: Date(),
            updatedAt: Date(),
            isForAuction: false,
            isForSale: true
        )
    }
}