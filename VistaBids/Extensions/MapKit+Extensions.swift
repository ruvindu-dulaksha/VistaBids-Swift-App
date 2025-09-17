//
//  MapKit+Extensions.swift
//  VistaBids
//
//  Advanced MapKit Extensions for Enhanced Functionality
//

import MapKit
import Foundation
import SwiftUI

//  MKMapView Extensions
extension MKMapView {
    
    /// Add heat map overlay to the map
    func addHeatMapOverlay(points: [HeatMapPoint], radius: Double = 2000) {
        let overlay = HeatMapOverlay(points: points, radius: radius)
        addOverlay(overlay)
    }
    
    /// Remove all heat map overlays
    func removeHeatMapOverlays() {
        let heatMapOverlays = overlays.compactMap { $0 as? HeatMapOverlay }
        removeOverlays(heatMapOverlays)
    }
    
    /// Add clustered annotations
    func addClusteredAnnotations(_ clusters: [PropertyCluster]) {
        let annotations = clusters.map { ClusterAnnotation(cluster: $0) }
        addAnnotations(annotations)
    }
    
    /// Animate to region with custom animation
    func animateToRegion(_ region: MKCoordinateRegion, duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
            self.setRegion(region, animated: false)
        }
    }
    
    /// Calculate optimal region for properties
    func optimalRegion(for properties: [AuctionProperty], padding: Double = 0.01) -> MKCoordinateRegion {
        guard !properties.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        let coordinates = properties.map { 
            CLLocationCoordinate2D(latitude: $0.location.latitude, longitude: $0.location.longitude)
        }
        
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLng = coordinates.map { $0.longitude }.min()!
        let maxLng = coordinates.map { $0.longitude }.max()!
        
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2
        
        let latDelta = max(maxLat - minLat + padding, 0.01)
        let lngDelta = max(maxLng - minLng + padding, 0.01)
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        )
    }
    
    /// Add route overlay
    func addRoute(_ route: MapRoute, color: UIColor = .systemBlue, lineWidth: CGFloat = 5.0) {
        let polyline = MKPolyline(coordinates: route.coordinates, count: route.coordinates.count)
        polyline.title = route.name
        addOverlay(polyline)
    }
    
    /// Enable traffic overlay
    func showTraffic(_ show: Bool = true) {
        showsTraffic = show
    }
    
    /// Enable building overlay
    func showBuildings(_ show: Bool = true) {
        showsBuildings = show
    }
    
    /// Enable compass
    func showCompass(_ show: Bool = true) {
        showsCompass = show
    }
    
    /// Enable scale
    func showScale(_ show: Bool = true) {
        showsScale = show
    }
}

//  MKCoordinateRegion Extensions
extension MKCoordinateRegion {
    
    /// Calculate region area in square kilometers
    var area: Double {
        let latMeters = span.latitudeDelta * 111_000 // Approximate meters per degree latitude
        let lngMeters = span.longitudeDelta * 111_000 * cos(center.latitude * .pi / 180)
        return (latMeters * lngMeters) / 1_000_000 // Convert to square kilometers
    }
    
    /// Check if coordinate is within region
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let latRange = (center.latitude - span.latitudeDelta/2)...(center.latitude + span.latitudeDelta/2)
        let lngRange = (center.longitude - span.longitudeDelta/2)...(center.longitude + span.longitudeDelta/2)
        
        return latRange.contains(coordinate.latitude) && lngRange.contains(coordinate.longitude)
    }
    
    /// Create region with radius in meters
    static func region(center: CLLocationCoordinate2D, radiusInMeters: Double) -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: center,
            latitudinalMeters: radiusInMeters * 2,
            longitudinalMeters: radiusInMeters * 2
        )
    }
    
    /// Expand region by factor
    func expanded(by factor: Double) -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta * factor,
                longitudeDelta: span.longitudeDelta * factor
            )
        )
    }
}

//  CLLocationCoordinate2D Extensions
extension CLLocationCoordinate2D {
    
    /// Calculate distance to another coordinate
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
    
    /// Calculate bearing to another coordinate
    func bearing(to coordinate: CLLocationCoordinate2D) -> Double {
        let lat1 = latitude * .pi / 180
        let lat2 = coordinate.latitude * .pi / 180
        let deltaLon = (coordinate.longitude - longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(x, y) * 180 / .pi
        return bearing >= 0 ? bearing : bearing + 360
    }
    
    /// Check if coordinate is valid
    var isValid: Bool {
        return !latitude.isNaN && !longitude.isNaN &&
               !latitude.isInfinite && !longitude.isInfinite &&
               latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180
    }
    
    /// Format coordinate as string
    var formattedString: String {
        return String(format: "%.6f, %.6f", latitude, longitude)
    }
    
    /// Create coordinate with offset in meters
    func offset(latitudeMeters: Double, longitudeMeters: Double) -> CLLocationCoordinate2D {
        let latOffset = latitudeMeters / 111_111.0
        let lngOffset = longitudeMeters / (111_111.0 * cos(latitude * .pi / 180))
        
        return CLLocationCoordinate2D(
            latitude: latitude + latOffset,
            longitude: longitude + lngOffset
        )
    }
}

// CLLocation Extensions
extension CLLocation {
    
    /// Format distance as readable string
    var formattedDistance: String {
        if horizontalAccuracy < 1000 {
            return "\(Int(horizontalAccuracy))m"
        } else {
            let km = horizontalAccuracy / 1000.0
            return String(format: "%.1fkm", km)
        }
    }
    
    /// Check if location is in Sri Lanka (for app context)
    var isInSriLanka: Bool {
        // Sri Lanka bounds approximately
        let sriLankaBounds = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
        return sriLankaBounds.contains(coordinate)
    }
}

//  MKAnnotation Protocol Extensions
extension MKAnnotation {
    
    /// Calculate distance from user location
    func distance(from userLocation: CLLocation?) -> CLLocationDistance? {
        guard let userLocation = userLocation else { return nil }
        let annotationLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return userLocation.distance(from: annotationLocation)
    }
    
    /// Format distance as string
    func formattedDistance(from userLocation: CLLocation?) -> String? {
        guard let distance = distance(from: userLocation) else { return nil }
        
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let km = distance / 1000.0
            return String(format: "%.1fkm", km)
        }
    }
}

//  MKPolyline Extensions
extension MKPolyline {
    
    /// Calculate polyline length
    var length: CLLocationDistance {
        var length: CLLocationDistance = 0
        let coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount)
        getCoordinates(coordinates, range: NSRange(location: 0, length: pointCount))
        
        for i in 0..<pointCount - 1 {
            let location1 = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let location2 = CLLocation(latitude: coordinates[i + 1].latitude, longitude: coordinates[i + 1].longitude)
            length += location1.distance(from: location2)
        }
        
        coordinates.deallocate()
        return length
    }
    
    /// Get coordinates as array
    var coordinates: [CLLocationCoordinate2D] {
        let coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount)
        getCoordinates(coordinates, range: NSRange(location: 0, length: pointCount))
        
        let result = Array(UnsafeBufferPointer(start: coordinates, count: pointCount))
        coordinates.deallocate()
        return result
    }
}

//  Color Extensions for Map Styling
extension Color {
    
    /// Heat map color based on intensity
    static func heatMapColor(intensity: Double) -> Color {
        let normalizedIntensity = max(0, min(1, intensity))
        
        if normalizedIntensity < 0.25 {
            return Color.blue.opacity(0.3 + normalizedIntensity)
        } else if normalizedIntensity < 0.5 {
            return Color.green.opacity(0.3 + normalizedIntensity)
        } else if normalizedIntensity < 0.75 {
            return Color.yellow.opacity(0.3 + normalizedIntensity)
        } else {
            return Color.red.opacity(0.3 + normalizedIntensity)
        }
    }
    
    /// Property price color coding
    static func priceColor(price: Double, minPrice: Double, maxPrice: Double) -> Color {
        guard maxPrice > minPrice else { return .gray }
        
        let normalized = (price - minPrice) / (maxPrice - minPrice)
        
        if normalized < 0.33 {
            return .green
        } else if normalized < 0.66 {
            return .orange
        } else {
            return .red
        }
    }
    
    /// Auction status color
    static func auctionStatusColor(_ status: AuctionStatus) -> Color {
        switch status {
        case .upcoming: return .blue
        case .active: return .green
        case .ended: return .orange
        case .sold: return .purple
        case .cancelled: return .red
        }
    }
}

//  Map Style Configurations
struct MapStyleConfig {
    static let defaultStyle = MKStandardMapConfiguration()
    
    static let satelliteStyle: MKMapConfiguration = {
        let config = MKImageryMapConfiguration()
        return config
    }()
    
    static let hybridStyle: MKMapConfiguration = {
        let config = MKHybridMapConfiguration()
        return config
    }()
    
    static let terrainStyle: MKMapConfiguration = {
        let config = MKStandardMapConfiguration()
        config.emphasisStyle = .muted
        return config
    }()
}
