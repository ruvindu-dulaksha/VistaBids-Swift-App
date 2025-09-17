//
//  WalkthroughVideoPlayer.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-18.
//

import SwiftUI
import AVKit
import AVFoundation

struct WalkthroughVideoPlayer: View {
    let videoURL: String
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var showControls = true
    @State private var isFullScreen = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if let player = player {
                    WalkthroughVideoPlayerView(player: player)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showControls.toggle()
                            }
                        }
                        .overlay(
                            customControls,
                            alignment: .bottom
                        )
                } else {
                    VStack(spacing: 20) {
                        ProgressView("Loading video...")
                            .foregroundColor(.white)
                        
                        Text("Preparing walkthrough video")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                }
            }
            .navigationBarHidden(!showControls)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        player?.pause()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isFullScreen.toggle()
                    }) {
                        Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private var customControls: some View {
        VStack {
            if showControls {
                VStack(spacing: 16) {
                    // Progress bar
                    VStack(spacing: 8) {
                        Slider(
                            value: $currentTime,
                            in: 0...max(duration, 1),
                            onEditingChanged: { editing in
                                if !editing {
                                    player?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
                                }
                            }
                        )
                        .accentColor(.white)
                        
                        HStack {
                            Text(formatTime(currentTime))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text(formatTime(duration))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // Control buttons
                    HStack(spacing: 40) {
                        Button(action: rewind) {
                            Image(systemName: "gobackward.10")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: togglePlayPause) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: fastForward) {
                            Image(systemName: "goforward.10")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .transition(.opacity)
            }
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoURL) else {
            print("Invalid video URL: \(videoURL)")
            return
        }
        
        player = AVPlayer(url: url)
        
        // Setup time observer
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            currentTime = time.seconds
        }
        
        // Get duration when ready
        player?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                if let duration = player?.currentItem?.duration {
                    self.duration = duration.seconds
                }
            }
        }
        
        // Observe playback status
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            isPlaying = false
            currentTime = 0
            player?.seek(to: .zero)
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    private func rewind() {
        let newTime = max(currentTime - 10, 0)
        player?.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        currentTime = newTime
    }
    
    private func fastForward() {
        let newTime = min(currentTime + 10, duration)
        player?.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        currentTime = newTime
    }
    
    private func formatTime(_ time: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: time) ?? "0:00"
    }
}

struct WalkthroughVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)
        
        DispatchQueue.main.async {
            playerLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
}

// Walkthrough Video Card
struct WalkthroughVideoCard: View {
    let videoURL: String
    let title: String
    let duration: String?
    @State private var showingVideoPlayer = false
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: {
            showingVideoPlayer = true
        }) {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [.orange.opacity(0.6), .red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 160)
                    
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .clipped()
                            .cornerRadius(12)
                    }
                    
                    // Play button overlay
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.6))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .offset(x: 2) 
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Image(systemName: "video.fill")
                                    .font(.caption)
                                Text("HD")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6))
                            .cornerRadius(8)
                        }
                        .padding(8)
                        
                        Spacer()
                        
                        if let duration = duration {
                            HStack {
                                Spacer()
                                
                                Text(duration)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.black.opacity(0.8))
                                    .cornerRadius(6)
                            }
                            .padding(8)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.accentColor)
                        Text("Walkthrough Video")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.top, 12)
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            WalkthroughVideoPlayer(videoURL: videoURL)
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        guard let url = URL(string: videoURL) else { return }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 600)
        
        DispatchQueue.global(qos: .background).async {
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    self.thumbnail = uiImage
                }
            } catch {
                print("Error generating thumbnail: \(error)")
            }
        }
    }
}

#Preview {
    VStack {
        WalkthroughVideoCard(
            videoURL: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
            title: "Property Walkthrough",
            duration: "3:45"
        )
        .padding()
        
        Spacer()
    }
}
