//
//  SaleProperty.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-08-12.
//

import Foundation
import MapKit

// MARK: - Sale Property Model (for direct sales, not auctions)
struct SaleProperty: Identifiable, Codable {
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
    let availableFrom: Date
    let createdAt: Date
    var updatedAt: Date
    let status: SalePropertyStatus
    let isNew: Bool
    
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
}

// MARK: - Sale Property Status
enum SalePropertyStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case active = "active"
    case sold = "sold"
    case withdrawn = "withdrawn"
    case underOffer = "under_offer"
    
    var displayText: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "For Sale"
        case .sold: return "Sold"
        case .withdrawn: return "Withdrawn"
        case .underOffer: return "Under Offer"
        }
    }
    
    var color: String {
        switch self {
        case .draft: return "gray"
        case .active: return "green"
        case .sold: return "blue"
        case .withdrawn: return "orange"
        case .underOffer: return "yellow"
        }
    }
}

// MARK: - Property Search Helper
extension SaleProperty {
    static func filter(properties: [SaleProperty], options: AdvancedSearchOptions, searchText: String) -> [SaleProperty] {
        var filteredProperties = properties
        
        // Text search
        if !searchText.isEmpty {
            filteredProperties = filteredProperties.filter { property in
                property.title.lowercased().contains(searchText.lowercased()) ||
                property.description.lowercased().contains(searchText.lowercased()) ||
                property.address.city.lowercased().contains(searchText.lowercased()) ||
                property.propertyType.displayName.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply advanced filters if enabled
        if options.filtersEnabled {
            // Price range filter
            if let minPrice = options.minPrice {
                filteredProperties = filteredProperties.filter { $0.price >= minPrice }
            }
            
            if let maxPrice = options.maxPrice {
                filteredProperties = filteredProperties.filter { $0.price <= maxPrice }
            }
            
            // Bedrooms filter
            if let minBedrooms = options.minBedrooms {
                filteredProperties = filteredProperties.filter { $0.bedrooms >= minBedrooms }
            }
            
            // Bathrooms filter
            if let minBathrooms = options.minBathrooms {
                filteredProperties = filteredProperties.filter { $0.bathrooms >= minBathrooms }
            }
            
            // Property type filter
            if !options.propertyType.isEmpty {
                filteredProperties = filteredProperties.filter { 
                    $0.propertyType.displayName.lowercased() == options.propertyType.lowercased()
                }
            }
            
            // Status filter
            if let status = options.status {
                filteredProperties = filteredProperties.filter { $0.status == status }
            }
        }
        
        return filteredProperties
    }
    
    func matchesSearch(searchText: String) -> Bool {
        return title.lowercased().contains(searchText.lowercased()) ||
            description.lowercased().contains(searchText.lowercased()) ||
            address.city.lowercased().contains(searchText.lowercased()) ||
            propertyType.displayName.lowercased().contains(searchText.lowercased())
    }
    
    // Sample data for previews and testing
    static var example: SaleProperty {
        SaleProperty(
            id: "sp1",
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
                PropertyFeature(id: "2", name: "Garage", icon: "car.garage", category: .exterior),
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
            availableFrom: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            status: .active,
            isNew: true
        )
    }
}


