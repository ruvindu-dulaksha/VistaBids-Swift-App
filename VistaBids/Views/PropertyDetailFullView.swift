//
//  PropertyDetailFullView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-09-07.
//

import SwiftUI
import MapKit

struct PropertyDetailFullView: View {
    let property: SaleProperty
    @Environment(\.dismiss) private var dismiss
    @StateObject private var nearbyPlacesService = NearbyPlacesService.shared
    @State private var selectedPlaceType: PlaceType = .restaurant
    @State private var currentTab = 0
    @State private var showingContactAlert = false
    @State private var showingCallAlert = false
    @State private var selectedImageIndex = 0
    @State private var scrollOffset: CGFloat = 0
    
    private var filteredPlaces: [NearbyPlace] {
        nearbyPlacesService.filterPlaces(by: selectedPlaceType)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Image carousel
                ZStack(alignment: .topLeading) {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(0..<(property.images.isEmpty ? 1 : property.images.count), id: \.self) { index in
                            if property.images.isEmpty {
                                Rectangle()
                                    .fill(Color.secondaryBackground)
                                    .overlay(
                                        Image(systemName: "house.fill")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondaryTextColor)
                                    )
                            } else {
                                AsyncImage(url: URL(string: property.images[index])) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.secondaryBackground)
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                                .tint(.accentBlues)
                                        )
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    
                    // Back button
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            // Share functionality
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            // Add to favorites
                        }) {
                            Image(systemName: "heart")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                
                // Property header information
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(property.formattedPrice)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.accentBlues)
                        
                        Text(property.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.red)
                            
                            Text("\(property.address.street), \(property.address.city), \(property.address.state)")
                                .font(.subheadline)
                                .foregroundColor(.secondaryTextColor)
                        }
                    }
                    
                    // Status badge
                    HStack {
                        Text(property.status.displayText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(property.status == .active ? Color.green : 
                                        property.status == .underOffer ? Color.orange : 
                                        property.status == .sold ? Color.blue : Color.gray)
                            .cornerRadius(16)
                        
                        if property.isNew {
                            Text("New")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentBlues)
                                .cornerRadius(16)
                        }
                        
                        Spacer()
                        
                        Text("Listed: \(formatDate(property.createdAt))")
                            .font(.caption)
                            .foregroundColor(.secondaryTextColor)
                    }
                    
                    // Key features
                    HStack(spacing: 0) {
                        PropertyFeatureBox(icon: "bed.double.fill", value: "\(property.bedrooms)", title: "Beds")
                        
                        Divider()
                            .frame(height: 40)
                        
                        PropertyFeatureBox(icon: "bathtub.fill", value: "\(property.bathrooms)", title: "Baths")
                        
                        Divider()
                            .frame(height: 40)
                        
                        PropertyFeatureBox(icon: "square.fill", value: property.area, title: "Area")
                        
                        Divider()
                            .frame(height: 40)
                        
                        PropertyFeatureBox(icon: "building.2.fill", value: property.propertyType.displayName, title: "Type")
                    }
                    .frame(height: 80)
                    .background(Color.secondaryBackground.opacity(0.3))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Tab selection
                HStack(spacing: 0) {
                    ForEach(["Overview", "Features", "Location", "Nearby"], id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                switch tab {
                                case "Overview": currentTab = 0
                                case "Features": currentTab = 1
                                case "Location": currentTab = 2
                                case "Nearby": 
                                    currentTab = 3
                                    loadNearbyPlaces()
                                default: break
                                }
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(tab)
                                    .font(.subheadline)
                                    .fontWeight(getCurrentTab() == tab ? .semibold : .regular)
                                    .foregroundColor(getCurrentTab() == tab ? .accentBlues : .secondaryTextColor)
                                
                                Rectangle()
                                    .fill(getCurrentTab() == tab ? Color.accentBlues : Color.clear)
                                    .frame(height: 2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Divider()
                    .padding(.top, 4)
                
                // Tab content
                VStack {
                    switch currentTab {
                    case 0:
                        // Overview tab
                        overviewTab
                    case 1:
                        // Features tab
                        featuresTab
                    case 2:
                        // Location tab
                        locationTab
                    case 3:
                        // Nearby tab
                        nearbyTab
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
        .background(Color.backgrounds)
        .overlay(
            // Contact section (sticky at bottom)
            VStack(spacing: 16) {
                Divider()
                
                // Contact buttons
                HStack(spacing: 12) {
                    // Seller info
                    HStack(spacing: 10) {
                        AsyncImage(url: URL(string: property.seller.profileImageURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(property.seller.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.textPrimary)
                                
                                if property.seller.verificationStatus == .verified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Text("Agent")
                                .font(.caption)
                                .foregroundColor(.secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingCallAlert = true
                    }) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        showingContactAlert = true
                    }) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.accentBlues)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color.cardBackground)
            .shadowOnTop()
            .frame(maxHeight: .infinity, alignment: .bottom)
        )
        .alert("Call Seller", isPresented: $showingCallAlert) {
            Button("Call Now") {
                makePhoneCall()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to call \(property.seller.name) at \(property.seller.phone ?? "N/A")?")
        }
        .alert("Contact Seller", isPresented: $showingContactAlert) {
            Button("Send Email") {
                sendEmail()
            }
            Button("Send SMS") {
                sendSMS()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("How would you like to contact \(property.seller.name)?")
        }
        .onAppear {
            loadNearbyPlaces()
        }
    }
    
    // Overview tab
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description section
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(property.description)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
            
            // Virtual experiences
            if property.hasWalkthroughVideo || property.hasPanoramicImages {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Virtual Experience")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 12) {
                        if property.hasWalkthroughVideo {
                            Button(action: {
                                // Open video walkthrough
                            }) {
                                HStack {
                                    Image(systemName: "video.fill")
                                    Text("Virtual Tour")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.accentBlues)
                                .cornerRadius(8)
                            }
                        }
                        
                        if property.hasPanoramicImages {
                            Button(action: {
                                // Show 360 views
                            }) {
                                HStack {
                                    Image(systemName: "panorama")
                                    Text("360° Views")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.accentBlues)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Divider()
            }
            
            // Nearby essential places section
            VStack(alignment: .leading, spacing: 12) {
                Text("Nearby Essentials")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                if nearbyPlacesService.isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading nearby places...")
                            .font(.subheadline)
                            .foregroundColor(.secondaryTextColor)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                } else if nearbyPlacesService.nearbyPlaces.isEmpty {
                    Button(action: loadNearbyPlaces) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Load Nearby Places")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentBlues)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    nearbyEssentialsList
                }
            }
            
            Divider()
            
            // Availability section
            VStack(alignment: .leading, spacing: 12) {
                Text("Availability")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Available From")
                            .font(.caption)
                            .foregroundColor(.secondaryTextColor)
                        
                        Text(formatDate(property.availableFrom))
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Listed On")
                            .font(.caption)
                            .foregroundColor(.secondaryTextColor)
                        
                        Text(formatDate(property.createdAt))
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.secondaryTextColor)
                        
                        Text(property.status.displayText)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
    }
    
    // Features tab
    private var featuresTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Property features
            ForEach(PropertyFeature.PropertyFeatureCategory.allCases, id: \.self) { category in
                let categoryFeatures = property.features.filter { $0.category == category }
                
                if !categoryFeatures.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(categoryFeatures, id: \.id) { feature in
                                HStack(spacing: 10) {
                                    Image(systemName: feature.icon)
                                        .foregroundColor(.accentBlues)
                                        .frame(width: 24, height: 24)
                                    
                                    Text(feature.name)
                                        .font(.subheadline)
                                        .foregroundColor(.textPrimary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    Divider()
                }
            }
            
            // Property details
            VStack(alignment: .leading, spacing: 12) {
                Text("Property Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                VStack(spacing: 8) {
                    DetailRow(title: "Property Type", value: property.propertyType.displayName)
                    DetailRow(title: "Area", value: property.area)
                    DetailRow(title: "Bedrooms", value: "\(property.bedrooms)")
                    DetailRow(title: "Bathrooms", value: "\(property.bathrooms)")
                    DetailRow(title: "Country", value: property.address.country)
                    DetailRow(title: "Status", value: property.status.displayText)
                }
            }
        }
    }
    
    // Location tab
    private var locationTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Address section
            VStack(alignment: .leading, spacing: 12) {
                Text("Address")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(title: "Street", value: property.address.street)
                    DetailRow(title: "City", value: property.address.city)
                    DetailRow(title: "State/Province", value: property.address.state)
                    DetailRow(title: "Zip/Postal Code", value: property.address.zipCode)
                    DetailRow(title: "Country", value: property.address.country)
                }
            }
            
            Divider()
            
            // Map section
            VStack(alignment: .leading, spacing: 12) {
                Text("Map Location")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: property.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [property]) { _ in
                    MapMarker(coordinate: property.coordinate, tint: .red)
                }
                .frame(height: 250)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // Nearby tab
    private var nearbyTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text("Nearby Places")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            // Filter buttons
            placeTypeFilters
            
            // Content based on loading state
            nearbyPlacesContent
        }
    }
    
    // Place type filter buttons
    private var placeTypeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PlaceType.allCases, id: \.self) { type in
                    placeTypeButton(for: type)
                }
            }
        }
    }
    
    // Individual place type filter button
    private func placeTypeButton(for type: PlaceType) -> some View {
        Button(action: {
            selectedPlaceType = type
        }) {
            HStack {
                Image(systemName: type.icon)
                Text(type.name)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedPlaceType == type ? Color.accentBlues : Color.secondaryBackground)
            .foregroundColor(selectedPlaceType == type ? .white : .textPrimary)
            .cornerRadius(16)
        }
    }
    
    // Content for nearby places based on loading state
    private var nearbyPlacesContent: some View {
        Group {
            if nearbyPlacesService.isLoading {
                loadingView
            } else if !nearbyPlacesService.nearbyPlaces.isEmpty {
                nearbyPlacesList
            } else if nearbyPlacesService.error != nil {
                errorView
            } else {
                emptyView
            }
        }
    }
    
    // Loading view
    private var loadingView: some View {
        VStack {
            ProgressView()
                .padding()
            Text("Loading nearby places...")
                .foregroundColor(.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // List of nearby places
    private var nearbyPlacesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(filteredPlaces) { place in
                NearbyPlaceRow(place: place, propertyCoordinate: property.coordinate)
            }
        }
    }
    
    // Error view
    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
                .font(.largeTitle)
            
            Text("Error loading places")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            if let error = nearbyPlacesService.error {
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: loadNearbyPlaces) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentBlues)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // Empty state view
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash")
                .foregroundColor(.gray)
                .font(.largeTitle)
            
            Text("No nearby places found")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Button(action: loadNearbyPlaces) {
                Text("Reload")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentBlues)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // This comment is intentionally left empty as this is the removed duplicate declaration
    
    private func getCurrentTab() -> String {
        switch currentTab {
        case 0: return "Overview"
        case 1: return "Features"
        case 2: return "Location"
        case 3: return "Nearby"
        default: return "Overview"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Nearby essentials list - showing one place from each category
    private var nearbyEssentialsList: some View {
        VStack(spacing: 16) {
            let essentialTypes: [PlaceType] = [.shopping, .school, .restaurant, .hospital, .pharmacy, .bank]
            let nearestByType = getNearestEssentialPlaces(types: essentialTypes)
            
            if nearestByType.isEmpty {
                Button(action: loadNearbyPlaces) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Load Nearby Places")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentBlues)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else {
                ForEach(nearestByType.sorted(by: { $0.key.name < $1.key.name }), id: \.key) { type, place in
                    HStack(spacing: 12) {
                        Image(systemName: type.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.accentBlues)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            Text(place.name)
                                .font(.caption)
                                .foregroundColor(.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Text(place.formattedDistance)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentBlues)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackground)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func getNearestEssentialPlaces(types: [PlaceType]) -> [PlaceType: NearbyPlace] {
        var nearestByType: [PlaceType: NearbyPlace] = [:]
        
        for type in types {
            let places = nearbyPlacesService.filterPlaces(by: type)
            if let nearest = places.first {
                nearestByType[type] = nearest
            }
        }
        
        return nearestByType
    }
    
    private func loadNearbyPlaces() {
        Task {
            await nearbyPlacesService.fetchNearbyPlaces(
                coordinate: property.coordinate,
                types: PlaceType.allCases,
                radius: 5000 // 5km radius
            )
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
    
    private func sendEmail() {
        let email = property.seller.email
        guard let url = URL(string: "mailto:\(email)?subject=Inquiry%20about%20\(property.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendSMS() {
        guard let phoneNumber = property.seller.phone,
              let url = URL(string: "sms:\(phoneNumber)?body=Hi%20\(property.seller.name),%20I'm%20interested%20in%20your%20property%20\(property.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// Supporting views
struct PropertyFeatureBox: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.accentBlues)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondaryTextColor)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

struct NearbyPlaceRow: View {
    let place: NearbyPlace
    let propertyCoordinate: CLLocationCoordinate2D
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: place.type.icon)
                .font(.title2)
                .foregroundColor(.accentBlues)
                .frame(width: 40, height: 40)
                .background(Color.secondaryBackground)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(place.formattedDistance)
                    .font(.caption)
                    .foregroundColor(.secondaryTextColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(String(format: "%.1f km", place.distance))
                .font(.subheadline)
                .foregroundColor(.accentBlues)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        PropertyDetailFullView(property: SaleProperty.example)
    }
}
