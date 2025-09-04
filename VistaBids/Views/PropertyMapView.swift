//
//  PropertyMapView.swift
//  VistaBids
//
//  Enhanced Property Map View with Advanced Features
//

import SwiftUI
import MapKit
import Combine
import FirebaseFirestore

struct PropertyMapView: View {
    let properties: [AuctionProperty]
    @ObservedObject var mapService = MapService.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var showHeatMap = false
    @State private var showClusters = true
    @State private var showFilters = false
    @State private var selectedHeatMapType: HeatMapPoint.HeatMapType = .bidActivity
    @State private var mapType: MKMapType = .standard
    @State private var selectedProperty: AuctionProperty?
    @State private var showPropertyDetail = false
    @State private var clusters: [PropertyCluster] = []
    @State private var filters: [MapFilter] = []
    
    private let coordinatorDelegate = MapViewCoordinator()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Map View
            AdvancedMapView(
                region: $region,
                mapType: $mapType,
                properties: properties,
                clusters: clusters,
                heatMapData: mapService.heatMapData,
                showHeatMap: showHeatMap,
                showClusters: showClusters,
                selectedHeatMapType: selectedHeatMapType,
                onPropertySelected: { property in
                    selectedProperty = property
                    showPropertyDetail = true
                },
                onRegionChanged: { newRegion in
                    region = newRegion
                    updateMapData()
                }
            )
            .ignoresSafeArea(.all)
            
            // Map Controls
            VStack(spacing: 16) {
                MapControlsView(
                    showHeatMap: $showHeatMap,
                    showClusters: $showClusters,
                    showFilters: $showFilters,
                    mapType: $mapType,
                    selectedHeatMapType: $selectedHeatMapType
                )
                            .onChange(of: selectedHeatMapType) { oldValue, newValue in
                Task {
                    await updateHeatMapData()
                }
            }
            .onChange(of: showHeatMap) { oldValue, isEnabled in
                if isEnabled {
                    Task {
                        await mapService.generateHeatMapData(for: properties, type: .bidActivity)
                    }
                }
            }
            .onChange(of: showClusters) { oldValue, newValue in
                Task {
                    await updateClusterData()
                }
            }
                
                // Heat Map Legend
                if showHeatMap {
                    MapLegendView(heatMapType: selectedHeatMapType)
                }
                
                Spacer()
            }
            .padding()
            
            // Analytics Panel
            if let analytics = mapService.propertyAnalytics {
                VStack {
                    Spacer()
                    
                    AnalyticsPanel(analytics: analytics)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            MapFilterView(filters: $filters, isPresented: $showFilters)
        }
        .sheet(item: $selectedProperty) { property in
                                PropertyMapDetailSheet(property: property)
        }
        .onAppear {
            setupInitialRegion()
            initializeFilters()
            updateMapData()
        }
        .task {
            await mapService.generateMapAnalytics(for: properties, region: region)
        }
    }
    
    private func setupInitialRegion() {
        guard !properties.isEmpty else { return }
        
        let coordinates = properties.map { property in
            CLLocationCoordinate2D(
                latitude: property.location.latitude,
                longitude: property.location.longitude
            )
        }
        
        region = mapService.calculateRegion(for: coordinates, padding: 0.05)
    }
    
    private func initializeFilters() {
        filters = [
            MapFilter(
                type: .priceRange,
                isEnabled: false,
                value: .priceRange(min: 0, max: 2000000)
            ),
            MapFilter(
                type: .propertyType,
                isEnabled: false,
                value: .propertyTypes([.residential, .commercial, .land, .luxury])
            ),
            MapFilter(
                type: .auctionStatus,
                isEnabled: false,
                value: .auctionStatuses([.active, .upcoming])
            ),
            MapFilter(
                type: .timeRange,
                isEnabled: false,
                value: .timeRange(start: Date(), end: Date().addingTimeInterval(7 * 24 * 3600))
            ),
            MapFilter(
                type: .bidCount,
                isEnabled: false,
                value: .bidRange(min: 0, max: 100)
            )
        ]
    }
    
    private func updateMapData() {
        Task {
            await updateClusterData()
            await mapService.generateMapAnalytics(for: properties, region: region)
        }
    }
    
    private func updateHeatMapData() {
        Task {
            await mapService.generateHeatMapData(for: filteredProperties, type: selectedHeatMapType)
        }
    }
    
    private func updateClusterData() {
        Task {
            clusters = await mapService.generatePropertyClusters(for: filteredProperties, region: region)
        }
    }
    
    private var filteredProperties: [AuctionProperty] {
        let activeFilters = filters.filter { $0.isEnabled }
        
        if activeFilters.isEmpty {
            return properties
        }
        
        return properties.filter { property in
            for filter in activeFilters {
                switch filter.value {
                case .priceRange(let min, let max):
                    if property.currentBid < min || property.currentBid > max {
                        return false
                    }
                    
                case .propertyTypes(let types):
                    if !types.contains(property.category) {
                        return false
                    }
                    
                case .auctionStatuses(let statuses):
                    if !statuses.contains(property.status) {
                        return false
                    }
                    
                case .timeRange(let start, let end):
                    if property.auctionEndTime < start || property.auctionEndTime > end {
                        return false
                    }
                    
                case .bidRange(let min, let max):
                    let bidCount = property.bidHistory.count
                    if bidCount < min || bidCount > max {
                        return false
                    }
                    
                case .distance(let radius, let center):
                    let distance = mapService.calculateDistance(
                        from: CLLocationCoordinate2D(latitude: property.location.latitude, longitude: property.location.longitude),
                        to: center
                    )
                    if distance > radius {
                        return false
                    }
                }
            }
            return true
        }
    }
}

// MARK: - Advanced Map View
struct AdvancedMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: MKMapType
    
    let properties: [AuctionProperty]
    let clusters: [PropertyCluster]
    let heatMapData: [HeatMapPoint]
    let showHeatMap: Bool
    let showClusters: Bool
    let selectedHeatMapType: HeatMapPoint.HeatMapType
    let onPropertySelected: (AuctionProperty) -> Void
    let onRegionChanged: (MKCoordinateRegion) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = true
        mapView.showsBuildings = true
        
        // Register custom annotation views
        mapView.register(PropertyAnnotationView.self, forAnnotationViewWithReuseIdentifier: "PropertyAnnotation")
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: "ClusterAnnotation")
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        if mapView.region.center.latitude != region.center.latitude ||
           mapView.region.center.longitude != region.center.longitude {
            mapView.setRegion(region, animated: true)
        }
        
        // Update map type
        mapView.mapType = mapType
        
        // Update annotations
        updateAnnotations(mapView: mapView)
        
        // Update overlays
        updateOverlays(mapView: mapView)
        
        // Store callbacks in coordinator
        context.coordinator.onPropertySelected = onPropertySelected
        context.coordinator.onRegionChanged = onRegionChanged
    }
    
    private func updateAnnotations(mapView: MKMapView) {
        // Remove existing annotations
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        if showClusters && !clusters.isEmpty {
            // Add cluster annotations
            let clusterAnnotations = clusters.map { ClusterAnnotation(cluster: $0) }
            mapView.addAnnotations(clusterAnnotations)
        } else {
            // Add individual property annotations
            let propertyAnnotations = properties.map { PropertyAnnotation(property: $0) }
            mapView.addAnnotations(propertyAnnotations)
        }
    }
    
    private func updateOverlays(mapView: MKMapView) {
        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)
        
        if showHeatMap && !heatMapData.isEmpty {
            // Add heat map overlay
            let heatMapOverlay = HeatMapOverlay(points: heatMapData)
            mapView.addOverlay(heatMapOverlay)
        }
    }
    
    func makeCoordinator() -> MapViewCoordinator {
        return MapViewCoordinator()
    }
}

// MARK: - Map View Coordinator
class MapViewCoordinator: NSObject, MKMapViewDelegate {
    var onPropertySelected: ((AuctionProperty) -> Void)?
    var onRegionChanged: ((MKCoordinateRegion) -> Void)?
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        onRegionChanged?(mapView.region)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        if let clusterAnnotation = annotation as? ClusterAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "ClusterAnnotation", for: annotation) as! ClusterAnnotationView
            return view
        }
        
        if let propertyAnnotation = annotation as? PropertyAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "PropertyAnnotation", for: annotation) as! PropertyAnnotationView
            return view
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let heatMapOverlay = overlay as? HeatMapOverlay {
            return HeatMapRenderer(overlay: heatMapOverlay)
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let propertyAnnotation = view.annotation as? PropertyAnnotation {
            onPropertySelected?(propertyAnnotation.property)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let clusterAnnotation = view.annotation as? ClusterAnnotation {
            // Zoom into cluster
            let cluster = clusterAnnotation.cluster
            let region = MKCoordinateRegion(
                center: cluster.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: - Analytics Panel
struct AnalyticsPanel: View {
    let analytics: MapAnalytics
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Map Analytics")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(.accentBlues)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Activity Metrics
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Activity")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            MetricView(title: "Active", value: "\(analytics.totalProperties)")
                            MetricView(title: "Total Bids", value: "\(analytics.totalBids)")
                            MetricView(title: "Avg Price", value: "$\(Int(analytics.averagePrice))")
                        }
                    }
                    
                    // Price Trends
                    if !analytics.trends.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Price Trends")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(analytics.trends, id: \.period) { trend in
                                HStack {
                                    Text(trend.period)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(trend.description)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Text("(\(trend.change > 0 ? "+" : "")\(String(format: "%.1f", trend.change))%)")
                                        .font(.caption)
                                        .foregroundColor(trend.change > 0 ? .green : .red)
                                }
                            }
                        }
                    }
                    
                    // Top Hotspots
                    if !analytics.hotspots.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Top Hotspots")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(analytics.hotspots.prefix(3), id: \.id) { hotspot in
                                HStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.6))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(hotspot.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(hotspot.propertyCount) properties")
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text("$\(Int(hotspot.averagePrice))")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// MARK: - Metric View
struct MetricView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.accentBlues)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Property Detail Sheet
struct PropertyMapDetailSheet: View {
    let property: AuctionProperty
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Property Images
                    if !property.images.isEmpty {
                        TabView {
                            ForEach(property.images, id: \.self) { imageURL in
                                AsyncImage(url: URL(string: imageURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(height: 200)
                                .clipped()
                            }
                        }
                        .frame(height: 200)
                        .tabViewStyle(PageTabViewStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(property.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(property.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label("Current Bid", systemImage: "hammer.fill")
                            Spacer()
                            Text("$\(Int(property.currentBid))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.accentBlues)
                        }
                        
                        HStack {
                            Label("Category", systemImage: "house.fill")
                            Spacer()
                            Text(property.category.rawValue.capitalized)
                        }
                        
                        HStack {
                            Label("Status", systemImage: "clock.fill")
                            Spacer()
                            Text(property.status.rawValue.capitalized)
                                .foregroundColor(property.status.color)
                        }
                        
                        HStack {
                            Label("Ends", systemImage: "calendar")
                            Spacer()
                            Text(property.auctionEndTime, style: .relative)
                        }
                        
                        if !property.bidHistory.isEmpty {
                            HStack {
                                Label("Bids", systemImage: "person.3.fill")
                                Spacer()
                                Text("\(property.bidHistory.count)")
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Property Details")
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

// MARK: - Single Property Map View (Legacy compatibility)
struct SinglePropertyMapView: View {
    let property: AuctionProperty
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    
    init(property: AuctionProperty) {
        self.property = property
        
        // Validate coordinates and provide default values if invalid (Colombo, Sri Lanka)
        let latitude = property.location.latitude.isNaN || property.location.latitude.isInfinite ? 6.9271 : property.location.latitude
        let longitude = property.location.longitude.isNaN || property.location.longitude.isInfinite ? 79.8612 : property.location.longitude
        
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
            VStack(spacing: 0) {
                // Map
                Map(coordinateRegion: $region, annotationItems: [property]) { property in
                    let latitude = property.location.latitude.isNaN || property.location.latitude.isInfinite ? 6.9271 : property.location.latitude
                    let longitude = property.location.longitude.isNaN || property.location.longitude.isInfinite ? 79.8612 : property.location.longitude
                    
                    return MapMarker(coordinate: CLLocationCoordinate2D(
                        latitude: latitude,
                        longitude: longitude
                    ), tint: .red)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Property Info Card
                propertyInfoCard
            }
            .navigationTitle("Property Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Directions") {
                        openInMaps()
                    }
                    .foregroundColor(.accentBlues)
                }
            }
        }
    }
    
    private var propertyInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AsyncImage(url: URL(string: property.images.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .clipped()
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(property.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                    
                    Text("$\(property.currentBid, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentBlues)
                    
                    Text(property.status.displayText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(property.status.color)
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Address")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(property.address.fullAddress)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: openInMaps) {
                    HStack {
                        Image(systemName: "location")
                        Text("Directions")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentBlues)
                    .cornerRadius(8)
                }
                
                Button(action: shareLocation) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.accentBlues)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentBlues.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: property.location.latitude,
            longitude: property.location.longitude
        )
        
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = property.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func shareLocation() {
        let coordinate = CLLocationCoordinate2D(
            latitude: property.location.latitude,
            longitude: property.location.longitude
        )
        
        let shareText = """
        Check out this property: \(property.title)
        Address: \(property.address.fullAddress)
        Current Bid: $\(String(format: "%.0f", property.currentBid))
        
        Location: https://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(property.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        """
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
}

#Preview {
    PropertyMapView(properties: [
        AuctionProperty(
            sellerId: "seller1",
            sellerName: "John Doe",
            title: "Modern Villa",
            description: "Beautiful modern villa with stunning views.",
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
        )
    ])
}
