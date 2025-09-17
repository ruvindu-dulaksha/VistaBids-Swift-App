//
//  PropertyService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-08.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class PropertyService: ObservableObject {
    static let shared = PropertyService()
    
    private let db = Firestore.firestore()
    
    @Published var properties: [Property] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        // Load minimal sample data for initialization
        preloadSampleData()
    }
    
    func fetchProperties() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await db.collection("properties").getDocuments()
            let fetchedProperties = snapshot.documents.compactMap { document -> Property? in
                try? document.data(as: Property.self)
            }
            
            await MainActor.run {
                self.properties = fetchedProperties
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func addProperty(_ property: Property, images: [UIImage]) async throws {
        // Upload images first
        var imageURLs: [String] = []
        
        // image upload to Firebase Storage
        //  using placeholder URLs
        imageURLs = property.images
        
        // Create property document
        let propertyData: [String: Any] = [
            "id": property.id,
            "title": property.title,
            "description": property.description,
            "price": property.price,
            "bedrooms": property.bedrooms,
            "bathrooms": property.bathrooms,
            "area": property.area,
            "propertyType": property.propertyType.rawValue,
            "images": imageURLs,
            "isForAuction": property.isForAuction,
            "isForSale": property.isForSale,
            "createdAt": Timestamp(date: property.createdAt),
            "updatedAt": Timestamp(date: property.updatedAt)
        ]
        
        try await db.collection("properties").document(property.id).setData(propertyData)
        
        // Update local array
        properties.append(property)
    }
    
    func updateProperty(_ property: Property) async throws {
        let propertyData: [String: Any] = [
            "title": property.title,
            "description": property.description,
            "price": property.price,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("properties").document(property.id).updateData(propertyData)
        
        // Update local array
        if let index = properties.firstIndex(where: { $0.id == property.id }) {
            properties[index] = property
        }
    }
    
    func deleteProperty(_ property: Property) async throws {
        try await db.collection("properties").document(property.id).delete()
        
        // Remove from local array
        properties.removeAll { $0.id == property.id }
    }
    
    func searchProperties(query: String) -> [Property] {
        return properties.filter { property in
            property.title.lowercased().contains(query.lowercased()) ||
            property.description.lowercased().contains(query.lowercased())
        }
    }
    
    func getPropertiesByType(_ type: PropertyType) -> [Property] {
        return properties.filter { $0.propertyType == type }
    }
    
    func getPropertiesInPriceRange(min: Double, max: Double) -> [Property] {
        return properties.filter { $0.price >= min && $0.price <= max }
    }
    
    func placeBid(on property: Property, amount: Double) async throws {
        
        print("Placing bid of $\(amount) on property: \(property.title)")
    }
    
    func loadSampleData() async {
        await MainActor.run {
            properties = [
                Property.example,
                Property(
                    id: "sample_2",
                    title: "Luxury Beach House",
                    description: "Stunning beachfront property with panoramic ocean views",
                    price: 750000,
                    bedrooms: 5,
                    bathrooms: 4,
                    area: "3,200 sq ft",
                    propertyType: .house,
                    address: PropertyAddressOld(
                        street: "456 Beach Road",
                        city: "Galle",
                        state: "Southern Province",
                        zipCode: "80000",
                        country: "Sri Lanka"
                    ),
                    coordinates: PropertyCoordinates(latitude: 6.0535, longitude: 80.2210),
                    images: ["https://images.unsplash.com/photo-1564013799919-ab600027ffc6"],
                    panoramicImages: [],
                    walkthroughVideoURL: nil,
                    features: [
                        PropertyFeature(id: "1", name: "Ocean View", icon: "water.waves", category: .exterior),
                        PropertyFeature(id: "2", name: "Private Beach", icon: "figure.surfing", category: .exterior)
                    ],
                    seller: PropertySeller(
                        id: "seller_2",
                        name: "Sarah Johnson",
                        email: "sarah@example.com",
                        phone: "+94771234568",
                        profileImageURL: nil,
                        rating: 4.9,
                        reviewCount: 15,
                        verificationStatus: .verified
                    ),
                    createdAt: Date().addingTimeInterval(-86400 * 3),
                    updatedAt: Date(),
                    isForAuction: true,
                    isForSale: false
                )
            ]
        }
    }
    
    private func preloadSampleData() {
        // Called from init - synchronous version
        properties = [Property.example]
    }
}
