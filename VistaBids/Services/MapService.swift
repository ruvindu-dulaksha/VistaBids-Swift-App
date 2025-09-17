//
//  MapService.swift
//  VistaBids
//
//  Enhanced Map Service with Advanced Features
//

import Foundation
import MapKit
import CoreLocation
import Combine
import FirebaseFirestore

@MainActor
class MapService: NSObject, ObservableObject {
    static let shared = MapService()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var heatMapData: [HeatMapPoint] = []
    @Published var propertyAnalytics: MapAnalytics?
    @Published var locationIntelligence: LocationIntelligence?
    @Published var isLoadingData = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // Location Management
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // Geocoding
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    continuation.resume(throwing: NSError(domain: "GeocodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Address not found"]))
                    return
                }
                
                continuation.resume(returning: location.coordinate)
            }
        }
    }
    
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    continuation.resume(throwing: NSError(domain: "GeocodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Location not found"]))
                    return
                }
                
                let address = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea
                ].compactMap { $0 }.joined(separator: ", ")
                
                continuation.resume(returning: address)
            }
        }
    }
    
    // Distance and Region Calculations
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    func calculateRegion(for coordinates: [CLLocationCoordinate2D], padding: Double = 0.1) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLng = coordinates.map { $0.longitude }.min()!
        let maxLng = coordinates.map { $0.longitude }.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        
        let latDelta = max((maxLat - minLat) * (1 + padding), 0.01)
        let lngDelta = max((maxLng - minLng) * (1 + padding), 0.01)
        
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        )
    }
    
    // Heat Map 
    func heatMapData(for properties: [AuctionProperty], type: HeatMapPoint.HeatMapType) async {
        isLoadingData = true
        defer { isLoadingData = false }
        
        // Clear existing data first
        await MainActor.run {
            self.heatMapData = []
        }
        
        var heatPoints: [HeatMapPoint] = []
        
        for property in properties {
            // Validate coordinates
            guard CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(
                latitude: property.location.latitude,
                longitude: property.location.longitude
            )) else {
                print("Invalid coordinates for property: \(property.title)")
                continue
            }
            
            let coordinate = CLLocationCoordinate2D(
                latitude: property.location.latitude,
                longitude: property.location.longitude
            )
            
            let intensity = calculateIntensity(for: property, type: type)
            
            // Only add points with meaningful intensity
            if intensity > 0.01 {
                let heatPoint = HeatMapPoint(
                    coordinate: coordinate,
                    intensity: intensity,
                    value: property.currentBid,
                    type: type
                )
                
                heatPoints.append(heatPoint)
            }
        }
        
       
        // Add clustering logic for dense areas
        if heatPoints.count > 1 {
            heatPoints = await clusterHeatPoints(heatPoints)
        }
        
        // Update data on main thread
        await MainActor.run {
            self.heatMapData = heatPoints
        }
    }
    
    private func calculateIntensity(for property: AuctionProperty, type: HeatMapPoint.HeatMapType) -> Double {
        let intensity: Double
        
        switch type {
        case .bidActivity:
            // More aggressive scaling for bid activity
            let bidCount = Double(property.bidHistory.count)
            intensity = bidCount > 0 ? min(bidCount / 10.0, 1.0) : 0.1 // Minimum 0.1 for active properties
            
        case .propertyValue:
            // Scale property values more reasonably
            let normalizedValue = property.currentBid / 500000.0 // Normalize to 500k
            intensity = max(0.2, min(normalizedValue, 1.0)) // Minimum 0.2, max 1.0
            
        case .priceAppreciation:
            // Time-based intensity (higher for properties ending soon)
            let hoursRemaining = property.auctionEndTime.timeIntervalSinceNow / 3600
            if hoursRemaining > 0 {
                intensity = max(0.2, min(1.0 - (hoursRemaining / 48.0), 1.0)) // 48-hour window
            } else {
                intensity = 1.0 // Ended auctions get maximum intensity
            }
            
        case .userActivity:
            // Watchlist-based intensity
            let watchlistCount = Double(property.watchlistUsers.count)
            intensity = watchlistCount > 0 ? min(watchlistCount / 20.0, 1.0) : 0.1
            
        case .demandLevel:
            // Combination of bids and watchers
            let bidCount = Double(property.bidHistory.count)
            let watchCount = Double(property.watchlistUsers.count)
            let combined = (bidCount * 2 + watchCount) / 30.0 // Weight bids more heavily
            intensity = max(0.1, min(combined, 1.0))
        }
        
        // Ensure intensity is within valid range
        return max(0.0, min(intensity, 1.0))
    }
    
    private func clusterHeatPoints(_ points: [HeatMapPoint]) async -> [HeatMapPoint] {
        // Simple clustering algorithm to merge nearby points
        var clusteredPoints: [HeatMapPoint] = []
        var processedIndices: Set<Int> = []
        
        for (index, point) in points.enumerated() {
            if processedIndices.contains(index) { continue }
            
            var cluster = [point]
            processedIndices.insert(index)
            
            // Find nearby points within 100 meters
            for (otherIndex, otherPoint) in points.enumerated() {
                if otherIndex == index || processedIndices.contains(otherIndex) { continue }
                
                let distance = calculateDistance(from: point.coordinate, to: otherPoint.coordinate)
                if distance < 100 { // 100 meters cluster radius
                    cluster.append(otherPoint)
                    processedIndices.insert(otherIndex)
                }
            }
            
            // Create clustered point
            if cluster.count > 1 {
                let avgLat = cluster.map { $0.coordinate.latitude }.reduce(0, +) / Double(cluster.count)
                let avgLng = cluster.map { $0.coordinate.longitude }.reduce(0, +) / Double(cluster.count)
                let avgIntensity = cluster.map { $0.intensity }.reduce(0, +) / Double(cluster.count)
                
                let clusteredPoint = HeatMapPoint(
                    coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng),
                    intensity: min(avgIntensity * 1.5, 1.0), // Boost cluster intensity
                    value: cluster.map { $0.value }.reduce(0, +) / Double(cluster.count),
                    type: point.type
                )
                clusteredPoints.append(clusteredPoint)
            } else {
                clusteredPoints.append(point)
            }
        }
        
        return clusteredPoints
    }
    
    // Property Clustering
    func propertyClusters(for properties: [AuctionProperty], region: MKCoordinateRegion) async -> [PropertyCluster] {
        let zoomLevel = calculateZoomLevel(from: region)
        let clusterLevel = determineClusterLevel(from: zoomLevel)
        
        return await withTaskGroup(of: [PropertyCluster].self) { group in
            var clusters: [PropertyCluster] = []
            
            group.addTask {
                await self.performClustering(properties: properties, level: clusterLevel)
            }
            
            for await clusterBatch in group {
                clusters.append(contentsOf: clusterBatch)
            }
            
            return clusters
        }
    }
    
    private func calculateZoomLevel(from region: MKCoordinateRegion) -> Double {
        // Calculate zoom level based on span
        let spanRatio = max(region.span.latitudeDelta, region.span.longitudeDelta)
        return max(0, min(20, log2(360.0 / spanRatio)))
    }
    
    private func performClustering(properties: [AuctionProperty], level: PropertyCluster.ClusterLevel) async -> [PropertyCluster] {
        var clusters: [PropertyCluster] = []
        var processedProperties: Set<String> = []
        
        for property in properties {
            guard let propertyId = property.id else { continue }
            if processedProperties.contains(propertyId) { continue }
            
            var clusterProperties = [property]
            processedProperties.insert(propertyId)
            
            // Find nearby properties for clustering
            for otherProperty in properties {
                guard let otherPropertyId = otherProperty.id else { continue }
                if processedProperties.contains(otherPropertyId) { continue }
                
                let distance = calculateDistance(
                    from: CLLocationCoordinate2D(latitude: property.location.latitude, longitude: property.location.longitude),
                    to: CLLocationCoordinate2D(latitude: otherProperty.location.latitude, longitude: otherProperty.location.longitude)
                )
                
                if distance < level.clusterRadius {
                    clusterProperties.append(otherProperty)
                    processedProperties.insert(otherPropertyId)
                }
            }
            
            // Create cluster
            if clusterProperties.count >= level.minimumProperties {
                let avgLat = clusterProperties.map { $0.location.latitude }.reduce(0, +) / Double(clusterProperties.count)
                let avgLng = clusterProperties.map { $0.location.longitude }.reduce(0, +) / Double(clusterProperties.count)
                
                let cluster = PropertyCluster(
                    coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng),
                    properties: clusterProperties,
                    averagePrice: clusterProperties.map { $0.currentBid }.reduce(0, +) / Double(clusterProperties.count),
                    totalBids: clusterProperties.map { $0.bidHistory.count }.reduce(0, +),
                    clusterLevel: level
                )
                
                clusters.append(cluster)
            } else {
                // Create individual clusters for properties that don't meet minimum
                for prop in clusterProperties {
                    let cluster = PropertyCluster(
                        coordinate: CLLocationCoordinate2D(latitude: prop.location.latitude, longitude: prop.location.longitude),
                        properties: [prop],
                        averagePrice: prop.currentBid,
                        totalBids: prop.bidHistory.count,
                        clusterLevel: .individual
                    )
                    clusters.append(cluster)
                }
            }
        }
        
        return clusters
    }
    
    private func determineClusterLevel(from zoomLevel: Double) -> PropertyCluster.ClusterLevel {
        switch zoomLevel {
        case 0...8:
            return .large
        case 9...12:
            return .medium
        case 13...15:
            return .small
        default:
            return .individual
        }
    }
    
    private func calculateBoundingBox(for properties: [AuctionProperty]) -> MKCoordinateRegion {
        let latitudes = properties.map { $0.location.latitude }
        let longitudes = properties.map { $0.location.longitude }
        
        let maxLat = latitudes.max() ?? 0
        let minLat = latitudes.min() ?? 0
        let maxLng = longitudes.max() ?? 0
        let minLng = longitudes.min() ?? 0
        
        let centerLat = (maxLat + minLat) / 2
        let centerLng = (maxLng + minLng) / 2
        let latDelta = (maxLat - minLat) * 1.2 // Add 20% padding
        let lngDelta = (maxLng - minLng) * 1.2 // Add 20% padding
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        )
    }
    
    private func calculateClusterStatistics(for properties: [AuctionProperty]) -> (averagePrice: Double, totalProperties: Int, priceRange: (min: Double, max: Double)) {
        let prices = properties.map { $0.currentBid }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let avgPrice = prices.isEmpty ? 0 : prices.reduce(0, +) / Double(prices.count)
        
        return (
            averagePrice: avgPrice,
            totalProperties: properties.count,
            priceRange: (min: minPrice, max: maxPrice)
        )
    }
    
    // Analying map
    func mapAnalytics(for properties: [AuctionProperty], region: MKCoordinateRegion) async {
        isLoadingData = true
        defer { isLoadingData = false }
        
        let totalBids = properties.map { $0.bidHistory.count }.reduce(0, +)
        let averagePrice = properties.isEmpty ? 0 : properties.map { $0.currentBid }.reduce(0, +) / Double(properties.count)
        let prices = properties.map { $0.currentBid }.sorted()
        let minPrice = prices.first ?? 0
        let maxPrice = prices.last ?? 0
        let medianPrice = prices.isEmpty ? 0 : prices[prices.count / 2]
        
        let analytics = MapAnalytics(
            regionBounds: MapAnalytics.RegionBounds(
                northeast: CLLocationCoordinate2D(
                    latitude: region.center.latitude + region.span.latitudeDelta / 2,
                    longitude: region.center.longitude + region.span.longitudeDelta / 2
                ),
                southwest: CLLocationCoordinate2D(
                    latitude: region.center.latitude - region.span.latitudeDelta / 2,
                    longitude: region.center.longitude - region.span.longitudeDelta / 2
                )
            ),
            timeRange: MapAnalytics.TimeRange(
                start: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
                end: Date()
            ),
            totalProperties: properties.count,
            totalBids: totalBids,
            averagePrice: averagePrice,
            priceRange: MapAnalytics.PriceRange(
                min: minPrice,
                max: maxPrice,
                median: medianPrice
            ),
            hotspots: await identifyHotspots(properties: properties, region: region),
            trends: calculateTrends(properties: properties)
        )
        
        self.propertyAnalytics = analytics
    }
    
    private func identifyHotspots(properties: [AuctionProperty], region: MKCoordinateRegion) async -> [MapAnalytics.Hotspot] {
        // Grid-based hotspot detection
        let gridSize = 10
        let latStep = region.span.latitudeDelta / Double(gridSize)
        let lngStep = region.span.longitudeDelta / Double(gridSize)
        
        var hotspots: [MapAnalytics.Hotspot] = []
        
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                let lat = region.center.latitude - region.span.latitudeDelta/2 + Double(i) * latStep
                let lng = region.center.longitude - region.span.longitudeDelta/2 + Double(j) * lngStep
                
                let cellCenter = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let propertiesInCell = properties.filter { property in
                    let distance = calculateDistance(
                        from: cellCenter,
                        to: CLLocationCoordinate2D(latitude: property.location.latitude, longitude: property.location.longitude)
                    )
                    return distance < 1000 // 1km radius
                }
                
                if propertiesInCell.count >= 3 {
                    let activityScore = Double(propertiesInCell.count) / Double(max(properties.count, 1))
                    let avgPrice = propertiesInCell.isEmpty ? 0 : propertiesInCell.map { $0.currentBid }.reduce(0, +) / Double(propertiesInCell.count)
                    
                    let hotspot = MapAnalytics.Hotspot(
                        coordinate: cellCenter,
                        radius: 1000.0,
                        activityScore: activityScore,
                        propertyCount: propertiesInCell.count,
                        averagePrice: avgPrice,
                        name: "Area \(i)-\(j)"
                    )
                    hotspots.append(hotspot)
                }
            }
        }
        
        return hotspots
    }
    
    private func calculateTrends(properties: [AuctionProperty]) -> [MapAnalytics.Trend] {
        var trends: [MapAnalytics.Trend] = []
        
        // Price trend
        let _ = properties.isEmpty ? 0 : properties.map { $0.currentBid }.reduce(0, +) / Double(properties.count)
        let priceChange = 5.2 // Mock change percentage
        trends.append(MapAnalytics.Trend(
            type: .priceIncrease,
            change: priceChange,
            period: "last 30 days",
            description: "Average price increased by \(priceChange)%"
        ))
        
        // Bid activity trend
        let totalBids = properties.map { $0.bidHistory.count }.reduce(0, +)
        let bidChange = 12.5 // Mock change percentage
        trends.append(MapAnalytics.Trend(
            type: .bidActivity,
            change: bidChange,
            period: "last week",
            description: "Bid activity increased by \(bidChange)%"
        ))
        
        return trends
    }
    
    //  Location Intelligence
    func locationIntelligence(for coordinate: CLLocationCoordinate2D) async {
        isLoadingData = true
        defer { isLoadingData = false }
        
        do {
            let demographics = await fetchDemographics(for: coordinate)
            let amenities = await findNearbyAmenities(coordinate: coordinate)
            
            let intelligence = LocationIntelligence(
                coordinate: coordinate,
                insights: [
                    LocationIntelligence.Insight(
                        type: .investment,
                        title: "Good Investment Area",
                        description: "High property value growth potential",
                        confidence: 0.85
                    )
                ],
                scores: LocationIntelligence.QualityScores(
                    overall: 7.5,
                    safety: 8.0,
                    accessibility: 7.0,
                    amenities: 6.5,
                    investment: 8.5,
                    growth: 7.8
                ),
                demographics: demographics,
                amenities: amenities
            )
            
            self.locationIntelligence = intelligence
        } catch {
            self.errorMessage = "Failed to load location intelligence: \(error.localizedDescription)"
        }
        
    }
    
    private func fetchDemographics(for coordinate: CLLocationCoordinate2D) async -> LocationIntelligence.Demographics {
        
        return LocationIntelligence.Demographics(
            populationDensity: Double.random(in: 100...5000),
            averageIncome: Double.random(in: 30000...120000),
            educationLevel: Double.random(in: 0.6...0.95),
            familyFriendly: Double.random(in: 0.5...0.9)
        )
    }
    
    private func findNearbyAmenities(coordinate: CLLocationCoordinate2D) async -> [LocationIntelligence.Amenity] {
        // Use MKLocalSearch to find real amenities
        var amenities: [LocationIntelligence.Amenity] = []
        
        let searchTypes = ["school", "hospital", "shopping center", "restaurant", "transit"]
        
        for searchType in searchTypes {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchType
            request.region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            
            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                for item in response.mapItems.prefix(3) {
                    let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        .distance(from: CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude))
                    
                    let amenityType: LocationIntelligence.Amenity.AmenityType
                    switch searchType.lowercased() {
                    case "school":
                        amenityType = .school
                    case "hospital":
                        amenityType = .hospital
                    case "shopping center":
                        amenityType = .shopping
                    case "restaurant":
                        amenityType = .restaurant
                    case "transit":
                        amenityType = .transport
                    default:
                        amenityType = .recreation
                    }
                    
                    let amenity = LocationIntelligence.Amenity(
                        type: amenityType,
                        name: item.name ?? "Unknown",
                        distance: distance / 1000.0, // Convert to km
                        rating: Double.random(in: 3.0...5.0)
                    )
                    amenities.append(amenity)
                }
            } catch {
                // Handle search error silently or log it
                print("Search failed for \(searchType): \(error)")
            }
        }
        
        return amenities
    }
    
    private func calculateTransportScore(coordinate: CLLocationCoordinate2D) async -> Double {
        // Calculate based on proximity to transport hubs
        let transportTypes = ["train station", "bus station", "subway", "airport"]
        var scores: [Double] = []
        
        for type in transportTypes {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = type
            request.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            
            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                if let nearest = response.mapItems.first {
                    let distance = calculateDistance(from: coordinate, to: nearest.placemark.coordinate)
                    let score = max(0, 1.0 - (distance / 5000)) // Score based on distance up to 5km
                    scores.append(score)
                }
            } catch {
                scores.append(0)
            }
        }
        
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    private func calculateLocationQuality(demographics: (population: Int, averageIncome: Double, ageDistribution: [String: Double], education: [String: Double]), amenities: [(name: String, type: String, distance: Double, rating: Double)], transportScore: Double) -> Double {
        let demographicsScore = min(demographics.averageIncome / 100000, 1.0) * 0.3
        let amenitiesScore = min(Double(amenities.count) / 20.0, 1.0) * 0.4
        let transportScoreWeighted = transportScore * 0.3
        
        return demographicsScore + amenitiesScore + transportScoreWeighted
    }
}

// CLLocationManagerDelegate
extension MapService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.currentLocation = locations.last
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationManager.startUpdatingLocation()
            default:
                break
            }
        }
    }
}
