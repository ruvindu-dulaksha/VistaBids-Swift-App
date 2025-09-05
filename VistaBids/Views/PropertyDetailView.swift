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

struct PropertyDetailView: View {
    let property: AuctionProperty
    let biddingService: BiddingService
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
                PlaceBidView(property: property, biddingService: biddingService)
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
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
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
                    
                    // Add Video Button (placeholder for future functionality)
                    Button(action: {
                        // TODO: Add video upload functionality
                    }) {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.accentBlues)
                            
                            Text("Add Video")
                                .font(.caption)
                                .foregroundColor(.textPrimary)
                        }
                        .frame(width: 120, height: 80)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentBlues.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                    }
                }
                .padding(.horizontal)
            }
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
}

// MARK: - Video Thumbnail View
struct VideoThumbnailView: View {
    let videoURL: String
    let title: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 120, height: 80)
                    .cornerRadius(8)
                
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
