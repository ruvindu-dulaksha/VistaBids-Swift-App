//
//  SalePropertyService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-22.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class SalePropertyService: ObservableObject {
    static let shared = SalePropertyService()
    
    @Published var properties: [SaleProperty] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let db = Firestore.firestore()
    
    private init() {
        NSLog("🏠 SalePropertyService: Initializing...")
    }
    
    func loadPropertiesFromFirestore() {
        NSLog("🏠 SalePropertyService: Starting loadPropertiesFromFirestore()")
        
        // Call the async function from a Task
        Task {
            await fetchProperties()
        }
    }
    
    func fetchProperties() async {
        NSLog("🏠 SalePropertyService: Starting fetchProperties() - async method")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Check authentication first
            if let currentUser = Auth.auth().currentUser {
                NSLog("🏠 SalePropertyService: User authenticated - UID: \(currentUser.uid)")
            } else {
                NSLog("🏠 SalePropertyService: No authenticated user - proceeding anyway for public data")
            }
            
            NSLog("🏠 SalePropertyService: Querying Firestore collection 'sale_properties'...")
            
            // Setup more resilient query with retry
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            let localDB = Firestore.firestore()
            localDB.settings = settings
            
            // Retry logic for fetching documents
            var retryCount = 0
            var snapshot: QuerySnapshot?
            var lastError: Error?
            
            while retryCount < 3 && snapshot == nil {
                do {
                    snapshot = try await localDB.collection("sale_properties").getDocuments()
                    NSLog("🏠 SalePropertyService: Query completed on attempt \(retryCount + 1) - found \(snapshot?.documents.count ?? 0) documents")
                    break
                } catch let error {
                    lastError = error
                    retryCount += 1
                    NSLog("🏠 SalePropertyService: Error on attempt \(retryCount): \(error.localizedDescription). Retrying...")
                    try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second before retry
                }
            }
            
            if let snapshot = snapshot {
                var fetchedProperties: [SaleProperty] = []
                
                for document in snapshot.documents {
                    NSLog("🏠 SalePropertyService: Processing document ID: \(document.documentID)")
                    
                    do {
                        // First try to decode directly
                        if let property = try? document.data(as: SaleProperty.self) {
                            fetchedProperties.append(property)
                            NSLog("🏠 SalePropertyService: Successfully decoded property: \(property.title)")
                        } else {
                            // Manual decoding as fallback
                            let data = document.data()
                            NSLog("🏠 SalePropertyService: Attempting manual decoding for \(document.documentID)")
                            
                            // Try to map Firestore fields to SaleProperty structure
                            if let manualProperty = createPropertyFromData(documentID: document.documentID, data: data) {
                                fetchedProperties.append(manualProperty)
                                NSLog("🏠 SalePropertyService: Successfully manual decoded property: \(manualProperty.title)")
                            } else {
                                NSLog("🏠 SalePropertyService: Manual decoding failed for \(document.documentID)")
                            }
                        }
                    } catch {
                        NSLog("🏠 SalePropertyService: Error decoding document \(document.documentID): \(error)")
                        NSLog("🏠 SalePropertyService: Document data: \(document.data())")
                    }
                }
                
                NSLog("🏠 SalePropertyService: Successfully processed \(fetchedProperties.count) properties")
                
                await MainActor.run {
                    self.properties = fetchedProperties
                    self.isLoading = false
                    NSLog("🏠 SalePropertyService: Updated @Published properties array with \(fetchedProperties.count) items")
                }
            } else if let error = lastError {
                throw error
            } else {
                throw NSError(domain: "SalePropertyService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch properties after multiple attempts"])
            }
            
        } catch {
            NSLog("🏠 SalePropertyService: Error fetching properties: \(error)")
            
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func createPropertyFromData(documentID: String, data: [String: Any]) -> SaleProperty? {
        guard let title = data["title"] as? String else { return nil }
        
        // Extract basic fields with defaults if missing
        let description = data["description"] as? String ?? "No description available"
        let price = data["price"] as? Double ?? 0.0
        let bedrooms = data["bedrooms"] as? Int ?? 0
        let bathrooms = data["bathrooms"] as? Int ?? 0
        let area = data["area"] as? String ?? "0 sq ft"
        
        // Property type parsing
        let propertyTypeString = data["propertyType"] as? String ?? "house"
        let propertyType = PropertyType(rawValue: propertyTypeString.lowercased()) ?? .house
        
        // Image URLs
        let images = data["images"] as? [String] ?? []
        
        // Status
        let statusString = data["status"] as? String ?? "active"
        let status = SalePropertyStatus(rawValue: statusString) ?? .active
        
        // Is new property flag
        let isNew = data["isNew"] as? Bool ?? false
        
        // Timestamps
        let createdAtTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let updatedAtTimestamp = data["updatedAt"] as? Timestamp ?? Timestamp(date: Date())
        let availableFromTimestamp = data["availableFrom"] as? Timestamp ?? Timestamp(date: Date())
        
        // Address
        var addressData = PropertyAddressOld(
            street: "Unknown Street",
            city: "Unknown City",
            state: "Unknown State",
            zipCode: "00000",
            country: "Sri Lanka"
        )
        
        if let address = data["address"] as? [String: Any] {
            addressData = PropertyAddressOld(
                street: address["street"] as? String ?? "Unknown Street",
                city: address["city"] as? String ?? "Unknown City",
                state: address["state"] as? String ?? "Unknown State",
                zipCode: address["zipCode"] as? String ?? "00000",
                country: address["country"] as? String ?? "Sri Lanka"
            )
        }
        
        // Coordinates
        var coordinatesData = PropertyCoordinates(latitude: 0.0, longitude: 0.0)
        
        if let coordinates = data["coordinates"] as? [String: Any] {
            coordinatesData = PropertyCoordinates(
                latitude: coordinates["latitude"] as? Double ?? 0.0,
                longitude: coordinates["longitude"] as? Double ?? 0.0
            )
        }
        
        // Seller information
        var sellerData = PropertySeller(
            id: "unknown",
            name: "Unknown Seller",
            email: "unknown@example.com",
            phone: nil,
            profileImageURL: nil,
            rating: 0.0,
            reviewCount: 0,
            verificationStatus: .unverified
        )
        
        if let seller = data["seller"] as? [String: Any] {
            sellerData = PropertySeller(
                id: seller["id"] as? String ?? "unknown",
                name: seller["name"] as? String ?? "Unknown Seller",
                email: seller["email"] as? String ?? "unknown@example.com",
                phone: seller["phone"] as? String,
                profileImageURL: seller["avatar"] as? String,
                rating: seller["rating"] as? Double ?? 0.0,
                reviewCount: seller["totalSales"] as? Int ?? 0,
                verificationStatus: PropertySeller.VerificationStatus(rawValue: seller["verificationStatus"] as? String ?? "unverified") ?? .unverified
            )
        }
        
        // Features
        var featuresData: [PropertyFeature] = []
        
        if let features = data["features"] as? [[String: Any]] {
            for feature in features {
                if let id = feature["id"] as? String,
                   let name = feature["name"] as? String,
                   let icon = feature["icon"] as? String,
                   let categoryString = feature["category"] as? String,
                   let category = PropertyFeature.PropertyFeatureCategory(rawValue: categoryString) {
                    
                    let propertyFeature = PropertyFeature(
                        id: id,
                        name: name,
                        icon: icon,
                        category: category
                    )
                    
                    featuresData.append(propertyFeature)
                }
            }
        }
        
        // Create the SaleProperty object
        return SaleProperty(
            id: documentID,  // Use the Firestore document ID
            title: title,
            description: description,
            price: price,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            area: area,
            propertyType: propertyType,
            address: addressData,
            coordinates: coordinatesData,
            images: images,
            panoramicImages: [],
            walkthroughVideoURL: nil,
            features: featuresData,
            seller: sellerData,
            availableFrom: availableFromTimestamp.dateValue(),
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            status: status,
            isNew: isNew
        )
    }
    
    func addProperty(_ property: SaleProperty) async throws {
        NSLog("🏠 SalePropertyService: Adding new property: \(property.title)")
        
        do {
            _ = try db.collection("sale_properties").addDocument(from: property)
            NSLog("🏠 SalePropertyService: Successfully added property to Firestore")
            
            // Send notification to all users about new property listing
            let notificationService = NotificationService.shared
            await notificationService.sendNotificationToAllUsers(
                title: "New Property Listed",
                body: "\(property.title) in \(property.address.city) - Rs. \(formatPrice(property.price))",
                type: .newSelling,
                data: [
                    "propertyId": property.id,
                    "propertyType": property.propertyType.displayName,
                    "city": property.address.city,
                    "price": String(property.price)
                ]
            )
            
            // Reload properties after adding
            await fetchProperties()
            
        } catch {
            NSLog("🏠 SalePropertyService: Error adding property: \(error)")
            throw error
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        let formattedValue = formatter.string(from: NSNumber(value: price)) ?? "0"
        
        if price >= 1_000_000 {
            let millionValue = price / 1_000_000
            return "\(String(format: "%.1f", millionValue))M"
        } else {
            return formattedValue
        }
    }
    
    func updateProperty(_ property: SaleProperty) async throws {
        let propertyId = property.id
        NSLog("🏠 SalePropertyService: Updating property ID: \(propertyId)")
        
        NSLog("🏠 SalePropertyService: Updating property ID: \(propertyId)")
        
        do {
            try db.collection("sale_properties").document(propertyId).setData(from: property)
            NSLog("🏠 SalePropertyService: Successfully updated property in Firestore")
            
            // Reload properties after updating
            await fetchProperties()
            
        } catch {
            NSLog("🏠 SalePropertyService: Error updating property: \(error)")
            throw error
        }
    }
    
    func deleteProperty(_ property: SaleProperty) async throws {
        let propertyId = property.id
        NSLog("🏠 SalePropertyService: Deleting property ID: \(propertyId)")
        
        NSLog("🏠 SalePropertyService: Deleting property ID: \(propertyId)")
        
        do {
            try await db.collection("sale_properties").document(propertyId).delete()
            NSLog("🏠 SalePropertyService: Successfully deleted property from Firestore")
            
            // Reload properties after deleting
            await fetchProperties()
            
        } catch {
            NSLog("🏠 SalePropertyService: Error deleting property: \(error)")
            throw error
        }
    }
    
    func getProperty(by id: String) -> SaleProperty? {
        return properties.first { $0.id == id }
    }
    
    func searchProperties(query: String) -> [SaleProperty] {
        guard !query.isEmpty else { return properties }
        
        let lowercasedQuery = query.lowercased()
        return properties.filter { property in
            property.title.lowercased().contains(lowercasedQuery) ||
            property.description.lowercased().contains(lowercasedQuery) ||
            property.address.street.lowercased().contains(lowercasedQuery) ||
            property.address.city.lowercased().contains(lowercasedQuery) ||
            property.address.state.lowercased().contains(lowercasedQuery)
        }
    }
    
    func filterProperties(
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        bedrooms: Int? = nil,
        bathrooms: Int? = nil,
        propertyType: String? = nil
    ) -> [SaleProperty] {
        return properties.filter { property in
            var matches = true
            
            if let minPrice = minPrice {
                matches = matches && property.price >= minPrice
            }
            
            if let maxPrice = maxPrice {
                matches = matches && property.price <= maxPrice
            }
            
            if let bedrooms = bedrooms {
                matches = matches && property.bedrooms == bedrooms
            }
            
            if let bathrooms = bathrooms {
                matches = matches && property.bathrooms == bathrooms
            }
            
            if let propertyType = propertyType, !propertyType.isEmpty {
                matches = matches && property.propertyType.displayName.lowercased() == propertyType.lowercased()
            }
            
            return matches
        }
    }
    
    func sortProperties(by sortOption: PropertySortOption) -> [SaleProperty] {
        switch sortOption {
        case .priceAscending:
            return properties.sorted { $0.price < $1.price }
        case .priceDescending:
            return properties.sorted { $0.price > $1.price }
        case .bedroomsAscending:
            return properties.sorted { $0.bedrooms < $1.bedrooms }
        case .bedroomsDescending:
            return properties.sorted { $0.bedrooms > $1.bedrooms }
        case .newest:
            return properties.sorted(by: { $0.createdAt > $1.createdAt })
        case .oldest:
            return properties.sorted(by: { $0.createdAt < $1.createdAt })
        }
    }
}

enum PropertySortOption: String, CaseIterable {
    case priceAscending = "Price: Low to High"
    case priceDescending = "Price: High to Low"
    case bedroomsAscending = "Bedrooms: Low to High"
    case bedroomsDescending = "Bedrooms: High to Low"
    case newest = "Newest First"
    case oldest = "Oldest First"
}

extension SalePropertyService {
    func refreshProperties() {
        NSLog("🏠 SalePropertyService: Manual refresh requested")
        loadPropertiesFromFirestore()
    }
    
    func clearProperties() {
        NSLog("🏠 SalePropertyService: Clearing all properties")
        properties.removeAll()
    }
    
    var hasProperties: Bool {
        return !properties.isEmpty
    }
    
    var propertyCount: Int {
        return properties.count
    }
    
    func getPropertiesForLocation(city: String) -> [SaleProperty] {
        return properties.filter { 
            $0.address.city.lowercased() == city.lowercased() 
        }
    }
    
    func getPropertiesInPriceRange(min: Double, max: Double) -> [SaleProperty] {
        return properties.filter { 
            $0.price >= min && $0.price <= max 
        }
    }
    
    func getFeaturedProperties() -> [SaleProperty] {
        // Return properties that might be featured (e.g., recently added, high-end)
        return properties
            .sorted(by: { $0.createdAt > $1.createdAt })
            .prefix(6)
            .map { $0 }
    }
}

// MARK: - Debug Helper Extensions
extension SalePropertyService {
    func printDiagnostics() {
        NSLog("🏠 SalePropertyService Diagnostics:")
        NSLog("  - Properties count: \(properties.count)")
        NSLog("  - Is loading: \(isLoading)")
        NSLog("  - Error message: \(errorMessage ?? "None")")
        
        if properties.isEmpty {
            NSLog("  - No properties loaded")
        } else {
            NSLog("  - Sample property: \(properties.first?.title ?? "Unknown")")
        }
    }
}
