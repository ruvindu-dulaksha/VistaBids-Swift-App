//
//  ImageUtils.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-24.
//

import Foundation
import SwiftUI
import UIKit

// Platform-specific type alias
#if os(iOS) || os(tvOS) || os(watchOS)
typealias PlatformImage = UIImage
#elseif os(macOS)
typealias PlatformImage = NSImage
#endif

/// Utility class for handling image operations including local storage and retrieval
class ImageUtils {
    
    /// Shared instance
    static let shared = ImageUtils()
    
    private init() {}
    
    /// Documents directory URL
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Images subdirectory URL
    private var imagesDirectory: URL {
        documentsDirectory.appendingPathComponent("images")
    }
    
    /// Ensures the images directory exists
    func ensureImagesDirectoryExists() {
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
                print("Created images directory: \(imagesDirectory.path)")
            } catch {
                print("Failed to create images directory: \(error)")
            }
        }
    }
    
   
    func saveImageLocally(_ image: PlatformImage, filename: String) throws -> String {
        ensureImagesDirectoryExists()
        
        #if canImport(UIKit)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageUtilsError.compressionFailed
        }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let bitmapRep = NSBitmapImageRep(cgImage: cgImage),
              let imageData = bitmapRep.representation(using: .jpeg, properties: [:]) else {
            throw ImageUtilsError.compressionFailed
        }
        #endif
        
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        try imageData.write(to: fileURL)
        
        // Verify file was saved
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ImageUtilsError.fileWriteFailed
        }
        
        let localURL = "local://images/\(filename)"
        print("Saved image locally: \(filename) -> \(localURL)")
        
        return localURL
    }
    
   
    func loadImage(from urlString: String) async -> PlatformImage? {
        if urlString.hasPrefix("local://") {
            return await loadLocalImage(from: urlString)
        } else if let url = URL(string: urlString) {
            return await loadRemoteImage(from: url)
        }
        return nil
    }
    
  
    private func loadLocalImage(from urlString: String) async -> PlatformImage? {
        let cleanPath = String(urlString.dropFirst(8)) // Remove "local://"
        
        print("🔍 Loading local image: \(cleanPath)")
        
        // Try different path combinations
        var candidatePaths: [String] = []
        
        // 1. Direct path from documents directory
        candidatePaths.append(documentsDirectory.appendingPathComponent(cleanPath).path)
        
        // 2. Path with images subdirectory if not already included
        if !cleanPath.hasPrefix("images/") {
            candidatePaths.append(imagesDirectory.appendingPathComponent(cleanPath).path)
        }
        
        // 3. If it looks like a full path, try it directly
        if cleanPath.hasPrefix("/") || cleanPath.hasPrefix("file://") {
            let actualPath = cleanPath.replacingOccurrences(of: "file://", with: "")
            candidatePaths.append(actualPath)
        }
        
        // 4. Just the filename in images directory
        let filename = URL(fileURLWithPath: cleanPath).lastPathComponent
        candidatePaths.append(imagesDirectory.appendingPathComponent(filename).path)
        
        // Try each candidate path
        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path),
               let image = UIImage(contentsOfFile: path) {
                print(" Loaded local image from: \(path)")
                return image
            }
        }
        
        print(" Failed to load local image: \(urlString)")
        return nil
    }
    
    
    private func loadRemoteImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let image = UIImage(data: data)
            
            if image != nil {
                print("Loaded remote image from: \(url)")
            } else {
                print(" Failed to create image from remote data: \(url)")
            }
            
            return image
        } catch {
            print("Failed to download remote image: \(error.localizedDescription)")
            return nil
        }
    }
    
   
    func deleteLocalImage(_ urlString: String) -> Bool {
        guard urlString.hasPrefix("local://") else { return false }
        
        let cleanPath = String(urlString.dropFirst(8))
        let filePath = documentsDirectory.appendingPathComponent(cleanPath)
        
        do {
            try FileManager.default.removeItem(at: filePath)
            print(" Deleted local image: \(cleanPath)")
            return true
        } catch {
            print(" Failed to delete local image: \(error)")
            return false
        }
    }
    
    
    func getImageStorageSize() -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    /// Clear all locally stored images
    func clearAllImages() {
        do {
            try FileManager.default.removeItem(at: imagesDirectory)
            ensureImagesDirectoryExists()
            print("Cleared all local images")
        } catch {
            print("Failed to clear images: \(error)")
        }
    }
}


enum ImageUtilsError: LocalizedError {
    case compressionFailed
    case fileWriteFailed
    case invalidPath
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .fileWriteFailed:
            return "Failed to write image file"
        case .invalidPath:
            return "Invalid file path"
        }
    }
}


extension Image {
    
    static func from(urlString: String) -> some View {
        AsyncImageView(urlString: urlString)
    }
}

/// Async Image View that handles both local and remote images
struct AsyncImageView: View {
    let urlString: String
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            Task {
                loadedImage = await ImageUtils.shared.loadImage(from: urlString)
                isLoading = false
            }
        }
    }
}
