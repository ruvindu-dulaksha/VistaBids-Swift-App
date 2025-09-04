//
//  VideoPlayerView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-16.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: String
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var loadingError: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let player = player {
                    VideoPlayer(player: player)
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Loading Video...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                } else if let error = loadingError {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("Failed to Load Video")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        player?.pause()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadVideo()
        }
    }
    
    private func loadVideo() {
        guard let videoURL = URL(string: url) else {
            loadingError = "Invalid video URL"
            isLoading = false
            return
        }
        
        player = AVPlayer(url: videoURL)
        
        // Add observer for player readiness
        player?.currentItem?.publisher(for: \.status)
            .sink { status in
                DispatchQueue.main.async {
                    switch status {
                    case .readyToPlay:
                        isLoading = false
                    case .failed:
                        loadingError = "Failed to load video"
                        isLoading = false
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

import Combine

#Preview {
    VideoPlayerView(url: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4")
}
