//
//  ImmersiveARPanoramaView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-04.
//

import SwiftUI
import ARKit
import SceneKit
import PhotosUI

struct ImmersiveARPanoramaView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingARView = false
    @State private var panoramaType: PanoramaType = .sphere360
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.dismiss) private var dismiss
    
    enum PanoramaType: String, CaseIterable {
        case sphere360 = "360° Sphere"
        case cylinder = "Cylindrical"
        
        var icon: String {
            switch self {
            case .sphere360: return "globe"
            case .cylinder: return "cylinder"
            }
        }
        
        var description: String {
            switch self {
            case .sphere360: return "Full 360° immersive experience"
            case .cylinder: return "Wide panoramic view"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if showingARView, let image = selectedImage {
                    ImmersiveARPanoramaViewerRepresentable(
                        image: image,
                        panoramaType: panoramaType,
                        onClose: {
                            showingARView = false
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    setupView
                }
            }
            .navigationTitle("AR Panorama Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImmersiveImagePicker(
                image: $selectedImage,
                sourceType: imagePickerSourceType
            )
        }
        .alert("Camera not available", isPresented: .constant(!UIImagePickerController.isSourceTypeAvailable(.camera) && showingCamera)) {
            Button("OK") {
                showingCamera = false
            }
        }
    }
    
    private var setupView: some View {
        ScrollView {
            VStack(spacing: 30) {
                headerSection
                
                if let image = selectedImage {
                    selectedImageSection(image)
                } else {
                    imageSelectionSection
                }
                
                panoramaTypeSection
                
                if selectedImage != nil {
                    startARButton
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "arkit")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Immersive AR Panorama")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Upload or capture an image to create an immersive 360° AR experience")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var imageSelectionSection: some View {
        VStack(spacing: 20) {
            Text("Select or Capture Image")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                // Photo Library Button
                Button(action: {
                    imagePickerSourceType = .photoLibrary
                    showingImagePicker = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Photo Library")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.blue, lineWidth: 1)
                    )
                }
                
                // Camera Button
                Button(action: {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        imagePickerSourceType = .camera
                        showingImagePicker = true
                    } else {
                        showingCamera = true
                    }
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("Camera")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.green.opacity(0.1))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.green, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private func selectedImageSection(_ image: UIImage) -> some View {
        VStack(spacing: 16) {
            Text("Selected Image")
                .font(.headline)
                .foregroundColor(.primary)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(15)
                .shadow(radius: 10)
            
            HStack {
                Text("Size: \(Int(image.size.width)) × \(Int(image.size.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Change Image") {
                    selectedImage = nil
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    private var panoramaTypeSection: some View {
        VStack(spacing: 16) {
            Text("Panorama Type")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(PanoramaType.allCases, id: \.self) { type in
                Button(action: {
                    panoramaType = type
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: type.icon)
                            .font(.title2)
                            .foregroundColor(panoramaType == type ? .white : .blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(panoramaType == type ? .white : .primary)
                            
                            Text(type.description)
                                .font(.caption)
                                .foregroundColor(panoramaType == type ? .white.opacity(0.8) : .secondary)
                        }
                        
                        Spacer()
                        
                        if panoramaType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(panoramaType == type ? .blue : .blue.opacity(0.1))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.blue, lineWidth: panoramaType == type ? 0 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var startARButton: some View {
        Button(action: {
            showingARView = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arkit")
                    .font(.title2)
                
                Text("Start AR Experience")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedImage)
    }
}

// AR Panorama Viewer using ARSCNView
struct ImmersiveARPanoramaViewerRepresentable: UIViewRepresentable {
    let image: UIImage
    let panoramaType: ImmersiveARPanoramaView.PanoramaType
    let onClose: () -> Void
    
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
        // Update if needed
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
        
        // Create material with the selected image
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.isDoubleSided = true
        material.cullMode = .front // Show texture from inside
        
        // Apply material to geometry
        geometry.materials = [material]
        
        // Create node and flip it inside-out
        let panoramaNode = SCNNode(geometry: geometry)
        panoramaNode.scale = SCNVector3(-1, 1, 1) // Flip X to show from inside
        
        // Position the camera inside
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add panorama to scene
        scene.rootNode.addChildNode(panoramaNode)
        
        // Set the camera as the point of view
        arView.pointOfView = cameraNode
        
        print("Created panoramic \(panoramaType.rawValue) with image size: \(image.size)")
    }
    
    private func addGestureRecognizers(to arView: ARSCNView, context: Context) {
        // Pan gesture for looking around
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        // Pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // Tap gesture for interactions
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onClose: onClose)
    }
    
    class Coordinator: NSObject {
        let onClose: () -> Void
        private var lastPanLocation: CGPoint = .zero
        private var currentRotation: SCNVector3 = SCNVector3(0, 0, 0)
        
        init(onClose: @escaping () -> Void) {
            self.onClose = onClose
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = gesture.view as? ARSCNView,
                  let camera = arView.pointOfView else { return }
            
            let translation = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            
            // Convert touch movement to rotation
            let rotationX = Float(translation.y) * 0.01
            let rotationY = Float(translation.x) * 0.01
            
            switch gesture.state {
            case .began:
                lastPanLocation = gesture.location(in: gesture.view)
                
            case .changed:
                // Apply rotation to camera
                currentRotation.x += rotationX
                currentRotation.y += rotationY
                
                // Clamp vertical rotation to prevent over-rotation
                currentRotation.x = max(-Float.pi/2, min(Float.pi/2, currentRotation.x))
                
                // Apply rotation
                camera.eulerAngles = currentRotation
                
                // Reset translation
                gesture.setTranslation(.zero, in: gesture.view)
                
            case .ended:
                // Add momentum for smooth feel
                let momentumX = Float(velocity.y) * 0.0001
                let momentumY = Float(velocity.x) * 0.0001
                
                currentRotation.x += momentumX
                currentRotation.y += momentumY
                currentRotation.x = max(-Float.pi/2, min(Float.pi/2, currentRotation.x))
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.3
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
            case .changed:
                let scale = Float(gesture.scale)
                
                // Adjust field of view for zoom effect 
                let currentFOV = camera.fieldOfView
                let newFOV = Double(max(10, min(120, currentFOV / Double(scale))))
                camera.fieldOfView = newFOV
                
                gesture.scale = 1.0
                
            default:
                break
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            if gesture.numberOfTapsRequired == 2 {
                // Double tap to reset view
                guard let arView = gesture.view as? ARSCNView,
                      let camera = arView.pointOfView else { return }
                
                currentRotation = SCNVector3(0, 0, 0)
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                camera.eulerAngles = currentRotation
                camera.camera?.fieldOfView = 60 // Reset FOV
                SCNTransaction.commit()
            }
        }
    }
}

//  Immersive Image Picker
struct ImmersiveImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> ImmersiveImagePickerCoordinator {
        ImmersiveImagePickerCoordinator(self)
    }
    
    class ImmersiveImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImmersiveImagePicker
        
        init(_ parent: ImmersiveImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

//  control ar overlay
struct AROverlayControls: View {
    let onClose: () -> Void
    let onReset: () -> Void
    @State private var showingInstructions = true
    
    var body: some View {
        VStack {
            // Top controls
           /* HStack {
                Button(action: onClose) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                        Text("Exit AR")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.7))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.black.opacity(0.7))
                        .cornerRadius(20)
                }
            }
            .padding()
            
            Spacer()*/
            
            // Bottom instructions
            if showingInstructions {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.draw")
                        Text("Pan to look around")
                    }
                    .foregroundColor(.white)
                    .font(.caption)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "plus.magnifyingglass")
                        Text("Pinch to zoom")
                    }
                    .foregroundColor(.white)
                    .font(.caption)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "hand.tap")
                        Text("Double tap to reset")
                    }
                    .foregroundColor(.white)
                    .font(.caption)
                    
                    Button("Hide Instructions") {
                        withAnimation {
                            showingInstructions = false
                        }
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption2)
                    .padding(.top, 8)
                }
                .padding()
                .background(.black.opacity(0.6))
                .cornerRadius(15)
                .padding()
            } else {
                Button("Show Instructions") {
                    withAnimation {
                        showingInstructions = true
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.black.opacity(0.7))
                .cornerRadius(20)
                .padding()
            }
        }
    }
}

#Preview {
    ImmersiveARPanoramaView()
}
