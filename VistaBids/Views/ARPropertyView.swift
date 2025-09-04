//
//  ARPropertyView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-16.
//

import SwiftUI
import ARKit
import SceneKit

struct ARPropertyView: View {
    let modelURL: String
    @Environment(\.dismiss) private var dismiss
    @State private var arView = ARSCNView()
    @State private var isLoading = true
    @State private var loadingError: String?
    @State private var showingInstructions = true
    
    var body: some View {
        ZStack {
            // AR View
            ARViewRepresentable(
                arView: $arView,
                modelURL: modelURL,
                isLoading: $isLoading,
                loadingError: $loadingError
            )
            .edgesIgnoringSafeArea(.all)
            
            // Overlay Controls
            VStack {
                // Top Controls
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: { showingInstructions.toggle() }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom Controls
                HStack(spacing: 20) {
                    // Reset Position
                    Button(action: resetARSession) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                            Text("Reset")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                    
                    // Take Screenshot
                    Button(action: takeScreenshot) {
                        VStack(spacing: 4) {
                            Image(systemName: "camera")
                                .font(.title2)
                            Text("Photo")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                    
                    // Scale Controls
                    VStack(spacing: 8) {
                        Button(action: { scaleModel(factor: 1.1) }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { scaleModel(factor: 0.9) }) {
                            Image(systemName: "minus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
            }
            
            // Loading Overlay
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Loading 3D Model...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
            }
            
            // Error Overlay
            if let error = loadingError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Failed to Load Model")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
            }
            
            // Instructions Overlay
            if showingInstructions && !isLoading && loadingError == nil {
                VStack(spacing: 16) {
                    Text("AR Instructions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InstructionRow(icon: "move.3d", text: "Move your device to scan the area")
                        InstructionRow(icon: "hand.tap", text: "Tap to place the 3D model")
                        InstructionRow(icon: "hand.point.up.braille", text: "Pinch to scale, drag to rotate")
                        InstructionRow(icon: "camera", text: "Tap photo button to capture")
                    }
                    
                    Button(action: { showingInstructions = false }) {
                        Text("Got it!")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
                .padding()
            }
        }
        .onAppear {
            requestCameraPermission()
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                DispatchQueue.main.async {
                    loadingError = "Camera permission required for AR experience"
                    isLoading = false
                }
            }
        }
    }
    
    private func resetARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func takeScreenshot() {
        let image = arView.snapshot()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Show feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func scaleModel(factor: Float) {
        arView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "property_model" {
                let currentScale = node.scale
                node.scale = SCNVector3(
                    currentScale.x * factor,
                    currentScale.y * factor,
                    currentScale.z * factor
                )
            }
        }
    }
}

// MARK: - AR View Representable
struct ARViewRepresentable: UIViewRepresentable {
    @Binding var arView: ARSCNView
    let modelURL: String
    @Binding var isLoading: Bool
    @Binding var loadingError: String?
    
    func makeUIView(context: Context) -> ARSCNView {
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration)
        
        // Add lighting
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        
        // Add gesture recognizers
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        // Load the 3D model
        context.coordinator.loadModel(from: modelURL)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        let parent: ARViewRepresentable
        private var modelNode: SCNNode?
        private var isModelPlaced = false
        
        init(_ parent: ARViewRepresentable) {
            self.parent = parent
        }
        
        func loadModel(from urlString: String) {
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async {
                    self.parent.loadingError = "Invalid model URL"
                    self.parent.isLoading = false
                }
                return
            }
            
            // For demo purposes, create a simple 3D house model
            // In a real app, you would load the actual 3D model from the URL
            DispatchQueue.global(qos: .userInitiated).async {
                let houseNode = self.createDemoHouseModel()
                
                DispatchQueue.main.async {
                    self.modelNode = houseNode
                    self.parent.isLoading = false
                }
            }
        }
        
        private func createDemoHouseModel() -> SCNNode {
            let houseNode = SCNNode()
            houseNode.name = "property_model"
            
            // House base
            let baseGeometry = SCNBox(width: 2, height: 0.1, length: 2, chamferRadius: 0)
            baseGeometry.firstMaterial?.diffuse.contents = UIColor.brown
            let baseNode = SCNNode(geometry: baseGeometry)
            baseNode.position = SCNVector3(0, 0.05, 0)
            houseNode.addChildNode(baseNode)
            
            // House walls
            let wallGeometry = SCNBox(width: 2, height: 1.5, length: 2, chamferRadius: 0)
            wallGeometry.firstMaterial?.diffuse.contents = UIColor.lightGray
            let wallNode = SCNNode(geometry: wallGeometry)
            wallNode.position = SCNVector3(0, 0.85, 0)
            houseNode.addChildNode(wallNode)
            
            // Roof
            let roofGeometry = SCNPyramid(width: 2.2, height: 0.8, length: 2.2)
            roofGeometry.firstMaterial?.diffuse.contents = UIColor.red
            let roofNode = SCNNode(geometry: roofGeometry)
            roofNode.position = SCNVector3(0, 2.0, 0)
            houseNode.addChildNode(roofNode)
            
            // Door
            let doorGeometry = SCNBox(width: 0.3, height: 0.8, length: 0.05, chamferRadius: 0)
            doorGeometry.firstMaterial?.diffuse.contents = UIColor.brown
            let doorNode = SCNNode(geometry: doorGeometry)
            doorNode.position = SCNVector3(0, 0.5, 1.025)
            houseNode.addChildNode(doorNode)
            
            // Windows
            for i in [-0.5, 0.5] {
                let windowGeometry = SCNBox(width: 0.3, height: 0.3, length: 0.05, chamferRadius: 0)
                windowGeometry.firstMaterial?.diffuse.contents = UIColor.cyan
                let windowNode = SCNNode(geometry: windowGeometry)
                windowNode.position = SCNVector3(Float(i), 0.8, 1.025)
                houseNode.addChildNode(windowNode)
            }
            
            // Scale down the model
            houseNode.scale = SCNVector3(0.1, 0.1, 0.1)
            
            return houseNode
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let modelNode = modelNode, !isModelPlaced else { return }
            
            let location = gesture.location(in: parent.arView)
            let hitTestResults = parent.arView.hitTest(location, types: .featurePoint)
            
            if let result = hitTestResults.first {
                let position = result.worldTransform.columns.3
                modelNode.position = SCNVector3(position.x, position.y, position.z)
                parent.arView.scene.rootNode.addChildNode(modelNode)
                isModelPlaced = true
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let modelNode = modelNode, isModelPlaced else { return }
            
            let scale = Float(gesture.scale)
            modelNode.scale = SCNVector3(
                modelNode.scale.x * scale,
                modelNode.scale.y * scale,
                modelNode.scale.z * scale
            )
            gesture.scale = 1.0
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let modelNode = modelNode, isModelPlaced else { return }
            
            let translation = gesture.translation(in: parent.arView)
            let x = Float(translation.x) * 0.001
            let z = Float(translation.y) * -0.001
            
            modelNode.position = SCNVector3(
                modelNode.position.x + x,
                modelNode.position.y,
                modelNode.position.z + z
            )
            gesture.setTranslation(.zero, in: parent.arView)
        }
        
        // MARK: - ARSessionDelegate
        func session(_ session: ARSession, didFailWithError error: Error) {
            DispatchQueue.main.async {
                self.parent.loadingError = "AR Session failed: \(error.localizedDescription)"
                self.parent.isLoading = false
            }
        }
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    ARPropertyView(modelURL: "demo_model_url")
}
