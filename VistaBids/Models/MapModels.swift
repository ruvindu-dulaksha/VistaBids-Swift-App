//
//  MapModels.swift
//  VistaBids
//
//  Advanced MapKit Models for Heat Maps, Clustering, and Analytics
//

import Foundation
import MapKit
import SwiftUI
import FirebaseFirestore

// MARK: - Heat Map Models
struct HeatMapPoint: Identifiable, Codable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let intensity: Double // 0.0 to 1.0
    let value: Double // Actual value (price, bids, etc.)
    let type: HeatMapType
    let timestamp: Date
    
    enum HeatMapType: String, CaseIterable, Codable {
        case bidActivity = "bid_activity"
        case propertyValue = "property_value"
        case userActivity = "user_activity"
        case priceAppreciation = "price_appreciation"
        case demandLevel = "demand_level"
        
        var displayName: String {
            switch self {
            case .bidActivity: return "Bid Activity"
            case .propertyValue: return "Property Values"
            case .userActivity: return "User Activity"
            case .priceAppreciation: return "Price Growth"
            case .demandLevel: return "Demand Levels"
            }
        }
        
        var color: Color {
            switch self {
            case .bidActivity: return .red
            case .propertyValue: return .green
            case .userActivity: return .blue
            case .priceAppreciation: return .orange
            case .demandLevel: return .purple
            }
        }
    }
    
    init(coordinate: CLLocationCoordinate2D, intensity: Double, value: Double, type: HeatMapType) {
        self.coordinate = coordinate
        self.intensity = min(max(intensity, 0.0), 1.0)
        self.value = value
        self.type = type
        self.timestamp = Date()
    }
}

// MARK: - Property Clustering
struct PropertyCluster: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let properties: [AuctionProperty]
    let averagePrice: Double
    let totalBids: Int
    let clusterLevel: ClusterLevel
    
    enum ClusterLevel: Int, CaseIterable {
        case individual = 1
        case small = 5
        case medium = 20
        case large = 50
        
        var displayRadius: CGFloat {
            switch self {
            case .individual: return 30
            case .small: return 40
            case .medium: return 50
            case .large: return 60
            }
        }
        
        var color: Color {
            switch self {
            case .individual: return .blue
            case .small: return .green
            case .medium: return .orange
            case .large: return .red
            }
        }
        
        var clusterRadius: Double {
            switch self {
            case .individual: return 100  // meters
            case .small: return 500
            case .medium: return 1000
            case .large: return 2000
            }
        }
        
        var minimumProperties: Int {
            switch self {
            case .individual: return 1
            case .small: return 2
            case .medium: return 5
            case .large: return 10
            }
        }
    }
    
    var displayTitle: String {
        if properties.count == 1 {
            return properties.first?.title ?? "Property"
        } else {
            return "\(properties.count) Properties"
        }
    }
    
    var displaySubtitle: String {
        return "Avg: $\(Int(averagePrice))"
    }
}

// MARK: - Map Analytics Data
struct MapAnalytics: Codable {
    let regionBounds: RegionBounds
    let timeRange: TimeRange
    let totalProperties: Int
    let totalBids: Int
    let averagePrice: Double
    let priceRange: PriceRange
    let hotspots: [Hotspot]
    let trends: [Trend]
    
    struct RegionBounds: Codable {
        let northeast: CLLocationCoordinate2D
        let southwest: CLLocationCoordinate2D
    }
    
    struct TimeRange: Codable {
        let start: Date
        let end: Date
    }
    
    struct PriceRange: Codable {
        let min: Double
        let max: Double
        let median: Double
    }
    
    struct Hotspot: Identifiable, Codable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let radius: Double
        let activityScore: Double
        let propertyCount: Int
        let averagePrice: Double
        let name: String
    }
    
    struct Trend: Identifiable, Codable {
        let id = UUID()
        let type: TrendType
        let change: Double
        let period: String
        let description: String
        
        enum TrendType: String, CaseIterable, Codable {
            case priceIncrease = "price_increase"
            case bidActivity = "bid_activity"
            case newListings = "new_listings"
            case userEngagement = "user_engagement"
        }
    }
}

// MARK: - Advanced Map Filters
struct MapFilter: Identifiable {
    let id = UUID()
    let type: FilterType
    var isEnabled: Bool
    var value: FilterValue
    
    enum FilterType: String, CaseIterable {
        case priceRange = "price_range"
        case propertyType = "property_type"
        case auctionStatus = "auction_status"
        case timeRange = "time_range"
        case bidCount = "bid_count"
        case distance = "distance"
        
        var displayName: String {
            switch self {
            case .priceRange: return "Price Range"
            case .propertyType: return "Property Type"
            case .auctionStatus: return "Auction Status"
            case .timeRange: return "Time Range"
            case .bidCount: return "Bid Activity"
            case .distance: return "Distance"
            }
        }
        
        var icon: String {
            switch self {
            case .priceRange: return "dollarsign.circle"
            case .propertyType: return "house"
            case .auctionStatus: return "clock"
            case .timeRange: return "calendar"
            case .bidCount: return "hand.raised"
            case .distance: return "location"
            }
        }
    }
    
    enum FilterValue {
        case priceRange(min: Double, max: Double)
        case propertyTypes([PropertyCategory])
        case auctionStatuses([AuctionStatus])
        case timeRange(start: Date, end: Date)
        case bidRange(min: Int, max: Int)
        case distance(radius: Double, from: CLLocationCoordinate2D)
    }
}

// MARK: - Map Layer Configuration
struct MapLayerConfig: Identifiable {
    let id = UUID()
    let type: LayerType
    var isVisible: Bool
    var opacity: Double
    var style: LayerStyle
    
    enum LayerType: String, CaseIterable {
        case properties = "properties"
        case heatMap = "heat_map"
        case clusters = "clusters"
        case routes = "routes"
        case boundaries = "boundaries"
        case transit = "transit"
        case traffic = "traffic"
        
        var displayName: String {
            switch self {
            case .properties: return "Properties"
            case .heatMap: return "Heat Map"
            case .clusters: return "Clusters"
            case .routes: return "Routes"
            case .boundaries: return "Boundaries"
            case .transit: return "Transit"
            case .traffic: return "Traffic"
            }
        }
        
        var icon: String {
            switch self {
            case .properties: return "house.fill"
            case .heatMap: return "flame.fill"
            case .clusters: return "circle.grid.3x3.fill"
            case .routes: return "arrow.triangle.turn.up.right.diamond.fill"
            case .boundaries: return "map"
            case .transit: return "tram.fill"
            case .traffic: return "car.fill"
            }
        }
    }
    
    enum LayerStyle {
        case standard
        case satellite
        case hybrid
        case terrain
    }
}

// MARK: - Search and Discovery
struct MapSearchResult: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let type: ResultType
    let relevanceScore: Double
    let distance: Double?
    
    enum ResultType {
        case property
        case neighborhood
        case landmark
        case business
        case address
    }
}

// MARK: - Map Route Information
struct MapRoute: Identifiable {
    let id = UUID()
    let name: String
    let coordinates: [CLLocationCoordinate2D]
    let distance: Double
    let estimatedTime: TimeInterval
    let transportType: MKDirectionsTransportType
    let instructions: [RouteInstruction]
    
    struct RouteInstruction {
        let text: String
        let distance: Double
        let coordinate: CLLocationCoordinate2D
    }
}

// MARK: - Location Intelligence
struct LocationIntelligence {
    let coordinate: CLLocationCoordinate2D
    let insights: [Insight]
    let scores: QualityScores
    let demographics: Demographics
    let amenities: [Amenity]
    
    struct Insight {
        let type: InsightType
        let title: String
        let description: String
        let confidence: Double
        
        enum InsightType {
            case investment
            case growth
            case risk
            case opportunity
        }
    }
    
    struct QualityScores {
        let overall: Double
        let safety: Double
        let accessibility: Double
        let amenities: Double
        let investment: Double
        let growth: Double
    }
    
    struct Demographics {
        let populationDensity: Double
        let averageIncome: Double
        let educationLevel: Double
        let familyFriendly: Double
    }
    
    struct Amenity {
        let type: AmenityType
        let name: String
        let distance: Double
        let rating: Double
        
        enum AmenityType: String, CaseIterable {
            case school = "school"
            case hospital = "hospital"
            case shopping = "shopping"
            case restaurant = "restaurant"
            case transport = "transport"
            case recreation = "recreation"
            case banking = "banking"
            case gas = "gas"
        }
    }
}

// MARK: - Codable Extensions for CLLocationCoordinate2D
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}
