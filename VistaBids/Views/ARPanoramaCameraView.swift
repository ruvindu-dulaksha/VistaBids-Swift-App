import SwiftUI
import ARKit
import RealityKit

struct ARPanoramaCameraView: UIViewRepresentable {
    @Binding var capturedImages: [UIImage]
    @Binding var isPresented: Bool
    @State private var currentPanoramaIndex = 0
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session for camera
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration)
        
        // Add gesture recognizer for capture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        
        // Listen for capture requests
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.captureRequested),
            name: .arCaptureRequested,
            object: nil
        )
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update UI if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ARPanoramaCameraView
        var arView: ARView?
        
        init(_ parent: ARPanoramaCameraView) {
            self.parent = parent
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            captureCurrentView(arView)
        }
        
        @objc func captureRequested() {
            guard let arView = arView else { return }
            captureCurrentView(arView)
        }
        
        private func captureCurrentView(_ arView: ARView) {
            // Capture the current AR view as an image
            arView.snapshot(saveToHDR: false) { [weak self] image in
                guard let self = self, let image = image else { return }
                
                DispatchQueue.main.async {
                    self.parent.capturedImages.append(image)
                    
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // Auto advance panorama index
                    self.parent.currentPanoramaIndex += 1
                    
                    // Notify that image was captured
                    NotificationCenter.default.post(name: .arImageCaptured, object: image)
                }
            }
        }
    }
}


