//
//  ARDemoView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-04.
//

import SwiftUI

struct ARDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingImmersiveAR = false
    @State private var showingEnhancedAR = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    featuresSection
                    
                    demoButtonsSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("AR Studio Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingImmersiveAR) {
            ImmersiveARPanoramaView()
        }
        .fullScreenCover(isPresented: $showingEnhancedAR) {
            ARPanoramicView(panoramicImages: samplePanoramicImages, property: nil)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "arkit")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            Text("Enhanced AR Panoramic Experience")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Experience immersive 360° AR views with enhanced controls and image capture capabilities")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Features")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FeatureCard(
                    icon: "arkit",
                    title: "SceneKit Mode",
                    description: "Enhanced immersion with SceneKit rendering"
                )
                
                FeatureCard(
                    icon: "camera.fill",
                    title: "Image Capture",
                    description: "Capture or select panoramic images"
                )
                
                FeatureCard(
                    icon: "hand.draw",
                    title: "Enhanced Controls",
                    description: "Pan, pinch, and gesture controls"
                )
                
                FeatureCard(
                    icon: "sparkles",
                    title: "Immersive View",
                    description: "Inside-out sphere rendering"
                )
            }
        }
    }
    
    private var demoButtonsSection: some View {
        VStack(spacing: 20) {
            Text("Try the AR Experiences")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // New Immersive AR Studio
                Button(action: {
                    showingImmersiveAR = true
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "arkit")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Immersive AR Studio")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Create your own panoramic AR experience")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.blue, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                // Enhanced AR View with existing panoramic images
                Button(action: {
                    showingEnhancedAR = true
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "cube.transparent")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enhanced AR Tour")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Experience sample properties with dual modes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.purple, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var samplePanoramicImages: [PanoramicImage] {
        [
            PanoramicImage(
                id: "demo_1",
                imageURL: "sample_panorama", // This should be replaced with actual panoramic images
                title: "Luxury Living Room",
                description: "Spacious living room with ocean view and modern furnishing",
                roomType: .livingRoom,
                captureDate: Date(),
                isAREnabled: true
            ),
            PanoramicImage(
                id: "demo_2",
                imageURL: "sample_panorama",
                title: "Gourmet Kitchen",
                description: "Professional kitchen with island and premium appliances",
                roomType: .kitchen,
                captureDate: Date(),
                isAREnabled: true
            ),
            PanoramicImage(
                id: "demo_3",
                imageURL: "sample_panorama",
                title: "Master Bedroom",
                description: "Elegant master suite with walk-in closet",
                roomType: .bedroom,
                captureDate: Date(),
                isAREnabled: true
            )
        ]
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ARDemoView()
}
