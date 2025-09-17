//
//  MapSupportingViews.swift
//  VistaBids
//
//  Advanced Map Supporting Views including Heat Maps, Clustering, and Analytics
//

import SwiftUI
import MapKit
import Foundation

// MARK: - Heat Map Overlay
class HeatMapOverlay: NSObject, MKOverlay {
    let points: [HeatMapPoint]
    let radius: Double
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    
    init(points: [HeatMapPoint], radius: Double = 2000) {
        self.points = points
        self.radius = radius
        
        guard !points.isEmpty else {
            self.coordinate = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
            self.boundingMapRect = MKMapRect()
            super.init()
            return
        }
        
        let coordinates = points.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLng = coordinates.map { $0.longitude }.min()!
        let maxLng = coordinates.map { $0.longitude }.max()!
        
        self.coordinate = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        
        let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: maxLat, longitude: minLng))
        let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: minLat, longitude: maxLng))
        
        self.boundingMapRect = MKMapRect(
            x: topLeft.x,
            y: topLeft.y,
            width: bottomRight.x - topLeft.x,
            height: bottomRight.y - topLeft.y
        )
        
        super.init()
    }
}

// Heat Map Renderer
class HeatMapRenderer: MKOverlayRenderer {
    private let heatMapOverlay: HeatMapOverlay
    
    init(overlay: HeatMapOverlay) {
        self.heatMapOverlay = overlay
        super.init(overlay: overlay)
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let rect = self.rect(for: mapRect)
        
        // Validate rect size
        guard rect.width > 0 && rect.height > 0 else { return }
        
        // Save the context state
        context.saveGState()
        
        // Set blend mode for proper heatmap visualization
        context.setBlendMode(.screen)
        
        // Draw heat points directly in the map context
        for point in heatMapOverlay.points {
            // Validate coordinates
            guard CLLocationCoordinate2DIsValid(point.coordinate) else { continue }
            
            let pointInMap = MKMapPoint(point.coordinate)
            let pointInRect = self.point(for: pointInMap)
            
            // Check if point is within visible rect with some padding
            let paddedRect = rect.insetBy(dx: -100, dy: -100)
            if paddedRect.contains(pointInRect) {
                drawHeatPoint(at: pointInRect, intensity: point.intensity, type: point.type, in: context, zoomScale: zoomScale)
            }
        }
        
        // Restore the context state
        context.restoreGState()
    }
    
    private func drawHeatPoint(at point: CGPoint, intensity: Double, type: HeatMapPoint.HeatMapType, in context: CGContext, zoomScale: MKZoomScale) {
        // Create larger radius based on zoom level and intensity for better visibility
        let baseRadius = CGFloat(50 + (intensity * 100)) 
        let radius = baseRadius / max(sqrt(zoomScale), 0.5) // Scale with zoom level, minimum divisor
        
        // Ensure minimum and maximum radius for visibility
        let finalRadius = max(20, min(radius, 200))
        
        // Create vibrant color based on type and intensity
        let baseColor = colorForHeatMapType(type)
        let centerAlpha = CGFloat(0.6 + (intensity * 0.4)) 
        let edgeAlpha = CGFloat(0.1)
        
        // Create multiple gradient layers for better heatmap effect
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Create multi-stop gradient for better heatmap visualization
        let colors = [
            baseColor.withAlphaComponent(centerAlpha).cgColor,      // Strong center
            baseColor.withAlphaComponent(centerAlpha * 0.7).cgColor, // Mid intensity
            baseColor.withAlphaComponent(centerAlpha * 0.4).cgColor, // Lower intensity
            baseColor.withAlphaComponent(edgeAlpha).cgColor          // Soft edge
        ]
        let locations: [CGFloat] = [0.0, 0.3, 0.7, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
            return
        }
        
        // Draw radial gradient with better blending
        context.saveGState()
        context.setBlendMode(.normal) // Use normal blend mode for individual points
        
        context.drawRadialGradient(
            gradient,
            startCenter: point,
            startRadius: 0,
            endCenter: point,
            endRadius: finalRadius,
            options: [.drawsBeforeStartLocation]
        )
        
        context.restoreGState()
    }
    
    private func colorForHeatMapType(_ type: HeatMapPoint.HeatMapType) -> UIColor {
        switch type {
        case .bidActivity:
            return UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0) // Bright red for high activity
        case .propertyValue:
            return UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0) // Bright green for value
        case .userActivity:
            return UIColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 1.0) // Bright blue for user activity
        case .priceAppreciation:
            return UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0) // Orange for price changes
        case .demandLevel:
            return UIColor(red: 0.8, green: 0.2, blue: 0.8, alpha: 1.0) // Purple for demand
        }
    }
}

// Cluster Annotation
class ClusterAnnotation: NSObject, MKAnnotation {
    let cluster: PropertyCluster
    
    var coordinate: CLLocationCoordinate2D {
        return cluster.coordinate
    }
    
    var title: String? {
        return cluster.displayTitle
    }
    
    var subtitle: String? {
        return cluster.displaySubtitle
    }
    
    init(cluster: PropertyCluster) {
        self.cluster = cluster
        super.init()
    }
}

// Enhanced Property Annotation
class PropertyAnnotation: NSObject, MKAnnotation {
    let property: AuctionProperty
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: property.location.latitude,
            longitude: property.location.longitude
        )
    }
    
    var title: String? {
        return property.title
    }
    
    var subtitle: String? {
        return "$\(Int(property.currentBid))"
    }
    
    init(property: AuctionProperty) {
        self.property = property
        super.init()
    }
}

// Cluster Annotation View
class ClusterAnnotationView: MKAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let cluster = newValue as? ClusterAnnotation else { return }
            setupView(for: cluster)
        }
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
    }
    
    private func setupView(for cluster: ClusterAnnotation) {
        let level = cluster.cluster.clusterLevel
        let size = level.displayRadius
        
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
        
        // Create custom view
        let containerView = UIView(frame: bounds)
        containerView.backgroundColor = UIColor(level.color)
        containerView.layer.cornerRadius = size / 2
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.white.cgColor
        
        // Add count label
        let label = UILabel()
        label.text = "\(cluster.cluster.properties.count)"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: size / 3)
        label.textAlignment = .center
        label.frame = containerView.bounds
        
        containerView.addSubview(label)
        addSubview(containerView)
    }
}

//  Enhanced Property Annotation View
class PropertyAnnotationView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let propertyAnnotation = newValue as? PropertyAnnotation else { return }
            setupView(for: propertyAnnotation.property)
        }
    }
    
    private func setupView(for property: AuctionProperty) {
        markerTintColor = UIColor(Color.auctionStatusColor(property.status))
        glyphText = "🏠"
        
        // Add custom callout
        canShowCallout = true
        
        // Add detail button
        let detailButton = UIButton(type: .detailDisclosure)
        rightCalloutAccessoryView = detailButton
        
        // Add image view
        if let imageURL = property.images.first, let url = URL(string: imageURL) {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            
            // Load image asynchronously
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }
            }.resume()
            
            leftCalloutAccessoryView = imageView
        }
    }
}

// Map Filter View
struct MapFilterView: View {
    @Binding var filters: [MapFilter]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach($filters) { $filter in
                    FilterRowView(filter: $filter)
                }
            }
            .navigationTitle("Map Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func resetFilters() {
        for index in filters.indices {
            filters[index].isEnabled = false
        }
    }
}

//  Filter Row View
struct FilterRowView: View {
    @Binding var filter: MapFilter
    
    var body: some View {
        HStack {
            Image(systemName: filter.type.icon)
                .foregroundColor(.accentBlues)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(filter.type.displayName)
                    .font(.headline)
                
                filterValueView
            }
            
            Spacer()
            
            Toggle("", isOn: $filter.isEnabled)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var filterValueView: some View {
        switch filter.value {
        case .priceRange(let min, let max):
            Text("$\(Int(min)) - $\(Int(max))")
                .font(.caption)
                .foregroundColor(.secondary)
        
        case .propertyTypes(let types):
            Text("\(types.count) types selected")
                .font(.caption)
                .foregroundColor(.secondary)
        
        case .auctionStatuses(let statuses):
            Text("\(statuses.count) statuses selected")
                .font(.caption)
                .foregroundColor(.secondary)
        
        case .timeRange(let start, let end):
            Text("\(DateFormatter.shortDate.string(from: start)) - \(DateFormatter.shortDate.string(from: end))")
                .font(.caption)
                .foregroundColor(.secondary)
        
        case .bidRange(let min, let max):
            Text("\(min) - \(max) bids")
                .font(.caption)
                .foregroundColor(.secondary)
        
        case .distance(let radius, _):
            Text("Within \(Int(radius/1000))km")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

//  Map Legend View
struct MapLegendView: View {
    let heatMapType: HeatMapPoint.HeatMapType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Heat Map Legend")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(heatMapType.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Low")
                    .font(.caption)
                
                HStack(spacing: 2) {
                    ForEach(0..<10) { index in
                        Rectangle()
                            .fill(Color.heatMapColor(intensity: Double(index) / 9.0))
                            .frame(width: 15, height: 8)
                    }
                }
                
                Text("High")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

//  Map Controls View
struct MapControlsView: View {
    @Binding var showHeatMap: Bool
    @Binding var showClusters: Bool
    @Binding var showFilters: Bool
    @Binding var mapType: MKMapType
    @Binding var selectedHeatMapType: HeatMapPoint.HeatMapType
    
    var body: some View {
        VStack(spacing: 12) {
            // Map Type Selector
            HStack {
                ForEach([MKMapType.standard, .satellite, .hybrid], id: \.self) { type in
                    Button(action: { mapType = type }) {
                        Text(type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(mapType == type ? Color.accentBlues : Color.gray.opacity(0.3))
                            .foregroundColor(mapType == type ? .white : .primary)
                            .cornerRadius(6)
                    }
                }
            }
            
            // Toggle Controls
            VStack(spacing: 8) {
                Toggle("Heat Map", isOn: $showHeatMap)
                Toggle("Clusters", isOn: $showClusters)
            }
            .font(.caption)
            
            // Heat Map Type Selector
            if showHeatMap {
                Picker("Heat Map Type", selection: $selectedHeatMapType) {
                    ForEach(HeatMapPoint.HeatMapType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .font(.caption)
            }
            
            // Filter Button
            Button(action: { showFilters.toggle() }) {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("Filters")
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentBlues)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

//  Extensions
extension MKMapType {
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
        case .hybrid: return "Hybrid"
        default: return "Standard"
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
