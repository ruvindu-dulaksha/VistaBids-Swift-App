//
//  ARPanoramicView.swift
//  VistaBids
//
//  Created by AI Assistant on 2025-08-18.
//

import SwiftUI
import RealityKit
import ARKit
import SceneKit
import Combine

struct ARPanoramicView: View {
    let panoramicImages: [PanoramicImage]
    @State private var selectedImage: PanoramicImage?
    @State private var isARSessionActive = false
    @State private var isARLoading = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ownershipService = PropertyOwnershipService()
    
    // Property ownership info (can be either AuctionProperty or SaleProperty)
    var property: (any OwnableProperty)?
    
    var body: some View {
        NavigationView {
            ZStack {
                if isARSessionActive, let selectedImage = selectedImage {
                    ZStack {
                        // Always use SceneKit for consistent experience
                        ImmersiveSceneKitARView(panoramicImage: selectedImage)
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
                        
                        // Consistent viewing instructions
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "hand.draw")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                Text("Pan to look around • Pinch to zoom • Double tap to reset")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.leading, 8)
                                Spacer()
                            }
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

// MARK: - Immersive SceneKit AR View for Enhanced Experience
struct ImmersiveSceneKitARView: UIViewRepresentable {
    let panoramicImage: PanoramicImage
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        
        // Configure AR session for panoramic viewing
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        configuration.isLightEstimationEnabled = false
        
        arView.session.run(configuration)
        arView.automaticallyUpdatesLighting = false
        arView.antialiasingMode = .multisampling4X
        
        // Create immersive panoramic sphere
        createImmersivePanoramicScene(in: arView)
        
        // Add enhanced gesture recognizers
        addAdvancedGestureRecognizers(to: arView, context: context)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Update if needed
    }
    
    private func createImmersivePanoramicScene(in arView: ARSCNView) {
        let scene = SCNScene()
        arView.scene = scene
        
        // Create sphere geometry with higher detail for better quality
        let sphere = SCNSphere(radius: 10.0)
        sphere.segmentCount = 64 // Higher segment count for smoother sphere
        
        // Load and apply panoramic image
        loadPanoramicImageForSceneKit { image in
            DispatchQueue.main.async {
                // Create material with enhanced properties
                let material = SCNMaterial()
                
                if let image = image {
                    material.diffuse.contents = image
                } else {
                    // Fallback gradient material
                    let gradientLayer = CAGradientLayer()
                    gradientLayer.frame = CGRect(x: 0, y: 0, width: 1024, height: 512)
                    gradientLayer.colors = [
                        UIColor.systemBlue.cgColor,
                        UIColor.systemPurple.cgColor,
                        UIColor.systemBlue.cgColor
                    ]
                    gradientLayer.locations = [0.0, 0.5, 1.0]
                    gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                    gradientLayer.endPoint = CGPoint(x: 1, y: 1)
                    
                    UIGraphicsBeginImageContext(gradientLayer.frame.size)
                    if let context = UIGraphicsGetCurrentContext() {
                        gradientLayer.render(in: context)
                        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        material.diffuse.contents = gradientImage
                    }
                }
                
                // Enhanced material properties for better visual quality
                material.isDoubleSided = true
                material.cullMode = .front // Show texture from inside
                material.lightingModel = .constant // Prevent lighting from affecting the panorama
                material.writesToDepthBuffer = false
                
                sphere.materials = [material]
                
                // Create panorama node
                let panoramaNode = SCNNode(geometry: sphere)
                panoramaNode.scale = SCNVector3(-1, 1, 1) // Inside-out view
                
                // Create camera setup for immersive experience
                let cameraNode = SCNNode()
                cameraNode.camera = SCNCamera()
                cameraNode.camera?.fieldOfView = 75 // Wider field of view for better immersion
                cameraNode.camera?.zNear = 0.1
                cameraNode.camera?.zFar = 50.0
                cameraNode.position = SCNVector3(0, 0, 0)
                
                // Add nodes to scene
                scene.rootNode.addChildNode(cameraNode)
                scene.rootNode.addChildNode(panoramaNode)
                
                // Set camera as point of view
                arView.pointOfView = cameraNode
                
                print("✅ Enhanced SceneKit panoramic sphere created with immersive camera setup")
            }
        }
    }
    
    private func loadPanoramicImageForSceneKit(completion: @escaping (UIImage?) -> Void) {
        guard !panoramicImage.imageURL.isEmpty else {
            completion(nil)
            return
        }
        
        // Handle local URLs
        if panoramicImage.imageURL.hasPrefix("local://") {
            loadLocalImageForSceneKit(completion: completion)
            return
        }
        
        // Handle remote URLs
        guard let url = URL(string: panoramicImage.imageURL) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    self.loadLocalImageForSceneKit(completion: completion)
                }
            }
        }.resume()
    }
    
    private func loadLocalImageForSceneKit(completion: @escaping (UIImage?) -> Void) {
        let urlString = panoramicImage.imageURL
        let cleanPath = urlString.hasPrefix("local://") ? String(urlString.dropFirst(8)) : urlString
        
        // Try various paths
        let possiblePaths = [
            cleanPath,
            cleanPath.replacingOccurrences(of: "file://", with: ""),
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent(URL(fileURLWithPath: cleanPath).lastPathComponent).path
        ]
        
        for path in possiblePaths {
            if let image = UIImage(contentsOfFile: path) {
                completion(image)
                return
            }
        }
        
        // Try bundle
        let filename = URL(fileURLWithPath: cleanPath).lastPathComponent
        let baseName = filename.replacingOccurrences(of: ".jpg", with: "")
                              .replacingOccurrences(of: ".jpeg", with: "")
                              .replacingOccurrences(of: ".png", with: "")
        
        if let bundleImage = UIImage(named: baseName) {
            completion(bundleImage)
            return
        }
        
        completion(nil)
    }
    
    private func addAdvancedGestureRecognizers(to arView: ARSCNView, context: Context) {
        // Pan gesture for looking around
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(ImmersiveCoordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        // Pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(ImmersiveCoordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // Double tap to reset
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(ImmersiveCoordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        arView.addGestureRecognizer(doubleTapGesture)
        
        // Long press for quick zoom
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(ImmersiveCoordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        arView.addGestureRecognizer(longPressGesture)
    }
    
    func makeCoordinator() -> ImmersiveCoordinator {
        ImmersiveCoordinator()
    }
}

class ImmersiveCoordinator: NSObject {
    private var currentRotation: SCNVector3 = SCNVector3(0, 0, 0)
    private var isZooming = false
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let arView = gesture.view as? ARSCNView,
              let camera = arView.pointOfView else { return }
        
        let translation = gesture.translation(in: gesture.view)
        let velocity = gesture.velocity(in: gesture.view)
        
        // Enhanced sensitivity based on device
        let sensitivity: Float = UIDevice.current.userInterfaceIdiom == .pad ? 0.008 : 0.01
        
        let rotationX = Float(translation.y) * sensitivity
        let rotationY = Float(translation.x) * sensitivity
        
        switch gesture.state {
        case .began:
            // Stop any ongoing animations
            camera.removeAllAnimations()
            
        case .changed:
            currentRotation.x += rotationX
            currentRotation.y += rotationY
            
            // Enhanced clamping with smooth transitions at limits
            currentRotation.x = max(-Float.pi/2.2, min(Float.pi/2.2, currentRotation.x))
            
            camera.eulerAngles = currentRotation
            gesture.setTranslation(.zero, in: gesture.view)
            
        case .ended:
            // Add momentum for smooth deceleration
            let momentumX = Float(velocity.y) * 0.0001
            let momentumY = Float(velocity.x) * 0.0001
            
            let finalRotationX = currentRotation.x + momentumX
            let finalRotationY = currentRotation.y + momentumY
            
            currentRotation.x = max(-Float.pi/2.2, min(Float.pi/2.2, finalRotationX))
            currentRotation.y = finalRotationY
            
            // Smooth deceleration animation
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.4
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            camera.eulerAngles = currentRotation
            SCNTransaction.commit()
            
        default:
            break
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let arView = gesture.view as? ARSCNView,
              let camera = arView.pointOfView?.camera else { return }
        
        switch gesture.state {
        case .began:
            isZooming = true
            camera.removeAllAnimations()
            
        case .changed:
            let scale = Float(gesture.scale)
            let currentFOV = camera.fieldOfView
            
            // Enhanced zoom range and sensitivity
            let zoomFactor = 1.0 / Double(scale)
            let newFOV = max(15.0, min(120.0, currentFOV * zoomFactor))
            
            camera.fieldOfView = newFOV
            gesture.scale = 1.0
            
        case .ended, .cancelled:
            isZooming = false
            
            // Smooth zoom settling
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            SCNTransaction.commit()
            
        default:
            break
        }
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = gesture.view as? ARSCNView,
              let camera = arView.pointOfView else { return }
        
        currentRotation = SCNVector3(0, 0, 0)
        
        // Smooth reset animation
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        camera.eulerAngles = currentRotation
        camera.camera?.fieldOfView = 75 // Reset to default FOV
        SCNTransaction.commit()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let arView = gesture.view as? ARSCNView,
              let camera = arView.pointOfView?.camera else { return }
        
        switch gesture.state {
        case .began:
            // Quick zoom to 45° FOV
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            camera.fieldOfView = 45.0
            SCNTransaction.commit()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        case .ended, .cancelled:
            // Return to previous FOV
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            camera.fieldOfView = 75.0
            SCNTransaction.commit()
            
        default:
            break
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
    ], property: nil)
}
