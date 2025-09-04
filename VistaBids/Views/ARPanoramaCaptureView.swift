import SwiftUI

struct ARPanoramaCaptureView: View {
    @Binding var capturedImages: [UIImage]
    @Binding var isPresented: Bool
    
    @State private var currentStep = 0
    @State private var capturedStepImages: [UIImage] = []
    @State private var showingPreview = false
    
    private let captureSteps = [
        "Point camera forward",
        "Turn left and capture",
        "Turn to back view",
        "Turn right and capture",
        "Capture interior view"
    ]
    
    var body: some View {
        ZStack {
            // AR Camera View
            ARPanoramaCameraView(
                capturedImages: $capturedStepImages,
                isPresented: $isPresented
            )
            .edgesIgnoringSafeArea(.all)
            
            // Overlay UI
            VStack {
                // Top instruction bar
                instructionBar
                
                Spacer()
                
                // Bottom controls
                bottomControls
            }
            .padding()
        }
        .onReceive(NotificationCenter.default.publisher(for: .arImageCaptured)) { notification in
            if let image = notification.object as? UIImage {
                handleImageCaptured(image)
            }
        }
        .sheet(isPresented: $showingPreview) {
            ARPreviewView(
                images: capturedStepImages,
                onSave: {
                    capturedImages = capturedStepImages
                    isPresented = false
                },
                onRetake: {
                    capturedStepImages.removeAll()
                    currentStep = 0
                    showingPreview = false
                }
            )
        }
    }
    
    private var instructionBar: some View {
        VStack(spacing: 8) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<captureSteps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.blue : Color.white.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            
            // Current instruction
            Text(currentStep < captureSteps.count ? captureSteps[currentStep] : "All photos captured!")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
        }
    }
    
    private var bottomControls: some View {
        HStack {
            // Cancel button
            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
            }
            
            Spacer()
            
            // Capture button
            Button(action: captureImage) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                    )
            }
            
            Spacer()
            
            // Done button (when all captured)
            if currentStep >= captureSteps.count {
                Button(action: {
                    showingPreview = true
                }) {
                    Text("Preview")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
            } else {
                // Captured count
                Text("\(capturedStepImages.count)/\(captureSteps.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
            }
        }
    }
    
    private func captureImage() {
        // Trigger image capture via notification
        NotificationCenter.default.post(name: .arCaptureRequested, object: nil)
    }
    
    private func handleImageCaptured(_ image: UIImage) {
        capturedStepImages.append(image)
        if currentStep < captureSteps.count - 1 {
            currentStep += 1
        } else {
            showingPreview = true
        }
    }
}

struct ARPreviewView: View {
    let images: [UIImage]
    let onSave: () -> Void
    let onRetake: () -> Void
    
    @State private var selectedImageIndex = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main image display
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Image(uiImage: images[index])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(maxHeight: 400)
                
                // Image thumbnails
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Button(action: {
                                selectedImageIndex = index
                            }) {
                                Image(uiImage: images[index])
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                selectedImageIndex == index ? Color.blue : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: onRetake) {
                        Text("Retake Photos")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: onSave) {
                        Text("Use These Photos")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("Panorama Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ARPanoramaCaptureView(
        capturedImages: .constant([]),
        isPresented: .constant(true)
    )
}
