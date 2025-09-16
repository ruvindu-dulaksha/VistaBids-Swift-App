//
//  PropertyDetailView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-16.
//

import SwiftUI
import MapKit
import ARKit
import AVKit
import FirebaseFirestore
import FirebaseAuth
import PhotosUI
import Intents
import IntentsUI

struct PropertyDetailView: View {
    @State private var property: AuctionProperty
    let biddingService: BiddingService
    @EnvironmentObject private var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex = 0
    @State private var showingBidSheet = false
    @State private var showingChatSheet = false
    @State private var showingARView = false
    @State private var showingPanoramicAR = false
    @State private var showingVideoPlayer = false
    @State private var selectedVideoURL: String?
    @State private var showingMap = false
    @State private var timeRemaining = ""
    @State private var timer: Timer?
    @State private var selectedVideos: [PhotosPickerItem] = []
    @State private var isUploadingVideo = false
    @State private var showingVideoUploadSheet = false
    @State private var uploadProgress = 0.0
    @State private var showingUploadAlert = false
    @State private var propertyListener: ListenerRegistration?
    private let db = Firestore.firestore()
    @State private var uploadAlertMessage = ""
    @State private var siriKitManager = SiriKitManager.shared
    
    init(property: AuctionProperty, biddingService: BiddingService) {
        self._property = State(initialValue: property)
        self.biddingService = biddingService
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Image Gallery
                    imageGallery
                    
                    // Property Info
                    propertyInfo
                    
                    // Bidding Section
                    biddingSection
                    
                    // Features
                    featuresSection
                    
                    // Location
                    locationSection
                    
                    // Videos Section
                    if !property.videos.isEmpty || (property.walkthroughVideoURL?.isEmpty == false) {
                        videosSection
                    }
                    
                    // AR Experience Section
                    if !property.panoramicImages.isEmpty || (property.arModelURL?.isEmpty == false) {
                        arSection
                    }
                    
                    // Description
                    descriptionSection
                    
                    // Bid History
                    bidHistorySection
                }
                .padding()
            }
            .navigationTitle("Property Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Watchlist Button
                        Button(action: {
                            Task {
                                if biddingService.isInWatchlist(propertyId: property.id ?? "") {
                                    try await biddingService.removeFromWatchlist(propertyId: property.id ?? "")
                                } else {
                                    try await biddingService.addToWatchlist(propertyId: property.id ?? "")
                                }
                            }
                        }) {
                            Image(systemName: biddingService.isInWatchlist(propertyId: property.id ?? "") ? "heart.fill" : "heart")
                                .foregroundColor(biddingService.isInWatchlist(propertyId: property.id ?? "") ? .red : .primary)
                        }
                        
                        // Chat Button
                        if property.status == .active {
                            Button(action: { showingChatSheet = true }) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .foregroundColor(.accentBlues)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingBidSheet) {
                PlaceBidView(
                    property: property, 
                    biddingService: biddingService,
                    onBidPlaced: {
                        Task {
                            try await refreshProperty()
                        }
                    }
                )
            }
            .sheet(isPresented: $showingChatSheet) {
                AuctionChatView(property: property, biddingService: biddingService)
            }
            .sheet(isPresented: $showingARView) {
                if let arModelURL = property.arModelURL {
                    ARPropertyView(modelURL: arModelURL)
                }
            }
            .sheet(isPresented: $showingPanoramicAR) {
                ARPanoramicView(panoramicImages: property.panoramicImages, property: property)
            }
            .sheet(isPresented: $showingVideoPlayer) {
                if let videoURL = selectedVideoURL {
                    VideoPlayerView(url: videoURL)
                }
            }
            .sheet(isPresented: $showingMap) {
                PropertyMapView(properties: [property])
            }
            .onAppear {
                startTimer()
                startPropertyListener()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startPropertyListener() {
        if propertyListener != nil {
            propertyListener?.remove()
        }
        
        guard let propertyId = property.id else { return }
        
        propertyListener = db.collection("auction_properties").document(propertyId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to property updates: \(error)")
                    return
                }
                
                guard let document = snapshot,
                      document.exists,
                      let updatedProperty = try? document.data(as: AuctionProperty.self) else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.property = updatedProperty
                }
            }
    }
    
    private func refreshProperty() async throws {
        guard let propertyId = property.id else { return }
        try await biddingService.refreshProperty(propertyId: propertyId)
        
        // Update local property with the refreshed data
        if let updatedProperty = biddingService.auctionProperties.first(where: { $0.id == propertyId }) {
            await MainActor.run {
                self.property = updatedProperty
            }
        }
    }
    
    // MARK: - SiriKit Integration
    
    @available(iOS 13.0, *)
    private func addBidShortcutToSiri() {
        print("🎤 SiriKit: Adding bid shortcut to Siri for property: \(property.title)")
        
        // Create and donate user activity for this property
        let userActivity = siriKitManager.createBiddingUserActivity(property: property)
        userActivity.becomeCurrent()
        
        // Create quick bid shortcuts for common amounts
        let commonBids = [
            "\(Int(property.currentBid + 10000))",
            "\(Int(property.currentBid + 25000))",
            "\(Int(property.currentBid + 50000))"
        ]
        
        for bidAmount in commonBids {
            siriKitManager.createQuickBidShortcut(amount: bidAmount, propertyTitle: property.title)
        }
        
        // Show success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("✅ SiriKit: Bid shortcuts created successfully")
    }
    
    private var imageGallery: some View {
        VStack {
            // Main Image
            TabView(selection: $selectedImageIndex) {
                ForEach(0..<max(property.images.count, 1), id: \.self) { index in
                    if property.images.isEmpty {
                        // Placeholder when no images
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("No Images Available")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }
                            )
                            .frame(height: 250)
                            .clipped()
                            .tag(index)
                    } else {
                        AsyncImage(url: URL(string: property.images[index])) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(_):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo")
                                                .font(.title)
                                                .foregroundColor(.gray)
                                            Text("Failed to load image")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(1.2)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .frame(height: 250)
                        .clipped()
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .frame(height: 250)
            .cornerRadius(12)
            
            // Image Thumbnails
            if property.images.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<property.images.count, id: \.self) { index in
                            AsyncImage(url: URL(string: property.images[index])) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure(_):
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        )
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        )
                                @unknown default:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                            }
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedImageIndex == index ? Color.accentBlues : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedImageIndex = index
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else if property.images.isEmpty {
                Text("No additional images")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    private var propertyInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(property.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text(property.status.displayText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(property.status.color)
                    .cornerRadius(6)
            }
            
            Text(property.address.fullAddress)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .onTapGesture {
                    showingMap = true
                }
            
            Text(property.category.rawValue)
                .font(.caption)
                .foregroundColor(.accentBlues)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentBlues.opacity(0.1))
                .cornerRadius(6)
        }
    }
    
    private var biddingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auction Information")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Current Bid:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(property.currentBid, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentBlues)
                }
                
                HStack {
                    Text("Starting Price:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(property.startingPrice, specifier: "%.0f")")
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)
                }
                
                if let highestBidder = property.highestBidderName {
                    HStack {
                        Text("Highest Bidder:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(highestBidder)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                HStack {
                    Text("Total Bids:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(property.bidHistory.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }
                
                Divider()
                
                if property.status == .active {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.red)
                        Text("Time Remaining:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(timeRemaining)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                } else if property.status == .upcoming {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                        Text("Starts:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(property.auctionStartTime, style: .relative)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            
            if property.status == .active {
                Button(action: { showingBidSheet = true }) {
                    Text("Place Bid")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentBlues)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property Features")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                PropertyFeatureItem(icon: "bed.double", title: "Bedrooms", value: "\(property.features.bedrooms)")
                PropertyFeatureItem(icon: "bathtub", title: "Bathrooms", value: "\(property.features.bathrooms)")
                PropertyFeatureItem(icon: "square", title: "Area", value: "\(String(format: "%.0f", property.features.area)) sq ft")
                PropertyFeatureItem(icon: "calendar", title: "Built", value: property.features.yearBuilt.map { "\($0)" } ?? "N/A")
                
                if let parking = property.features.parkingSpaces {
                    PropertyFeatureItem(icon: "car.fill", title: "Parking", value: "\(parking)")
                }
                
                if property.features.hasGarden {
                    PropertyFeatureItem(icon: "leaf.fill", title: "Garden", value: "Yes")
                }
                
                if property.features.hasPool {
                    PropertyFeatureItem(icon: "figure.pool.swim", title: "Pool", value: "Yes")
                }
                
                if property.features.hasGym {
                    PropertyFeatureItem(icon: "dumbbell.fill", title: "Gym", value: "Yes")
                }
            }
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Button(action: { showingMap = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.address.street)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        Text("\(property.address.city), \(property.address.state)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "map")
                        .foregroundColor(.accentBlues)
                    
                    Text("View on Map")
                        .font(.caption)
                        .foregroundColor(.accentBlues)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property Videos")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Walkthrough Video
                    if let walkthroughURL = property.walkthroughVideoURL, !walkthroughURL.isEmpty {
                        VideoThumbnailView(
                            videoURL: walkthroughURL,
                            title: "Property Walkthrough",
                            onTap: {
                                selectedVideoURL = walkthroughURL
                                showingVideoPlayer = true
                            }
                        )
                    }
                    
                    // Additional Videos
                    ForEach(property.videos, id: \.self) { videoURL in
                        VideoThumbnailView(
                            videoURL: videoURL,
                            title: "Property Tour",
                            onTap: {
                                selectedVideoURL = videoURL
                                showingVideoPlayer = true
                            }
                        )
                    }
                    
                    // Add Video Button with proper implementation
                    if isCurrentUserOwner() {
                        PhotosPicker(
                            selection: $selectedVideos,
                            maxSelectionCount: 1,
                            matching: .videos
                        ) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.accentBlues)
                                
                                Text("Add Video")
                                    .font(.caption)
                                    .foregroundColor(.textPrimary)
                                
                                if isUploadingVideo {
                                    ProgressView(value: uploadProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(width: 80)
                                }
                            }
                            .frame(width: 120, height: 80)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentBlues.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                        }
                        .onChange(of: selectedVideos) { items in
                            if !items.isEmpty, let item = items.first {
                                uploadVideo(item: item)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .alert(isPresented: $showingUploadAlert) {
            Alert(
                title: Text("Video Upload"),
                message: Text(uploadAlertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var arSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AR Experience")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            // Panoramic AR Views
            if !property.panoramicImages.isEmpty {
                Button(action: { showingPanoramicAR = true }) {
                    HStack {
                        Image(systemName: "view.3d")
                            .font(.title2)
                            .foregroundColor(.accentBlues)
                        
                        VStack(alignment: .leading) {
                            Text("360° Panoramic View")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            Text("Experience \(property.panoramicImages.count) panoramic views in AR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 3D Model AR (if available)
            if let arModelURL = property.arModelURL, !arModelURL.isEmpty {
                Button(action: { showingARView = true }) {
                    HStack {
                        Image(systemName: "arkit")
                            .font(.title2)
                            .foregroundColor(.accentBlues)
                        
                        VStack(alignment: .leading) {
                            Text("3D Model View")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            Text("View 3D model in augmented reality")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // No AR Content Available
            if property.panoramicImages.isEmpty && (property.arModelURL?.isEmpty != false) {
                HStack {
                    Image(systemName: "arkit")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading) {
                        Text("AR Experience")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        Text("No AR content available for this property")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text(property.description)
                .font(.body)
                .foregroundColor(.textPrimary)
                .lineSpacing(4)
        }
    }
    
    private var bidHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Bids")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if property.bidHistory.isEmpty {
                Text("No bids yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(property.bidHistory.suffix(5).reversed(), id: \.id) { bid in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bid.bidderName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            Text(bid.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("$\(bid.amount, specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.accentBlues)
                    }
                    .padding(.vertical, 8)
                    
                    if bid.id != property.bidHistory.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeRemaining()
        }
        updateTimeRemaining()
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        let timeInterval = property.auctionEndTime.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            timeRemaining = "Auction Ended"
            timer?.invalidate()
        } else {
            let days = Int(timeInterval) / 86400
            let hours = Int(timeInterval.truncatingRemainder(dividingBy: 86400)) / 3600
            let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
            
            if days > 0 {
                timeRemaining = "\(days)d \(hours)h \(minutes)m"
            } else if hours > 0 {
                timeRemaining = "\(hours)h \(minutes)m \(seconds)s"
            } else {
                timeRemaining = "\(minutes)m \(seconds)s"
            }
        }
    }
    
    private func isCurrentUserOwner() -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }
        return currentUserId == property.sellerId
    }
    
    private func uploadVideo(item: PhotosPickerItem) {
        guard let propertyId = property.id else {
            uploadAlertMessage = "Cannot upload video: Missing property ID"
            showingUploadAlert = true
            return
        }
        
        isUploadingVideo = true
        uploadProgress = 0.1
        
        Task {
            do {
                guard let videoData = try await item.loadTransferable(type: Data.self) else {
                    await MainActor.run {
                        isUploadingVideo = false
                        uploadAlertMessage = "Failed to load video data"
                        showingUploadAlert = true
                    }
                    return
                }
                
                // Check file size - limit to 5MB for Firestore (Firestore has a 1MB limit per document)
                if videoData.count > 5 * 1024 * 1024 {
                    await MainActor.run {
                        isUploadingVideo = false
                        uploadAlertMessage = "Video too large. Please select a video under 5MB for direct storage."
                        showingUploadAlert = true
                    }
                    return
                }
                
                await MainActor.run {
                    uploadProgress = 0.3
                }
                
                // Store video locally and reference it
                let fileName = "\(UUID().uuidString).mp4"
                let videoURL = try await saveVideoLocally(data: videoData, fileName: fileName)
                
                // Update progress
                await MainActor.run {
                    uploadProgress = 0.7
                }
                
                // Add local URL reference to Firestore
                updatePropertyWithLocalVideo(propertyId: propertyId, videoURL: videoURL)
            } catch {
                await MainActor.run {
                    isUploadingVideo = false
                    uploadAlertMessage = "Error processing video: \(error.localizedDescription)"
                    showingUploadAlert = true
                }
            }
        }
    }
    
    private func saveVideoLocally(data: Data, fileName: String) async throws -> String {
        // Get documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoDirectory = documentsDirectory.appendingPathComponent("videos", isDirectory: true)
        
        // Create videos directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: videoDirectory.path) {
            try FileManager.default.createDirectory(at: videoDirectory, withIntermediateDirectories: true)
        }
        
        // Create file URL
        let fileURL = videoDirectory.appendingPathComponent(fileName)
        
        // Write data to file
        try data.write(to: fileURL)
        
        // Return local URL scheme
        return "local://videos/\(fileName)"
    }
    
    private func updatePropertyWithLocalVideo(propertyId: String, videoURL: String) {
        let db = Firestore.firestore()
        let propertyRef = db.collection("properties").document(propertyId)
        
        propertyRef.updateData([
            "videos": FieldValue.arrayUnion([videoURL])
        ]) { error in
            DispatchQueue.main.async {
                self.isUploadingVideo = false
                
                if let error = error {
                    self.uploadProgress = 0
                    self.uploadAlertMessage = "Failed to update property data: \(error.localizedDescription)"
                    self.showingUploadAlert = true
                } else {
                    self.uploadProgress = 1.0
                    self.uploadAlertMessage = "Video uploaded successfully!"
                    self.showingUploadAlert = true
                    self.selectedVideos = []
                    
                    // Refresh property data
                    Task {
                        try await self.biddingService.refreshProperty(propertyId: propertyId)
                    }
                }
            }
        }
    }
}

// MARK: - Video Thumbnail View
struct VideoThumbnailView: View {
    let videoURL: String
    let title: String
    let onTap: () -> Void
    @State private var thumbnailImage: UIImage? = nil
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let thumbnail = thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            Rectangle()
                                .fill(Color.black.opacity(0.2))
                                .cornerRadius(8)
                        )
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 120, height: 80)
                        .cornerRadius(8)
                }
                
                VStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        // Handle local URLs first
        if videoURL.hasPrefix("local://") {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let cleanPath = videoURL.replacingOccurrences(of: "local://", with: "")
            let fileURL = documentsDirectory.appendingPathComponent(cleanPath)
            
            createThumbnail(from: fileURL)
            return
        }
        
        // Handle remote URLs
        guard let url = URL(string: videoURL) else { return }
        createThumbnail(from: url)
    }
    
    private func createThumbnail(from url: URL) {
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 60), actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    self.thumbnailImage = thumbnail
                }
            } catch {
                print("Error generating thumbnail: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Property Feature Item
struct PropertyFeatureItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentBlues)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(8)
    }
}

#Preview {
    PropertyDetailView(
        property: AuctionProperty(
            sellerId: "seller1",
            sellerName: "John Doe",
            title: "Modern Villa",
            description: "Beautiful modern villa with stunning views and premium finishes.",
            startingPrice: 500000,
            currentBid: 550000,
            highestBidderId: "bidder1",
            highestBidderName: "Jane Smith",
            images: [],
            videos: [],
            arModelURL: nil,
            address: PropertyAddress(
                street: "123 Main Street",
                city: "Colombo",
                state: "Western Province",
                postalCode: "00100",
                country: "Sri Lanka"
            ),
            location: GeoPoint(latitude: 6.9271, longitude: 79.8612),
            features: PropertyFeatures(
                bedrooms: 4,
                bathrooms: 3,
                area: 2500,
                yearBuilt: 2020,
                parkingSpaces: 2,
                hasGarden: true,
                hasPool: true,
                hasGym: false,
                floorNumber: nil,
                totalFloors: nil,
                propertyType: "Villa"
            ),
            auctionStartTime: Date().addingTimeInterval(-3600),
            auctionEndTime: Date().addingTimeInterval(7200),
            auctionDuration: .oneHour,
            status: .active,
            category: .luxury,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: Date(),
            updatedAt: Date(),
            panoramicImages: [],
            walkthroughVideoURL: nil
        ),
        biddingService: BiddingService()
    )
}
