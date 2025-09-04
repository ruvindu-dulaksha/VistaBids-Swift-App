//
//  ARPanoramicView.swift
//  VistaBids
//
//  Created by AI Assistant on 2025-08-18.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARPanoramicView: View {
    let panoramicImages: [PanoramicImage]
    @State private var selectedImage: PanoramicImage?
    @State private var isARSessionActive = false
    @State private var isARLoading = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if isARSessionActive, let selectedImage = selectedImage {
                    ZStack {
                        ARPanoramaViewerRepresentable(panoramicImage: selectedImage)
                            .ignoresSafeArea()
                        
                        // Loading overlay
                        if isARLoading {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                Text("Initializing AR View...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .padding(.top)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.black.opacity(0.6))
                            .ignoresSafeArea()
                        }
                    }
                } else {
                    panoramicImageGrid
                }
                
                if isARSessionActive {
                    VStack {
                        HStack {
                            Button("Exit AR") {
                                isARSessionActive = false
                                selectedImage = nil
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.7))
                            .cornerRadius(20)
                            
                            Spacer()
                            
                            if let selectedImage = selectedImage {
                                VStack(alignment: .trailing) {
                                    Text(selectedImage.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    if let description = selectedImage.description {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                            }
                        }
                        .padding()
                        
                        // Instructions for AR usage
                        HStack {
                            Image(systemName: "hand.draw")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("Look around to explore the 360° view")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .background(.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("360° AR Tour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var panoramicImageGrid: some View {
        Group {
            if panoramicImages.isEmpty {
                // Empty state when no panoramic images
                VStack(spacing: 20) {
                    Image(systemName: "view.3d")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No AR Content Available")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("This property doesn't have any 360° panoramic views yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .cornerRadius(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(Array(panoramicImagesByRoom.keys), id: \.self) { roomType in
                            if let roomImages = panoramicImagesByRoom[roomType] {
                                Section {
                                    ForEach(roomImages) { image in
                                        PanoramicImageCard(
                                            image: image,
                                            onTap: {
                                                selectedImage = image
                                                isARLoading = true
                                                isARSessionActive = true
                                                
                                                // Simulate AR initialization delay
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                    isARLoading = false
                                                }
                                            }
                                        )
                                    }
                                } header: {
                                    HStack {
                                        Image(systemName: roomType.icon)
                                            .foregroundColor(.accentColor)
                                        Text(roomType.displayName)
                                            .font(.headline)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var panoramicImagesByRoom: [PanoramicImage.RoomType: [PanoramicImage]] {
        Dictionary(grouping: panoramicImages) { $0.roomType }
    }
}

struct PanoramicImageCard: View {
    let image: PanoramicImage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "view.3d")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        
                        if image.isAREnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "arkit")
                                    .font(.caption)
                                Text("AR")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(image.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    if let description = image.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AR Panorama Viewer
struct ARPanoramaViewerRepresentable: UIViewRepresentable {
    let panoramicImage: PanoramicImage
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session for better panoramic viewing
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [] // Disable plane detection for panoramic viewing
        configuration.isLightEstimationEnabled = false // Disable light estimation for consistent viewing
        
        // Check if AR is supported
        guard ARWorldTrackingConfiguration.isSupported else {
            print("AR World Tracking is not supported on this device")
            errorMessage = "AR is not supported on this device"
            return arView
        }
        
        arView.session.run(configuration)
        
        // Create panoramic sphere
        createPanoramicSphere(in: arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update if needed
    }
    
    private func createPanoramicSphere(in arView: ARView) {
        // Create a large sphere to display the panoramic image (room scale)
        let sphereMesh = MeshResource.generateSphere(radius: 5.0) // Increased radius for better immersion
        
        // Load the actual panoramic image
        loadPanoramicImageTexture { texture in
            DispatchQueue.main.async {
                var material = UnlitMaterial()
                if let texture = texture {
                    material.color = .init(texture: MaterialParameters.Texture(texture))
                } else {
                    // Fallback: Create a better looking error sphere with gradient
                    material.color = .init(tint: .blue.withAlphaComponent(0.5))
                    print("⚠️ Using fallback material for panoramic sphere")
                }
                
                let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [material])
                
                // Flip the sphere inside-out so we can see the texture from inside
                sphereEntity.scale = SIMD3<Float>(-1, 1, 1)
                
                // Position the sphere at world origin
                let anchor = AnchorEntity(.world(transform: matrix_identity_float4x4))
                anchor.addChild(sphereEntity)
                
                // Enable interaction
                sphereEntity.generateCollisionShapes(recursive: true)
                arView.installGestures([.rotation, .scale], for: sphereEntity)
                
                // Add the sphere to the scene
                arView.scene.addAnchor(anchor)
                
                print("✅ Panoramic sphere created and added to AR scene")
            }
        }
    }
    
    private func loadPanoramicImageTexture(completion: @escaping (TextureResource?) -> Void) {
        guard !panoramicImage.imageURL.isEmpty else {
            print("❌ No panoramic image URL provided")
            completion(nil)
            return
        }
        
        print("🖼️ Loading panoramic image from: \(panoramicImage.imageURL)")
        
        // Handle local storage URLs (our new local image system)
        if panoramicImage.imageURL.hasPrefix("local://") {
            loadLocalPanoramicImage(completion: completion)
            return
        }
        
        // Handle remote URLs
        guard let url = URL(string: panoramicImage.imageURL) else {
            print("❌ Invalid panoramic image URL: \(panoramicImage.imageURL)")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error loading panoramic image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data,
                  let uiImage = UIImage(data: data) else {
                print("❌ Failed to create image from data")
                completion(nil)
                return
            }
            
            print("✅ Successfully loaded remote panoramic image: \(uiImage.size)")
            self.createTextureFromImage(uiImage, completion: completion)
        }.resume()
    }
    
    private func loadLocalPanoramicImage(completion: @escaping (TextureResource?) -> Void) {
        let urlString = panoramicImage.imageURL
        print("🔍 Processing local panoramic URL: \(urlString)")
        
        // Handle different local URL formats
        var finalImagePath: String?
        
        if urlString.hasPrefix("local://") {
            let cleanPath = String(urlString.dropFirst(8)) // Remove "local://"
            
            // Check if it's already a full file path
            if cleanPath.hasPrefix("file://") || cleanPath.hasPrefix("/") {
                // Extract the actual file path
                let actualPath = cleanPath.replacingOccurrences(of: "file://", with: "")
                if FileManager.default.fileExists(atPath: actualPath) {
                    finalImagePath = actualPath
                } else {
                    // Try to find it in documents directory
                    let filename = URL(fileURLWithPath: actualPath).lastPathComponent
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let documentFile = documentsPath.appendingPathComponent(filename)
                    if FileManager.default.fileExists(atPath: documentFile.path) {
                        finalImagePath = documentFile.path
                    }
                }
            } else {
                // It's just a filename, look in documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let documentFile = documentsPath.appendingPathComponent(cleanPath)
                if FileManager.default.fileExists(atPath: documentFile.path) {
                    finalImagePath = documentFile.path
                }
            }
        } else if urlString.hasPrefix("file://") {
            // Direct file URL
            let path = urlString.replacingOccurrences(of: "file://", with: "")
            if FileManager.default.fileExists(atPath: path) {
                finalImagePath = path
            }
        } else if urlString.hasPrefix("/") {
            // Direct file path
            if FileManager.default.fileExists(atPath: urlString) {
                finalImagePath = urlString
            }
        }
        
        // Try to load the image
        if let imagePath = finalImagePath,
           let uiImage = UIImage(contentsOfFile: imagePath) {
            print("✅ Successfully loaded panoramic image from: \(imagePath)")
            createTextureFromImage(uiImage, completion: completion)
            return
        }
        
        // Fallback: Try to find by filename in documents directory
        let filename = URL(fileURLWithPath: urlString).lastPathComponent
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fallbackPath = documentsPath.appendingPathComponent(filename)
        
        if let fallbackImage = UIImage(contentsOfFile: fallbackPath.path) {
            print("✅ Loaded panoramic image from fallback path: \(fallbackPath.path)")
            createTextureFromImage(fallbackImage, completion: completion)
            return
        }
        
        // Last resort: Try app bundle
        let baseFileName = filename.replacingOccurrences(of: ".jpg", with: "")
                                  .replacingOccurrences(of: ".jpeg", with: "")
                                  .replacingOccurrences(of: ".png", with: "")
        
        if let bundleImage = UIImage(named: baseFileName) {
            print("✅ Loaded panoramic image from bundle: \(baseFileName)")
            createTextureFromImage(bundleImage, completion: completion)
            return
        }
        
        print("❌ Failed to load local panoramic image from all sources. URL: \(urlString)")
        completion(nil)
    }
    
    private func createTextureFromImage(_ uiImage: UIImage, completion: @escaping (TextureResource?) -> Void) {
        guard let cgImage = uiImage.cgImage else {
            print("Failed to get CGImage from UIImage")
            completion(nil)
            return
        }
        
        do {
            let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
            completion(texture)
        } catch {
            print("Failed to create texture from image: \(error)")
            completion(nil)
        }
    }
}

#Preview {
    ARPanoramicView(panoramicImages: [
        PanoramicImage(
            id: "1",
            imageURL: "",
            title: "Living Room 360°",
            description: "Spacious living room with ocean view",
            roomType: .livingRoom,
            captureDate: Date(),
            isAREnabled: true
        ),
        PanoramicImage(
            id: "2",
            imageURL: "",
            title: "Kitchen 360°",
            description: "Modern kitchen with island",
            roomType: .kitchen,
            captureDate: Date(),
            isAREnabled: true
        )
    ])
}
