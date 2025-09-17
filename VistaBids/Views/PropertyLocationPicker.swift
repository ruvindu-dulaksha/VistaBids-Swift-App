import SwiftUI
import MapKit
import CoreLocation

struct PropertyLocationPicker: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var locationName: String
    @Binding var isPresented: Bool
    
    @StateObject private var locationManager = PropertyLocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), 
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var showingSearchResults = false
    
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
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .disabled(selectedLocation == nil)
                }
            }
        }
        .onAppear {
            requestLocationPermission()
        }
    }
    
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
        Map(coordinateRegion: $region, annotationItems: selectedLocation != nil ? [MapAnnotation(coordinate: selectedLocation!)] : []) { annotation in
            MapPin(coordinate: annotation.coordinate, tint: .red)
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
            .background(Color.accentBlues)
            .cornerRadius(12)
        }
        .padding()
    }
    
    private func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
    
    private func centerOnCurrentLocation() {
        if let currentLocation = locationManager.currentLocation {
            region = MKCoordinateRegion(
                center: currentLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            selectedLocation = currentLocation
            reverseGeocode(coordinate: currentLocation)
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

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

class PropertyLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let clLocationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        clLocationManager.delegate = self
        clLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = clLocationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        clLocationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            clLocationManager.startUpdatingLocation()
        }
    }
     
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
        }
        clLocationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdatingLocation()
            }
        }
    }
}

#Preview {
    PropertyLocationPicker(
        selectedLocation: .constant(nil),
        locationName: .constant(""),
        isPresented: .constant(true)
    )
}
