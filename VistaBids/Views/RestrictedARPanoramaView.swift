//
//  RestrictedARPanoramaView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-04.
//

import SwiftUI
import ARKit
import SceneKit

/// A viewing-only version of the AR panorama view for use within property browsing
/// This version does NOT allow image capture or upload - only viewing existing panoramic images
struct RestrictedARPanoramaView: View {
    let panoramicImage: PanoramicImage
    @Environment(\.dismiss) private var dismiss
    @State private var panoramaType: PanoramaType = .sphere360
    
    enum PanoramaType: String, CaseIterable {
        case sphere360 = "360° Sphere"
        case cylinder = "Cylindrical"
        
        var icon: String {
            switch self {
            case .sphere360: return "globe"
            case .cylinder: return "cylinder"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Only show the AR viewer - no image capture options
                RestrictedARViewerRepresentable(
                    panoramicImage: panoramicImage,
                    panoramaType: panoramaType
                )
                .ignoresSafeArea()
                
                // Overlay controls
                VStack {
                    // Top controls
                    HStack {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.7))
                        .cornerRadius(20)
                        
                        Spacer()
                        
                        // Panorama type toggle
                        Picker("Type", selection: $panoramaType) {
                            ForEach(PanoramaType.allCases, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.7))
                        .cornerRadius(15)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom info
                    VStack(spacing: 12) {
                        Text(panoramicImage.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let description = panoramicImage.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        HStack(spacing: 16) {
                            Label("Pan to look around", systemImage: "hand.draw")
                            Label("Pinch to zoom", systemImage: "plus.magnifyingglass")
                            Label("Double tap to reset", systemImage: "arrow.counterclockwise")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(.black.opacity(0.6))
                    .cornerRadius(15)
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

//  Restricted AR Viewer (View Only)
struct RestrictedARViewerRepresentable: UIViewRepresentable {
    let panoramicImage: PanoramicImage
    let panoramaType: RestrictedARPanoramaView.PanoramaType
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        configuration.isLightEstimationEnabled = false
        
        arView.session.run(configuration)
        arView.automaticallyUpdatesLighting = false
        arView.antialiasingMode = .multisampling4X
        
        // Create panoramic geometry
        createPanoramicGeometry(in: arView)
        
        // Add gesture recognizers
        addGestureRecognizers(to: arView, context: context)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Update panorama type if changed
        updatePanoramicGeometry(in: uiView)
    }
    
    private func createPanoramicGeometry(in arView: ARSCNView) {
        let scene = SCNScene()
        arView.scene = scene
        
        // Create geometry based on panorama type
        let geometry: SCNGeometry
        
        switch panoramaType {
        case .sphere360:
            geometry = SCNSphere(radius: 10.0)
        case .cylinder:
            geometry = SCNCylinder(radius: 10.0, height: 10.0)
        }
        
        // Load and apply panoramic image
        loadPanoramicImage { image in
            DispatchQueue.main.async {
                let material = SCNMaterial()
                
                if let image = image {
                    material.diffuse.contents = image
                } else {
                    // Fallback material
                    material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.3)
                }
                
                material.isDoubleSided = true
                material.cullMode = .front
                material.lightingModel = .constant
                
                geometry.materials = [material]
                
                // Create node and flip it inside-out
                let panoramaNode = SCNNode(geometry: geometry)
                panoramaNode.scale = SCNVector3(-1, 1, 1)
                
                // Set up camera
                let cameraNode = SCNNode()
                cameraNode.camera = SCNCamera()
                cameraNode.camera?.fieldOfView = 75
                cameraNode.position = SCNVector3(0, 0, 0)
                
                // Add to scene
                scene.rootNode.addChildNode(cameraNode)
                scene.rootNode.addChildNode(panoramaNode)
                arView.pointOfView = cameraNode
            }
        }
    }
    
    private func updatePanoramicGeometry(in arView: ARSCNView) {
        // Re-create geometry if panorama type changes
        createPanoramicGeometry(in: arView)
    }
    
    private func loadPanoramicImage(completion: @escaping (UIImage?) -> Void) {
        let urlString = panoramicImage.imageURL
        
        // Handle local URLs
        if urlString.hasPrefix("local://") {
            let cleanPath = String(urlString.dropFirst(8))
            
            // Try various local paths
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
            
            
            let filename = URL(fileURLWithPath: cleanPath).lastPathComponent
            let baseName = filename.replacingOccurrences(of: ".jpg", with: "")
                                  .replacingOccurrences(of: ".jpeg", with: "")
                                  .replacingOccurrences(of: ".png", with: "")
            
            if let bundleImage = UIImage(named: baseName) {
                completion(bundleImage)
                return
            }
        }
        
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        completion(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }.resume()
        } else {
            completion(nil)
        }
    }
    
    private func addGestureRecognizers(to arView: ARSCNView, context: Context) {
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(RestrictedCoordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(RestrictedCoordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(RestrictedCoordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        arView.addGestureRecognizer(doubleTapGesture)
    }
    
    func makeCoordinator() -> RestrictedCoordinator {
        RestrictedCoordinator()
    }
}

class RestrictedCoordinator: NSObject {
    private var currentRotation: SCNVector3 = SCNVector3(0, 0, 0)
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let arView = gesture.view as? ARSCNView,
              let camera = arView.pointOfView else { return }
        
        let translation = gesture.translation(in: gesture.view)
        let rotationX = Float(translation.y) * 0.01
        let rotationY = Float(translation.x) * 0.01
        
        currentRotation.x += rotationX
        currentRotation.y += rotationY
        
        // Clamp vertical rotation
        currentRotation.x = max(-Float.pi/2, min(Float.pi/2, currentRotation.x))
        
        camera.eulerAngles = currentRotation
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let arView = gesture.view as? ARSCNView,
              let camera = arView.pointOfView?.camera else { return }
        
        let scale = Float(gesture.scale)
        let currentFOV = camera.fieldOfView
        let newFOV = Double(max(15, min(120, currentFOV / Double(scale))))
        camera.fieldOfView = newFOV
        
        gesture.scale = 1.0
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = gesture.view as? ARSCNView,
              let camera = arView.pointOfView else { return }
        
        currentRotation = SCNVector3(0, 0, 0)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        camera.eulerAngles = currentRotation
        camera.camera?.fieldOfView = 75
        SCNTransaction.commit()
    }
}

#Preview {
    RestrictedARPanoramaView(
        panoramicImage: PanoramicImage(
            id: "1",
            imageURL: "sample_panorama",
            title: "Living Room",
            description: "Viewing only - no image upload allowed",
            roomType: .livingRoom,
            captureDate: Date(),
            isAREnabled: true
        )
    )
}
