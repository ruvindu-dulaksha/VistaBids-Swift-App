import Foundation
import Firebase
import FirebaseFirestore
import CoreLocation
import SwiftUI

// Property Types and Features
enum PropertyType: String, CaseIterable, Codable {
    case house = "house"
    case apartment = "apartment"
    case condo = "condo"
    case townhouse = "townhouse"
    case land = "land"
    case commercial = "commercial"
    
    var displayName: String {
        switch self {
        case .house: return "House"
        case .apartment: return "Apartment"
        case .condo: return "Condo"
        case .townhouse: return "Townhouse"
        case .land: return "Land"
        case .commercial: return "Commercial"
        }
    }
}

struct PropertyFeature: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let category: PropertyFeatureCategory
    
    enum PropertyFeatureCategory: String, Codable, CaseIterable {
        case interior = "interior"
        case exterior = "exterior"
        case amenities = "amenities"
        case security = "security"
        
        var displayName: String {
            switch self {
            case .interior: return "Interior"
            case .exterior: return "Exterior"
            case .amenities: return "Amenities"
            case .security: return "Security"
            }
        }
    }
}

struct PropertyCoordinates: Codable {
    let latitude: Double
    let longitude: Double
    
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct PropertyAddressOld: Codable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    
    var fullAddress: String {
        "\(street), \(city), \(state) \(zipCode), \(country)"
    }
    
    var shortAddress: String {
        "\(city), \(state)"
    }
}

struct PropertySeller: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let profileImageURL: String?
    let rating: Double
    let reviewCount: Int
    let verificationStatus: VerificationStatus
    
    enum VerificationStatus: String, Codable {
        case verified = "verified"
        case pending = "pending"
        case unverified = "unverified"
    }
}

//  Auction Chat
struct AuctionChatMessage: Codable, Identifiable {
    let id: String
    let senderID: String
    let senderName: String
    let message: String
    let timestamp: Date
    let messageType: MessageType
    
    enum MessageType: String, Codable {
        case text = "text"
        case bidUpdate = "bid_update"
        case system = "system"
    }
}

//  User Lists and History
struct WatchlistItem: Codable, Identifiable {
    let id: String
    let propertyID: String
    let userID: String
    let addedDate: Date
    let notificationsEnabled: Bool
}

struct BidHistoryItem: Codable, Identifiable {
    let id: String
    let propertyID: String
    let bidAmount: Double
    let timestamp: Date
    let status: BidStatus
    let propertyTitle: String
    let propertyImageURL: String?
    
    enum BidStatus: String, Codable {
        case active = "active"
        case outbid = "outbid"
        case won = "won"
        case lost = "lost"
    }
}

//  Notifications
struct AuctionWinnerNotification: Codable, Identifiable {
    let id: String
    let propertyID: String
    let propertyTitle: String
    let winningBid: Double
    let timestamp: Date
    let isRead: Bool
    let actionRequired: Bool
}

//  Search and Filters
struct PropertySearchFilters: Codable {
    var propertyTypes: [PropertyType] = []
    var minPrice: Double?
    var maxPrice: Double?
    var minBedrooms: Int?
    var maxBedrooms: Int?
    var minBathrooms: Int?
    var maxBathrooms: Int?
    var features: [String] = []
    var radius: Double = 10.0 // kilometers
    var centerLocation: PropertyCoordinates?
    var sortBy: SortOption = .endingSoon
    
    enum SortOption: String, CaseIterable, Codable {
        case endingSoon = "ending_soon"
        case priceAsc = "price_asc"
        case priceDesc = "price_desc"
        case newest = "newest"
        case oldest = "oldest"
        
        var displayName: String {
            switch self {
            case .endingSoon: return "Ending Soon"
            case .priceAsc: return "Price: Low to High"
            case .priceDesc: return "Price: High to Low"
            case .newest: return "Newest First"
            case .oldest: return "Oldest First"
            }
        }
    }
}

//  Analytics
struct PropertyAnalytics: Codable {
    let viewCount: Int
    let watchlistCount: Int
    let bidCount: Int
    let avgBidAmount: Double
    let peakViewingTime: Date?
    let geographicDistribution: [String: Int] // region: count
}

//  User Preferences
struct UserNotificationSettings: Codable {
    var bidOutbid: Bool = true
    var auctionEnding: Bool = true
    var newProperties: Bool = false
    var priceDrops: Bool = true
    var auctionWon: Bool = true
    var auctionLost: Bool = false
    var marketUpdates: Bool = false
    var emailNotifications: Bool = true
    var pushNotifications: Bool = true
}

struct UserPreferences: Codable {
    var favoritePropertyTypes: [PropertyType] = []
    var preferredPriceRange: ClosedRange<Double>?
    var searchRadius: Double = 25.0
    var notificationSettings: UserNotificationSettings = UserNotificationSettings()
    var autoWatchNewListings: Bool = false
    var bidIncrement: Double = 1000.0
}

// Advanced Search Options
struct AdvancedSearchOptions: Codable {
    var filtersEnabled: Bool = false
    var minPrice: Double?
    var maxPrice: Double?
    var minBedrooms: Int?
    var minBathrooms: Int?
    var propertyType: String = ""
    var status: SalePropertyStatus?
}