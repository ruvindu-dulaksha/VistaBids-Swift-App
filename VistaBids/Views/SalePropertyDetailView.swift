//
//  SalePropertyDetailView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-17.
//

import SwiftUI
import MapKit
import PhotosUI
import UIKit
import RealityKit
import ARKit
import AVKit

struct SalePropertyDetailView: View {
    let property: SaleProperty
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex = 0
    @State private var showingContactSheet = false
    @State private var showingMap = false
    @State private var showingCallAlert = false
    @State private var showingPhotoViewer = false
    @State private var showingARView = false
    @State private var showingVideoPlayer = false
    @State private var isInWishlist = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Image Gallery
                    imageGallery
                    
                    // Property Info
                    propertyInfo
                    
                    // Price Section
                    priceSection
                    
                    // Features
                    featuresSection
                    
                    // Location
                    locationSection
                    
                    // Description
                    descriptionSection
                    
                    // Seller Info
                    sellerSection
                    
                    // Contact Actions
                    contactActionsSection
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
                        Button(action: toggleWishlist) {
                            Image(systemName: isInWishlist ? "heart.fill" : "heart")
                                .foregroundColor(isInWishlist ? .red : .accentBlues)
                        }
                        
                        Button(action: shareProperty) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.accentBlues)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingContactSheet) {
                ContactSellerSheet(property: property)
            }
            .sheet(isPresented: $showingMap) {
                SalePropertyMapView(property: property)
            }
            .sheet(isPresented: $showingARView) {
                ARPanoramicView(panoramicImages: property.panoramicImages)
            }
            .sheet(isPresented: $showingVideoPlayer) {
                if let videoURL = property.walkthroughVideoURL {
                    WalkthroughVideoPlayer(videoURL: videoURL)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                PropertyShareView(property: property)
            }
            .alert("Call Seller", isPresented: $showingCallAlert) {
                Button("Call Now") {
                    makePhoneCall()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Would you like to call \(property.seller.name) at \(property.seller.phone ?? "N/A")?")
            }
            .onAppear {
                loadWishlistStatus()
            }
        }
    }
    
    private var imageGallery: some View {
        VStack {
            // Main Image
            if property.images.isEmpty {
                // Show placeholder when no images
                Image("loginlogo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No images available")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                    )
            } else {
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<property.images.count, id: \.self) { index in
                        AsyncImage(url: URL(string: property.images[index])) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(ProgressView())
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(_):
                                // Fallback to local placeholder
                                Image("loginlogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            @unknown default:
                                Image("loginlogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                        }
                        .frame(height: 250)
                        .clipped()
                        .tag(index)
                        .onTapGesture {
                            showingPhotoViewer = true
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 250)
                .cornerRadius(12)
            }
            
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
                                case .failure(_), .empty:
                                    Image("loginlogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                @unknown default:
                                    Image("loginlogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
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
            }
            
            // AR Panoramic and Video Section
            if property.panoramicImages.count > 0 || property.hasWalkthroughVideo {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arkit")
                            .foregroundColor(.accentBlues)
                        Text("Immersive Experience")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        // AR Panoramic View Button
                        if property.panoramicImages.count > 0 {
                            Button(action: { showingARView = true }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(LinearGradient(
                                                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(height: 80)
                                        
                                        VStack(spacing: 4) {
                                            Image(systemName: "view.3d")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                            
                                            Text("360° AR Tour")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    Text("\(property.panoramicImages.count) Views")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Video Walkthrough Button
                        if property.hasWalkthroughVideo {
                            Button(action: { showingVideoPlayer = true }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(LinearGradient(
                                                colors: [.orange.opacity(0.6), .red.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(height: 80)
                                        
                                        VStack(spacing: 4) {
                                            Image(systemName: "play.rectangle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                            
                                            Text("Video Tour")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    Text("HD Walkthrough")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if property.panoramicImages.count == 0 && !property.hasWalkthroughVideo {
                            Spacer()
                        }
                    }
                }
                .padding(.top, 8)
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
                                            .background(Color(property.status.color))
                    .cornerRadius(6)
            }
            
            Text("\(property.address.street), \(property.address.city)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .onTapGesture {
                    showingMap = true
                }
            
            Text(property.propertyType.displayName)
                .font(.caption)
                .foregroundColor(.accentBlues)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentBlues.opacity(0.1))
                .cornerRadius(6)
        }
    }
    
    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack {
                Text(formatPrice(property.price))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.accentBlues)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Available From")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(property.availableFrom, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
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
                // Use bedroom.double instead of bed
                FeatureItemSale(icon: "bed.double", title: "Bedrooms", value: "\(property.bedrooms)")
                FeatureItemSale(icon: "bathtub", title: "Bathrooms", value: "\(property.bathrooms)")
                FeatureItemSale(icon: "square", title: "Area", value: property.area)
                FeatureItemSale(icon: "house", title: "Type", value: property.propertyType.displayName)
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
    
    private var sellerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seller Information")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: property.seller.profileImageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_), .empty:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(property.seller.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", property.seller.rating ?? 0.0))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("\(property.seller.reviewCount) reviews")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if property.seller.verificationStatus == .verified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    Text(property.seller.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var contactActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showingCallAlert = true }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Call Seller")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentBlues)
                .cornerRadius(12)
            }
            
            HStack(spacing: 12) {
                Button(action: { showingContactSheet = true }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Message")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.accentBlues)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentBlues.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button(action: { showingContactSheet = true }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Schedule Visit")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.accentBlues)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentBlues.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if price >= 1_000_000 {
            let millionValue = price / 1_000_000
            return "Rs. \(String(format: "%.1f", millionValue))M"
        } else if price >= 100_000 {
            let hundredThousandValue = price / 100_000
            return "Rs. \(String(format: "%.1f", hundredThousandValue))L"
        } else {
            let formattedValue = formatter.string(from: NSNumber(value: price)) ?? "0"
            return "Rs. \(formattedValue)"
        }
    }
    
    private func makePhoneCall() {
        guard let phoneNumber = property.seller.phone,
              let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func toggleWishlist() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isInWishlist.toggle()
        }
        
        // Here you would typically save to UserDefaults or a wishlist service
        let wishlistKey = "wishlist_\(property.id)"
        UserDefaults.standard.set(isInWishlist, forKey: wishlistKey)
        
        // Show feedback to user
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func shareProperty() {
        showingShareSheet = true
    }
    
    private func loadWishlistStatus() {
        let wishlistKey = "wishlist_\(property.id)"
        isInWishlist = UserDefaults.standard.bool(forKey: wishlistKey)
    }
}

// MARK: - Feature Item for Sale Properties
struct FeatureItemSale: View {
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

// MARK: - Contact Seller Sheet
struct ContactSellerSheet: View {
    let property: SaleProperty
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var selectedDate = Date()
    @State private var isSchedulingVisit = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: property.seller.profileImageURL ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_), .empty:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    
                    VStack(spacing: 4) {
                        Text(property.seller.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", property.seller.rating ?? 0.0))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Schedule a visit", isOn: $isSchedulingVisit)
                        .font(.headline)
                    
                    if isSchedulingVisit {
                        DatePicker("Preferred Date", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                        
                        TextField("Type your message here...", text: $message, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(4...8)
                    }
                }
                
                Spacer()
                
                Button(action: sendMessage) {
                    Text(isSchedulingVisit ? "Schedule Visit & Send Message" : "Send Message")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentBlues)
                        .cornerRadius(12)
                }
                .disabled(message.isEmpty)
            }
            .padding()
            .navigationTitle("Contact Seller")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        // Implement message sending logic here
        print("Sending message: \(message)")
        if isSchedulingVisit {
            print("Scheduling visit for: \(selectedDate)")
        }
        dismiss()
    }
}

// MARK: - Sale Property Map View
struct SalePropertyMapView: View {
    let property: SaleProperty
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    
    init(property: SaleProperty) {
        self.property = property
        
        // Validate coordinates and provide default values if invalid
        let latitude = property.coordinates.latitude.isNaN || property.coordinates.latitude.isInfinite ? 6.9271 : property.coordinates.latitude
        let longitude = property.coordinates.longitude.isNaN || property.coordinates.longitude.isInfinite ? 79.8612 : property.coordinates.longitude
        
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: [property]) { property in
                let latitude = property.coordinates.latitude.isNaN || property.coordinates.latitude.isInfinite ? 6.9271 : property.coordinates.latitude
                let longitude = property.coordinates.longitude.isNaN || property.coordinates.longitude.isInfinite ? 79.8612 : property.coordinates.longitude
                
                return MapPin(coordinate: CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude
                ), tint: .red)
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SalePropertyDetailView(
        property: SaleProperty(
            id: "1",
            title: "Modern Villa with Ocean View",
            description: "Beautiful modern villa with stunning ocean views and premium finishes. Perfect for families looking for luxury living.",
            price: 2500000,
            bedrooms: 4,
            bathrooms: 3,
            area: "2,500 sq ft",
            propertyType: PropertyType.house,
            address: PropertyAddressOld(
                street: "123 Ocean Drive",
                city: "Colombo",
                state: "Western Province",
                zipCode: "00100",
                country: "Sri Lanka"
            ),
            coordinates: PropertyCoordinates(latitude: 6.9271, longitude: 79.8612),
            images: ["loginlogo"],
            panoramicImages: [
                PanoramicImage(
                    id: "panoramic1",
                    imageURL: "local://loginlogo.png",
                    title: "Living Room",
                    description: "Spacious living room with ocean view",
                    roomType: .livingRoom,
                    captureDate: Date(),
                    isAREnabled: true
                ),
                PanoramicImage(
                    id: "panoramic2",
                    imageURL: "local://loginlogo.png",
                    title: "Kitchen",
                    description: "Modern kitchen with island",
                    roomType: .kitchen,
                    captureDate: Date(),
                    isAREnabled: true
                )
            ],
            walkthroughVideoURL: "https://example.com/walkthrough.mp4",
            features: [],
            seller: PropertySeller(
                id: "seller1",
                name: "John Doe",
                email: "john@example.com",
                phone: "+94771234567",
                profileImageURL: "loginlogo",
                rating: 4.5,
                reviewCount: 12,
                verificationStatus: .verified
            ),
            availableFrom: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            status: SalePropertyStatus.active,
            isNew: true
        )
    )
}

// MARK: - Property Share View
struct PropertyShareView: UIViewControllerRepresentable {
    let property: SaleProperty
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let shareText = """
        Check out this amazing property!
        
        🏡 \(property.title)
        💰 \(formatPrice(property.price))
        📍 \(property.address.city), \(property.address.state)
        🛏️ \(property.bedrooms) bedrooms, 🛁 \(property.bathrooms) bathrooms
        📐 \(property.area)
        
        Contact: \(property.seller.name)
        📧 \(property.seller.email)
        📞 \(property.seller.phone ?? "N/A")
        
        Shared via VistaBids
        """
        
        var itemsToShare: [Any] = [shareText]
        
        // Add first image URL if available
        if let firstImageURL = property.images.first, let url = URL(string: firstImageURL) {
            itemsToShare.append(url)
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Exclude certain activity types if needed
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact
        ]
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if price >= 1_000_000 {
            let millionValue = price / 1_000_000
            return "Rs. \(String(format: "%.1f", millionValue))M"
        } else if price >= 100_000 {
            let hundredThousandValue = price / 100_000
            return "Rs. \(String(format: "%.1f", hundredThousandValue))L"
        } else {
            let formattedValue = formatter.string(from: NSNumber(value: price)) ?? "0"
            return "Rs. \(formattedValue)"
        }
    }
}
