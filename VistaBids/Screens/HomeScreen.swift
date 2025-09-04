//
//  HomeScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-08.
//


import SwiftUI
import MapKit
import FirebaseFirestore

struct HomeScreen: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var salePropertyService = SalePropertyService.shared
    @StateObject private var mapService = MapService.shared
    @StateObject private var nearbyPlacesService = NearbyPlacesService.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchText = ""
    @State private var searchActive = false
    @State private var searchHistory: [String] = []
    @State private var showingSuggestions = false
    @State private var searchDebounceTask: DispatchWorkItem?
    @State private var showingFilters = false
    @State private var selectedProperty: SaleProperty?
    @State private var advancedSearchOptions = AdvancedSearchOptions()
    @State private var isSearching = false
    @State private var showingInsights = false
    @State private var showingNearbyPlaces = false
    @State private var selectedPlaceType: PlaceType = .restaurant
    
    // Search suggestions based on property data
    private var searchSuggestions: [String] {
        let allCities = Set(salePropertyService.properties.map { $0.address.city })
        let allTypes = Set(salePropertyService.properties.map { $0.propertyType.displayName })
        
        let suggestions = Array(allCities) + Array(allTypes)
        
        if searchText.isEmpty {
            return Array(suggestions.prefix(5))
        } else {
            return suggestions
                .filter { $0.lowercased().contains(searchText.lowercased()) }
                .prefix(5)
                .map { $0 }
        }
    }

    // Filtered properties based on search and advanced options
    private var filteredProperties: [SaleProperty] {
        SaleProperty.filter(properties: salePropertyService.properties, options: advancedSearchOptions, searchText: searchText)
    }

    var body: some View {
        ZStack {
            // Map View with property pins
            Map(coordinateRegion: $region, annotationItems: filteredProperties) { property in
                // Use MapMarker instead of MapAnnotation for compatibility
                MapMarker(coordinate: property.coordinate, tint: .blue)
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Custom pins overlay (since MapAnnotation has compatibility issues)
            ForEach(filteredProperties) { property in
                if region.contains(coordinate: property.coordinate) {
                    PropertyPinView(property: property, isSelected: selectedProperty?.id == property.id)
                        .position(
                            x: offSetFor(coordinate: property.coordinate).x + UIScreen.main.bounds.width/2,
                            y: offSetFor(coordinate: property.coordinate).y + UIScreen.main.bounds.height/2 - 60
                        )
                        .onTapGesture {
                            selectedProperty = property
                        }
                }
            }

            // Top Search Bar
            VStack {
                VStack(spacing: 0) {
                    HStack {
                        HStack {
                            Image(systemName: searchActive ? "xmark.circle.fill" : "magnifyingglass")
                                .foregroundColor(searchActive ? .accentBlues : .secondaryTextColor)
                                .onTapGesture {
                                    if searchActive && !searchText.isEmpty {
                                        searchText = ""
                                    } else {
                                        searchActive.toggle()
                                        if searchActive {
                                            loadSearchHistory()
                                        }
                                    }
                                }
                            
                            TextField("Search properties, locations...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: searchText) { newValue in
                                    // Debounce search to avoid too many refreshes
                                    searchDebounceTask?.cancel()
                                    
                                    let task = DispatchWorkItem {
                                        withAnimation {
                                            showingSuggestions = !newValue.isEmpty && searchActive
                                        }
                                        
                                        // Show search indicator briefly
                                        if !newValue.isEmpty {
                                            isSearching = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                                isSearching = false
                                            }
                                        }
                                    }
                                    
                                    searchDebounceTask = task
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
                                }
                                .onTapGesture {
                                    searchActive = true
                                    loadSearchHistory()
                                    showSearchInsights()
                                }
                                .onSubmit {
                                    if !searchText.isEmpty {
                                        // Save to history when user confirms search
                                        UserDefaults.standard.addRecentSearch(searchText)
                                        loadSearchHistory()
                                        showingSuggestions = false
                                    }
                                }
                                .onTapGesture {
                                    searchActive = true
                                    loadSearchHistory()
                                }
                                .overlay(
                                    HStack {
                                        Spacer()
                                        if isSearching {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                                .scaleEffect(0.7)
                                                .padding(.trailing, 8)
                                        } else if !searchText.isEmpty {
                                            Button(action: { searchText = "" }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.gray)
                                                    .padding(.trailing, 8)
                                            }
                                        }
                                    }
                                )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        Button(action: {
                            if searchActive {
                                // Toggle advanced search options
                                withAnimation {
                                    showingSuggestions = false
                                    advancedSearchOptions.filtersEnabled.toggle()
                                }
                            } else {
                                showingFilters.toggle()
                            }
                        }) {
                            Image(systemName: searchActive ? "line.3.horizontal.decrease.circle" : "slider.horizontal.3")
                                .foregroundColor(.buttonText)
                                .frame(width: 44, height: 44)
                                .background(Color.buttonBackground)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        
                        // Location button
                        Button(action: {
                            if mapService.authorizationStatus == .denied || mapService.authorizationStatus == .restricted {
                                // Open settings
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            } else {
                                mapService.requestLocationPermission()
                                // TODO: Fix location access - userLocation should come from LocationManager
                                // if let userLocation = mapService.userLocation {
                                //     withAnimation {
                                //         region.center = userLocation.coordinate
                                //         region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                //     }
                                // }
                            }
                        }) {
                            Image(systemName: mapService.currentLocation != nil ? "location.fill" : "location")
                                .foregroundColor(mapService.currentLocation != nil ? .accentBlues : .buttonText)
                                .frame(width: 44, height: 44)
                                .background(Color.buttonBackground)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Search suggestions and history
                    if showingSuggestions {
                        VStack(alignment: .leading, spacing: 0) {
                            // Recent searches
                            if !searchHistory.isEmpty {
                                RecentSearchView(
                                    searchHistory: searchHistory,
                                    onSearchSelected: { selectedSearch in
                                        searchText = selectedSearch
                                        showingSuggestions = false
                                    }
                                )
                            }
                            
                            // Search suggestions
                            SearchSuggestionView(
                                suggestions: searchSuggestions,
                                onSuggestionSelected: { suggestion in
                                    searchText = suggestion
                                    UserDefaults.standard.addRecentSearch(suggestion)
                                    loadSearchHistory()
                                    showingSuggestions = false
                                }
                            )
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                    }
                    
                    // Search insights
                    if showingInsights && !salePropertyService.properties.isEmpty {
                        SearchInsightView(properties: salePropertyService.properties)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Advanced search options
                    if searchActive && advancedSearchOptions.filtersEnabled {
                        AdvancedSearchView(options: $advancedSearchOptions)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                // Search stats
                if searchActive && !searchText.isEmpty {
                    SearchStatusView(
                        count: filteredProperties.count,
                        searchText: searchText,
                        onDismiss: {
                            searchActive = false
                            showingSuggestions = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.opacity)
                }
                
                Spacer()
            }

            // Bottom Property Cards
            VStack {
                Spacer()
                if !filteredProperties.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filteredProperties) { property in
                                PropertyCardView(property: property)
                                    .onTapGesture {
                                        selectedProperty = property
                                        withAnimation {
                                            region.center = property.coordinate
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(height: 160)
                }
            }

            // Property detail sheet
            if let property = selectedProperty {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { selectedProperty = nil }
                VStack {
                    Spacer()
                    PropertyDetailSheet(property: property, onClose: { selectedProperty = nil })
                        .transition(.move(edge: .bottom))
                }
                .zIndex(2)
            }
        }
        .background(Color.backgrounds)
        .sheet(isPresented: $showingFilters) {
            FilterView()
        }
        .onAppear {
            salePropertyService.loadPropertiesFromFirestore()
            loadSearchHistory()
            setupLocationServices()
        }
        .onChange(of: mapService.currentLocation) { location in
            if let location = location {
                withAnimation {
                    region.center = location.coordinate
                }
            }
        }
    }
    
    private func loadSearchHistory() {
        searchHistory = UserDefaults.standard.recentSearches
    }
    
    private func setupLocationServices() {
        mapService.requestLocationPermission()
    }
    
    private func showSearchInsights() {
        withAnimation {
            showingInsights = true
        }
        
        // Hide insights after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation {
                showingInsights = false
            }
        }
    }
    
    private func fetchNearbyPlaces(for property: SaleProperty) {
        Task {
            await nearbyPlacesService.fetchNearbyPlaces(
                coordinate: property.coordinate,
                types: PlaceType.allCases,
                radius: 5000 // 5km radius
            )
        }
    }
}




// MARK: - Property Marker View (for Sale Properties)
struct PropertyMarkerView: View {
    let property: SaleProperty
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Text(property.formattedPrice)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.buttonText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.buttonBackground)
                .cornerRadius(8)
            
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(isSelected ? .accentBlues : .red)
                .background(Color.cardBackground)
                .clipShape(Circle())
                .font(.title2)
        }
    }
}

// MARK: - Property Card View (Firestore)
struct PropertyCardView: View {
    let property: SaleProperty
    @State private var showingQuickInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: property.primaryImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.secondaryBackground)
                        .overlay(
                            Image(systemName: "house.fill")
                                .foregroundColor(.secondaryTextColor)
                        )
                }
                .frame(height: 80)
                .clipped()
                .cornerRadius(8)
                
                // Property status badge
                Text(property.status.displayText)
                    .font(.system(size: 10))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(property.status.color))
                    .cornerRadius(4)
                    .padding(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(property.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Text(property.formattedPrice)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentBlues)

                HStack(spacing: 8) {
                    Label("\(property.bedrooms)", systemImage: "bed.double.fill")
                    Label("\(property.bathrooms)", systemImage: "bathtub.fill")
                    
                    Button(action: {
                        withAnimation {
                            showingQuickInfo.toggle()
                        }
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentBlues)
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondaryTextColor)
                
                // Quick info popup
                if showingQuickInfo {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.location)
                            .font(.caption)
                            .foregroundColor(.secondaryTextColor)
                        
                        Text(property.area)
                            .font(.caption)
                            .foregroundColor(.secondaryTextColor)
                        
                        if property.hasWalkthroughVideo {
                            Label("Virtual Tour", systemImage: "video.fill")
                                .font(.caption2)
                                .foregroundColor(.accentBlues)
                        }
                        
                        if property.hasPanoramicImages {
                            Label("360° Views", systemImage: "panorama")
                                .font(.caption2)
                                .foregroundColor(.accentBlues)
                        }
                    }
                    .padding(8)
                    .background(Color.secondaryBackground)
                    .cornerRadius(8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(width: 140)
        .padding(8)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Property Detail Sheet
struct PropertyDetailSheet: View {
    let property: SaleProperty
    let onClose: () -> Void
    @StateObject private var nearbyPlacesService = NearbyPlacesService.shared
    @State private var selectedPlaceType: PlaceType = .restaurant
    @State private var currentTab = 0
    
    private var filteredPlaces: [NearbyPlace] {
        nearbyPlacesService.filterPlaces(by: selectedPlaceType)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(property.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondaryTextColor)
                }
            }
            
            TabView(selection: $currentTab) {
                // First tab - Main info
                VStack(alignment: .leading, spacing: 12) {
                    AsyncImage(url: URL(string: property.primaryImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.secondaryBackground)
                            .overlay(
                                Image(systemName: "house.fill")
                                    .foregroundColor(.secondaryTextColor)
                            )
                    }
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(10)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(property.description)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                            
                            HStack(spacing: 16) {
                                FeatureItem(icon: "bed.double.fill", value: "\(property.bedrooms) Beds")
                                FeatureItem(icon: "bathtub.fill", value: "\(property.bathrooms) Baths")
                                FeatureItem(icon: "square.fill", value: property.area)
                            }
                            
                            Divider()
                            
                            Text("Location")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            
                            Text("\(property.address.street), \(property.address.city), \(property.address.state) \(property.address.zipCode)")
                                .font(.caption)
                                .foregroundColor(.secondaryTextColor)
                            
                            Map(coordinateRegion: .constant(MKCoordinateRegion(
                                center: property.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )), annotationItems: [property]) { _ in
                                MapMarker(coordinate: property.coordinate, tint: .red)
                            }
                            .frame(height: 120)
                            .cornerRadius(10)
                            .disabled(true)
                            
                            Divider()
                            
                            // Property features
                            Text("Features")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(property.features, id: \.name) { feature in
                                    HStack {
                                        Image(systemName: feature.icon)
                                            .foregroundColor(.accentBlues)
                                        Text(feature.name)
                                            .font(.caption)
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Special features
                            VStack(alignment: .leading, spacing: 8) {
                                if property.hasWalkthroughVideo {
                                    Button(action: {
                                        // Open video walkthrough
                                    }) {
                                        Label("Virtual Tour", systemImage: "video.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.accentBlues)
                                            .cornerRadius(8)
                                    }
                                }
                                
                                if property.hasPanoramicImages {
                                    Button(action: {
                                        // Show 360 views
                                    }) {
                                        Label("360° Views", systemImage: "panorama")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.accentBlues)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                .tag(0)
                
                // Second tab - Nearby places
                VStack {
                    if nearbyPlacesService.isLoading {
                        VStack {
                            ProgressView()
                                .padding()
                            Text("Loading nearby places...")
                                .foregroundColor(.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !nearbyPlacesService.nearbyPlaces.isEmpty {
                        NearbyPlacesView(
                            places: nearbyPlacesService.nearbyPlaces,
                            propertyCoordinate: property.coordinate,
                            selectedType: $selectedPlaceType
                        )
                    } else if let error = nearbyPlacesService.error {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .font(.title)
                            Text("Error loading places")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.secondaryTextColor)
                                .multilineTextAlignment(.center)
                            
                            Button("Try Again") {
                                loadNearbyPlaces()
                            }
                            .padding(.top)
                            .foregroundColor(.accentBlues)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        VStack {
                            Image(systemName: "location.slash")
                                .foregroundColor(.gray)
                                .font(.title)
                            Text("No nearby places found")
                                .foregroundColor(.secondaryTextColor)
                            
                            Button("Reload") {
                                loadNearbyPlaces()
                            }
                            .padding(.top)
                            .foregroundColor(.accentBlues)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 500)
            
            // Custom tab indicator
            HStack {
                TabButton(title: "Details", isSelected: currentTab == 0) {
                    withAnimation {
                        currentTab = 0
                    }
                }
                
                TabButton(title: "Nearby", isSelected: currentTab == 1) {
                    withAnimation {
                        currentTab = 1
                        loadNearbyPlaces()
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Contact button
            Button(action: {
                // Contact action
            }) {
                Text("Contact Agent")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentBlues)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(radius: 10)
        .frame(maxWidth: 350)
        .padding(.bottom, 24)
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
}

struct FeatureItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .foregroundColor(.accentBlues)
            Text(value)
                .font(.caption)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .accentBlues : .secondaryTextColor)
                
                Rectangle()
                    .fill(isSelected ? Color.accentBlues : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var minPrice: String = ""
    @State private var maxPrice: String = ""
    @State private var selectedBedrooms: Int = 0
    @State private var selectedBathrooms: Int = 0
    @State private var selectedPropertyType: String = ""
    @State private var selectedStatus: SalePropertyStatus? = nil
    
    private let bedroomOptions = ["Any", "1+", "2+", "3+", "4+", "5+"]
    private let bathroomOptions = ["Any", "1+", "1.5+", "2+", "2.5+", "3+"]
    private let propertyTypes = ["Any", "House", "Apartment", "Condo", "Land", "Commercial"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Price Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Price Range")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Minimum")
                                    .font(.subheadline)
                                    .foregroundColor(.secondaryTextColor)
                                
                                TextField("$0", text: $minPrice)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color.inputFields)
                                    .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Maximum")
                                    .font(.subheadline)
                                    .foregroundColor(.secondaryTextColor)
                                
                                TextField("No Max", text: $maxPrice)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color.inputFields)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Bedrooms & Bathrooms
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bedrooms & Bathrooms")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bedrooms")
                                    .font(.subheadline)
                                    .foregroundColor(.secondaryTextColor)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(0..<bedroomOptions.count, id: \.self) { index in
                                            Button(action: {
                                                selectedBedrooms = index
                                            }) {
                                                Text(bedroomOptions[index])
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(selectedBedrooms == index ? Color.accentBlues : Color.inputFields)
                                                    .foregroundColor(selectedBedrooms == index ? .white : .textPrimary)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bathrooms")
                                    .font(.subheadline)
                                    .foregroundColor(.secondaryTextColor)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(0..<bathroomOptions.count, id: \.self) { index in
                                            Button(action: {
                                                selectedBathrooms = index
                                            }) {
                                                Text(bathroomOptions[index])
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(selectedBathrooms == index ? Color.accentBlues : Color.inputFields)
                                                    .foregroundColor(selectedBathrooms == index ? .white : .textPrimary)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Property Type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Property Type")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(propertyTypes, id: \.self) { type in
                                    Button(action: {
                                        selectedPropertyType = type == "Any" ? "" : type
                                    }) {
                                        Text(type)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background((type == "Any" && selectedPropertyType.isEmpty) || type == selectedPropertyType ? Color.accentBlues : Color.inputFields)
                                            .foregroundColor((type == "Any" && selectedPropertyType.isEmpty) || type == selectedPropertyType ? .white : .textPrimary)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Status
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Status")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                Button(action: {
                                    selectedStatus = nil
                                }) {
                                    Text("Any")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedStatus == nil ? Color.accentBlues : Color.inputFields)
                                        .foregroundColor(selectedStatus == nil ? .white : .textPrimary)
                                        .cornerRadius(20)
                                }
                                
                                ForEach(SalePropertyStatus.allCases, id: \.self) { status in
                                    Button(action: {
                                        selectedStatus = status
                                    }) {
                                        Text(status.displayText)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedStatus == status ? Color.accentBlues : Color.inputFields)
                                            .foregroundColor(selectedStatus == status ? .white : .textPrimary)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .background(Color.backgrounds)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.accentBlues)
                }
            }
        }
    }
    
    private func resetFilters() {
        minPrice = ""
        maxPrice = ""
        selectedBedrooms = 0
        selectedBathrooms = 0
        selectedPropertyType = ""
        selectedStatus = nil
    }
    
    private func applyFilters() {
        // In a real app, this would update a shared filter state
        // For this demo, we'll just print the selected filters
        print("Applying filters: Price range $\(minPrice)-$\(maxPrice), Bedrooms: \(selectedBedrooms > 0 ? bedroomOptions[selectedBedrooms] : "Any"), Bathrooms: \(selectedBathrooms > 0 ? bathroomOptions[selectedBathrooms] : "Any"), Property Type: \(selectedPropertyType.isEmpty ? "Any" : selectedPropertyType), Status: \(selectedStatus?.displayText ?? "Any")")
    }
}

#Preview {
    HomeScreen()
        .environmentObject(ThemeManager())
}

// MARK: - Helper functions for map coordinates
extension HomeScreen {
    func offSetFor(coordinate: CLLocationCoordinate2D) -> CGPoint {
        let mapCenter = region.center
        
        let distanceX = coordinate.longitude - mapCenter.longitude
        let distanceY = coordinate.latitude - mapCenter.latitude
        
        let span = region.span
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let xOffset = CGFloat(distanceX / span.longitudeDelta) * screenWidth
        let yOffset = -CGFloat(distanceY / span.latitudeDelta) * screenHeight
        
        return CGPoint(x: xOffset, y: yOffset)
    }
}

extension MKCoordinateRegion {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let latDelta = span.latitudeDelta
        let longDelta = span.longitudeDelta
        
        let latRange = (center.latitude - latDelta/2 - 0.05)...(center.latitude + latDelta/2 + 0.05)
        let longRange = (center.longitude - longDelta/2 - 0.05)...(center.longitude + longDelta/2 + 0.05)
        
        return latRange.contains(coordinate.latitude) && longRange.contains(coordinate.longitude)
    }
}

// MARK: - Custom property pin view
struct PropertyPinView: View {
    let property: SaleProperty
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Text(property.formattedPrice)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentBlues : Color.gray.opacity(0.7))
                .cornerRadius(8)
            
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(isSelected ? .accentBlues : .red)
                .background(Color.white)
                .clipShape(Circle())
                .font(.title2)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(), value: isSelected)
        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Advanced Search View
struct AdvancedSearchView: View {
    @Binding var options: AdvancedSearchOptions
    
    // Temporary variables for the view
    @State private var minPriceString = ""
    @State private var maxPriceString = ""
    @State private var selectedBedroomsIndex = 0
    @State private var selectedBathroomsIndex = 0
    
    private let bedroomOptions = ["Any", "1+", "2+", "3+", "4+", "5+"]
    private let bathroomOptions = ["Any", "1+", "1.5+", "2+", "2.5+", "3+"]
    private let propertyTypes = ["", "House", "Apartment", "Condo", "Land", "Commercial"]
    private let statusOptions = SalePropertyStatus.allCases
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Advanced Search")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Reset") {
                    resetFilters()
                }
                .font(.subheadline)
                .foregroundColor(.red)
            }
            
            Divider()
            
            // Price Range
            VStack(alignment: .leading, spacing: 8) {
                Text("Price Range")
                    .font(.subheadline)
                    .foregroundColor(.secondaryTextColor)
                
                HStack {
                    TextField("Min", text: $minPriceString)
                        .keyboardType(.numberPad)
                        .padding(8)
                        .background(Color.inputFields)
                        .cornerRadius(8)
                        .onChange(of: minPriceString) { newValue in
                            options.minPrice = Double(newValue)
                        }
                    
                    Text("-")
                    
                    TextField("Max", text: $maxPriceString)
                        .keyboardType(.numberPad)
                        .padding(8)
                        .background(Color.inputFields)
                        .cornerRadius(8)
                        .onChange(of: maxPriceString) { newValue in
                            options.maxPrice = Double(newValue)
                        }
                }
            }
            
            // Bedrooms & Bathrooms
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bedrooms")
                        .font(.subheadline)
                        .foregroundColor(.secondaryTextColor)
                    
                    Picker("", selection: $selectedBedroomsIndex) {
                        ForEach(0..<bedroomOptions.count, id: \.self) { index in
                            Text(bedroomOptions[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedBedroomsIndex) { newValue in
                        if newValue == 0 {
                            options.minBedrooms = nil
                        } else {
                            options.minBedrooms = newValue
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bathrooms")
                        .font(.subheadline)
                        .foregroundColor(.secondaryTextColor)
                    
                    Picker("", selection: $selectedBathroomsIndex) {
                        ForEach(0..<bathroomOptions.count, id: \.self) { index in
                            Text(bathroomOptions[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedBathroomsIndex) { newValue in
                        if newValue == 0 {
                            options.minBathrooms = nil
                        } else {
                            options.minBathrooms = newValue
                        }
                    }
                }
            }
            
            // Property Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Property Type")
                    .font(.subheadline)
                    .foregroundColor(.secondaryTextColor)
                
                Picker("Property Type", selection: $options.propertyType) {
                    ForEach(propertyTypes, id: \.self) { type in
                        Text(type.isEmpty ? "Any" : type).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Status")
                    .font(.subheadline)
                    .foregroundColor(.secondaryTextColor)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button(action: {
                            options.status = nil
                        }) {
                            Text("Any")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(options.status == nil ? Color.accentBlues : Color.inputFields)
                                .foregroundColor(options.status == nil ? .white : .textPrimary)
                                .cornerRadius(20)
                        }
                        
                        ForEach(statusOptions, id: \.self) { status in
                            Button(action: {
                                options.status = status
                            }) {
                                Text(status.displayText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(options.status == status ? Color.accentBlues : Color.inputFields)
                                    .foregroundColor(options.status == status ? .white : .textPrimary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
            
            Button(action: {
                options.filtersEnabled = true
            }) {
                Text("Apply Filters")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentBlues)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
        .onAppear {
            // Initialize text fields with current values
            if let minPrice = options.minPrice {
                minPriceString = String(Int(minPrice))
            }
            
            if let maxPrice = options.maxPrice {
                maxPriceString = String(Int(maxPrice))
            }
            
            // Initialize pickers with current values
            if let minBedrooms = options.minBedrooms, minBedrooms <= 5 {
                selectedBedroomsIndex = minBedrooms
            }
            
            if let minBathrooms = options.minBathrooms, minBathrooms <= 3 {
                selectedBathroomsIndex = minBathrooms
            }
        }
    }
    
    private func resetFilters() {
        options = AdvancedSearchOptions()
        minPriceString = ""
        maxPriceString = ""
        selectedBedroomsIndex = 0
        selectedBathroomsIndex = 0
    }
}
