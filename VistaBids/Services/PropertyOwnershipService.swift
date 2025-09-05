//
//  PropertyOwnershipService.swift
//  VistaBids
//
//  Created by AI Assistant on 2025-09-04.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

// MARK: - Property Ownership Protocol
protocol OwnableProperty {
    var panoramicImages: [PanoramicImage] { get }
    func getOwnerId() -> String
}

extension AuctionProperty: OwnableProperty {
    func getOwnerId() -> String {
        return sellerId
    }
}

extension SaleProperty: OwnableProperty {
    func getOwnerId() -> String {
        return seller.id
    }
}

class PropertyOwnershipService: ObservableObject {
    @Published var currentUserId: String?
    private let db = Firestore.firestore()
    
    init() {
        self.currentUserId = Auth.auth().currentUser?.uid
        
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUserId = user?.uid
            }
        }
    }
    
    // MARK: - Ownership Checks
    
    /// Check if the current user owns the auction property
    func isOwner(of property: AuctionProperty) -> Bool {
        guard let currentUserId = currentUserId else { return false }
        return property.sellerId == currentUserId
    }
    
    /// Check if the current user owns the sale property
    func isOwner(of property: SaleProperty) -> Bool {
        guard let currentUserId = currentUserId else { return false }
        return property.seller.id == currentUserId
    }
    
    /// Check if the current user can modify panoramic images for an auction property
    func canModifyPanoramicImages(for property: AuctionProperty) -> Bool {
        return isOwner(of: property)
    }
    
    /// Check if the current user can modify panoramic images for a sale property
    func canModifyPanoramicImages(for property: SaleProperty) -> Bool {
        return isOwner(of: property)
    }
    
    /// Generic ownership check for any property type
    func isOwner(of property: OwnableProperty) -> Bool {
        guard let currentUserId = currentUserId else { return false }
        return property.getOwnerId() == currentUserId
    }
    
    /// Generic panoramic image modification check
    func canModifyPanoramicImages(for property: OwnableProperty) -> Bool {
        return isOwner(of: property)
    }
    
    /// Check if the current user can capture images during property creation
    func canCaptureImages() -> Bool {
        return currentUserId != nil
    }
    
    // MARK: - Image Storage Management
    
    /// Save panoramic image for a property (only owner can do this)
    func savePanoramicImage(_ image: UIImage, for propertyId: String, roomType: PanoramicImage.RoomType, title: String, description: String? = nil) async throws -> PanoramicImage {
        guard let currentUserId = currentUserId else {
            throw PropertyOwnershipError.notAuthenticated
        }
        
        // Verify ownership
        let property = try await getProperty(propertyId)
        guard property.sellerId == currentUserId else {
            throw PropertyOwnershipError.notOwner
        }
        
        // Save image to storage and create PanoramicImage
        let imageURL = try await saveImageToStorage(image, propertyId: propertyId)
        
        let panoramicImage = PanoramicImage(
            id: UUID().uuidString,
            imageURL: imageURL,
            title: title,
            description: description,
            roomType: roomType,
            captureDate: Date(),
            isAREnabled: true
        )
        
        // Update property with new panoramic image
        try await addPanoramicImageToProperty(panoramicImage, propertyId: propertyId)
        
        return panoramicImage
    }
    
    /// Delete panoramic image (only owner can do this)
    func deletePanoramicImage(_ imageId: String, from propertyId: String) async throws {
        guard let currentUserId = currentUserId else {
            throw PropertyOwnershipError.notAuthenticated
        }
        
        // Verify ownership
        let property = try await getProperty(propertyId)
        guard property.sellerId == currentUserId else {
            throw PropertyOwnershipError.notOwner
        }
        
        // Remove from property
        try await removePanoramicImageFromProperty(imageId, propertyId: propertyId)
    }
    
    // MARK: - Private Helper Methods
    
    private func getProperty(_ propertyId: String) async throws -> AuctionProperty {
        let document = try await db.collection("auction_properties").document(propertyId).getDocument()
        guard let data = document.data() else {
            throw PropertyOwnershipError.propertyNotFound
        }
        return try Firestore.Decoder().decode(AuctionProperty.self, from: data)
    }
    
    private func saveImageToStorage(_ image: UIImage, propertyId: String) async throws -> String {
        // Create a unique filename
        let filename = "panoramic_\(UUID().uuidString).jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageURL = documentsPath.appendingPathComponent(filename)
        
        // Save image to local storage
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PropertyOwnershipError.imageProcessingFailed
        }
        
        try imageData.write(to: imageURL)
        
        // Return local URL for now (in production, you'd upload to Firebase Storage)
        return "local://\(filename)"
    }
    
    private func addPanoramicImageToProperty(_ panoramicImage: PanoramicImage, propertyId: String) async throws {
        try await db.collection("auction_properties").document(propertyId).updateData([
            "panoramicImages": FieldValue.arrayUnion([try Firestore.Encoder().encode(panoramicImage)])
        ])
    }
    
    private func removePanoramicImageFromProperty(_ imageId: String, propertyId: String) async throws {
        let property = try await getProperty(propertyId)
        let updatedImages = property.panoramicImages.filter { $0.id != imageId }
        
        try await db.collection("auction_properties").document(propertyId).updateData([
            "panoramicImages": try updatedImages.map { try Firestore.Encoder().encode($0) }
        ])
    }
}

// MARK: - Property Ownership Errors

enum PropertyOwnershipError: LocalizedError {
    case notAuthenticated
    case notOwner
    case propertyNotFound
    case imageProcessingFailed
    case storageError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action."
        case .notOwner:
            return "You can only modify properties that you own."
        case .propertyNotFound:
            return "Property not found."
        case .imageProcessingFailed:
            return "Failed to process the image."
        case .storageError:
            return "Failed to save image to storage."
        }
    }
}
