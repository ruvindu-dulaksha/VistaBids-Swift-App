//
//  ImageUploadService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-19.
//  Local storage implementation for image handling
//

import Foundation
import UIKit
import Combine

/// Service for handling image uploads and storage
/// Currently implements local storage with plans for Firebase Storage integration
@MainActor
class ImageUploadService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    private let documentsDirectory: URL
    private let imagesDirectory: URL
    
    // MARK: - Initialization
    init() {
        // Set up local storage directories
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.imagesDirectory = documentsDirectory.appendingPathComponent("PropertyImages", isDirectory: true)
        
        // Create images directory if it doesn't exist
        createImageDirectoryIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// Upload multiple property images
    /// - Parameters:
    ///   - images: Array of UIImages to upload
    ///   - propertyId: Unique identifier for the property
    /// - Returns: Array of image URLs
    func uploadPropertyImages(_ images: [UIImage], propertyId: String) async throws -> [String] {
        guard !images.isEmpty else { return [] }
        
        isUploading = true
        uploadProgress = 0.0
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        var imageUrls: [String] = []
        let totalImages = Double(images.count)
        
        for (index, image) in images.enumerated() {
            do {
                let imageUrl = try await saveImageLocally(
                    image,
                    fileName: "\(propertyId)_property_\(index + 1).jpg"
                )
                imageUrls.append(imageUrl)
                
                // Update progress
                let progress = Double(index + 1) / totalImages
                await MainActor.run {
                    uploadProgress = progress
                }
                
                // Small delay to show progress
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
            } catch {
                print("❌ Failed to save image \(index + 1): \(error)")
                lastError = error
                throw error
            }
        }
        
        print("✅ Successfully saved \(imageUrls.count) property images locally")
        return imageUrls
    }
    
    /// Upload a panoramic image for AR viewing
    /// - Parameters:
    ///   - image: The panoramic image
    ///   - propertyId: Unique identifier for the property
    ///   - roomType: Type of room for organization
    /// - Returns: Image URL
    func uploadPanoramicImage(_ image: UIImage, propertyId: String, roomType: PanoramicImage.RoomType) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        defer {
            isUploading = false
            uploadProgress = 1.0
        }
        
        do {
            // Generate unique filename with timestamp for panoramic images
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileName = "\(propertyId)_panoramic_\(roomType.rawValue)_\(timestamp).jpg"
            
            // Use higher quality for panoramic images since they're used in AR
            guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                throw ImageUploadError.compressionFailed
            }
            
            // Ensure images directory exists
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let imagesDirectory = documentsURL.appendingPathComponent("images")
            
            if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
                try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            }
            
            // Save the image file
            let fileURL = imagesDirectory.appendingPathComponent(fileName)
            try imageData.write(to: fileURL)
            
            // Verify the file was saved correctly
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw ImageUploadError.fileWriteFailed
            }
            
            // Simulate upload progress
            for i in 1...10 {
                await MainActor.run {
                    uploadProgress = Double(i) / 10.0
                }
                try await Task.sleep(nanoseconds: 30_000_000) // 0.03 seconds
            }
            
            let localURL = "local://images/\(fileName)"
            print("✅ Successfully saved panoramic image: \(fileName) -> \(localURL)")
            print("📁 Full path: \(fileURL.path)")
            
            return localURL
            
        } catch {
            print("❌ Failed to save panoramic image: \(error)")
            lastError = error
            throw error
        }
    }
    
    /// Get local image URL for a file name
    /// - Parameter fileName: Name of the image file
    /// - Returns: Local file URL as string
    func getLocalImageUrl(fileName: String) -> String {
        return imagesDirectory.appendingPathComponent(fileName).path
    }
    
    /// Check if an image exists locally
    /// - Parameter fileName: Name of the image file
    /// - Returns: True if the file exists
    func imageExistsLocally(fileName: String) -> Bool {
        let filePath = imagesDirectory.appendingPathComponent(fileName).path
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    /// Delete a local image
    /// - Parameter fileName: Name of the image file to delete
    func deleteLocalImage(fileName: String) throws {
        let fileUrl = imagesDirectory.appendingPathComponent(fileName)
        try FileManager.default.removeItem(at: fileUrl)
    }
    
    // MARK: - Private Methods
    
    /// Save image to local storage
    /// - Parameters:
    ///   - image: UIImage to save
    ///   - fileName: Name for the saved file
    /// - Returns: Local file URL as string
    private func saveImageLocally(_ image: UIImage, fileName: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ImageUploadError.serviceUnavailable)
                    return
                }
                
                do {
                    // Compress image to JPEG
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        throw ImageUploadError.compressionFailed
                    }
                    
                    // Create file URL
                    let fileUrl = self.imagesDirectory.appendingPathComponent(fileName)
                    
                    // Write data to file
                    try imageData.write(to: fileUrl)
                    
                    // Verify file was written successfully
                    guard FileManager.default.fileExists(atPath: fileUrl.path) else {
                        throw ImageUploadError.fileWriteFailed
                    }
                    
                    // Return proper file URL for AsyncImage compatibility
                    let localUrl = fileUrl.absoluteString
                    print("✅ Saved image: \(fileName) -> \(localUrl)")
                    continuation.resume(returning: localUrl)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Create images directory if it doesn't exist
    private func createImageDirectoryIfNeeded() {
        do {
            try FileManager.default.createDirectory(
                at: imagesDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            print("📁 Images directory ready at: \(imagesDirectory.path)")
        } catch {
            print("❌ Failed to create images directory: \(error)")
        }
    }
}

// MARK: - Error Types

enum ImageUploadError: LocalizedError {
    case serviceUnavailable
    case compressionFailed
    case fileWriteFailed
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "Image upload service is unavailable"
        case .compressionFailed:
            return "Failed to compress image"
        case .fileWriteFailed:
            return "Failed to write image file"
        case .invalidImage:
            return "Invalid image provided"
        }
    }
}

// MARK: - Backward Compatibility

extension ImageUploadService {
    
    /// Legacy method for property image upload
    @available(*, deprecated, message: "Use uploadPropertyImages(_:propertyId:) instead")
    func uploadImages(_ images: [UIImage], for propertyId: String) async throws -> [String] {
        return try await uploadPropertyImages(images, propertyId: propertyId)
    }
    
    /// Legacy method for panoramic image upload
    @available(*, deprecated, message: "Use uploadPanoramicImage(_:propertyId:roomType:) instead")
    func uploadPanoramicImage(_ image: UIImage, for propertyId: String) async throws -> String {
        return try await uploadPanoramicImage(image, propertyId: propertyId, roomType: .livingRoom)
    }
}

// MARK: - Future Firebase Storage Integration Points

/*
 When Firebase Storage is properly configured, replace the local storage methods with:
 
 1. FirebaseStorage.storage().reference() for storage references
 2. StorageReference.putData() for upload operations
 3. StorageReference.downloadURL() for retrieving URLs
 4. StorageMetadata for file metadata
 5. Progress tracking through StorageUploadTask
 
 Example structure:
 
 private func uploadToFirebaseStorage(_ imageData: Data, path: String) async throws -> String {
     let storageRef = Storage.storage().reference()
     let imageRef = storageRef.child(path)
     
     let metadata = StorageMetadata()
     metadata.contentType = "image/jpeg"
     
     let _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
     let downloadURL = try await imageRef.downloadURL()
     
     return downloadURL.absoluteString
 }
 */