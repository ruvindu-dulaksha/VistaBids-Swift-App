import SwiftUI
import MapKit
import CoreLocation

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct LocationPickerView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var locationName: String
    @Binding var isPresented: Bool
    
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), 
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var showingSearchResults = false
    
    // For environment-based dismissal
    @Environment(\.dismiss) private var dismiss
    
    // Internal state to track if we should use dismiss or isPresented
    private let useEnvironmentDismiss: Bool
    
    // Primary initializer (for AR property form)
    init(selectedLocation: Binding<CLLocationCoordinate2D?>, locationName: Binding<String>, isPresented: Binding<Bool>) {
        self._selectedLocation = selectedLocation
        self._locationName = locationName
        self._isPresented = isPresented
        self.useEnvironmentDismiss = false
    }
    
    // Alternative initializer (for other parts of the app)
    init(selectedLocation: Binding<String>, selectedCoordinate: Binding<CLLocationCoordinate2D?>) {
        self._selectedLocation = selectedCoordinate
        self._locationName = selectedLocation
        self._isPresented = .constant(true)
        self.useEnvironmentDismiss = true
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Map view
                mapView
                
                // Current location button
                currentLocationButton
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if useEnvironmentDismiss {
                            dismiss()
                        } else {
                            isPresented = false
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if useEnvironmentDismiss {
                            dismiss()
                        } else {
                            isPresented = false
                        }
                    }
                    .disabled(selectedLocation == nil)
                }
            }
        }
        .onAppear {
            requestLocationPermission()
        }
    }
}

// View Components
extension LocationPickerView {
    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search for a location", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        searchForLocation()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                        showingSearchResults = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top)
            
            // Search results
            if showingSearchResults && !searchResults.isEmpty {
                List(searchResults, id: \.self) { item in
                    Button(action: {
                        selectSearchResult(item)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Unknown Location")
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            if let address = item.placemark.title {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: 200)
            }
        }
    }
    
    private var mapView: some View {
        ZStack {
            Map(coordinateRegion: $region, 
                annotationItems: selectedLocation != nil ? [MapAnnotationItem(coordinate: selectedLocation!)] : []) { annotation in
                MapPin(coordinate: annotation.coordinate)
            }
            .onTapGesture { location in
                let coordinate = region.center
                selectedLocation = coordinate
                reverseGeocode(coordinate: coordinate)
            }
            .gesture(
                DragGesture()
                    .onChanged { _ in
                        showingSearchResults = false
                    }
                    .onEnded { _ in
                        let coordinate = region.center
                        selectedLocation = coordinate
                        reverseGeocode(coordinate: coordinate)
                    }
            )
            .overlay(
                // Center crosshair
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.red)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            )
        }
    }
    
    private var currentLocationButton: some View {
        Button(action: {
            centerOnCurrentLocation()
        }) {
            HStack {
                Image(systemName: "location.fill")
                Text("Use Current Location")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue) 
            .cornerRadius(12)
        }
        .padding()
    }
}

//  Private Methods
extension LocationPickerView {
    private func requestLocationPermission() {
        locationManager.requestPermission()
    }
    
    private func centerOnCurrentLocation() {
        if let currentLocation = locationManager.location {
            region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            selectedLocation = currentLocation.coordinate
            reverseGeocode(coordinate: currentLocation.coordinate)
        }
    }
    
    private func searchForLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                DispatchQueue.main.async {
                    self.searchResults = response.mapItems
                    self.showingSearchResults = true
                }
            }
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        selectedLocation = item.placemark.coordinate
        locationName = item.placemark.title ?? "Selected Location"
        
        region = MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        searchText = ""
        searchResults = []
        showingSearchResults = false
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    var components: [String] = []
                    
                    if let name = placemark.name {
                        components.append(name)
                    }
                    if let locality = placemark.locality {
                        components.append(locality)
                    }
                    if let country = placemark.country {
                        components.append(country)
                    }
                    
                    self.locationName = components.joined(separator: ", ")
                }
            }
        }
    }
}

#Preview {
    LocationPickerView(
        selectedLocation: .constant(nil),
        locationName: .constant(""),
        isPresented: .constant(true)
    )
}
