//
//  BiddingModels.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-16.
//

import Foundation
import FirebaseFirestore
import CoreLocation
import SwiftUI

// MARK: - Auction Property Model
struct AuctionProperty: Identifiable, Codable {
    var id: String?
    let sellerId: String
    let sellerName: String
    let title: String
    let description: String
    let startingPrice: Double
    var currentBid: Double
    var highestBidderId: String?
    var highestBidderName: String?
    let images: [String]
    let videos: [String]
    let arModelURL: String?
    let address: PropertyAddress
    let location: GeoPoint
    let features: PropertyFeatures
    var auctionStartTime: Date
    var auctionEndTime: Date
    let auctionDuration: AuctionDuration
    var status: AuctionStatus
    let category: PropertyCategory
    var bidHistory: [BidEntry]
    var watchlistUsers: [String]
    let createdAt: Date
    var updatedAt: Date
    var winnerId: String?
    var winnerName: String?
    var finalPrice: Double?
    var paymentStatus: PaymentStatus?
    var transactionId: String?
    
    // AR/Panoramic Features
    let panoramicImages: [PanoramicImage]
    let walkthroughVideoURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id, sellerId, sellerName, title, description, startingPrice
        case currentBid, highestBidderId, highestBidderName, images, videos, arModelURL
        case address, location, features, auctionStartTime, auctionEndTime, auctionDuration
        case status, category, bidHistory, watchlistUsers, createdAt, updatedAt
        case winnerId, winnerName, finalPrice, paymentStatus, transactionId
        case panoramicImages, walkthroughVideoURL
    }
    
    // Standard initializer for creating instances
    init(sellerId: String, sellerName: String, title: String, description: String, 
         startingPrice: Double, currentBid: Double, highestBidderId: String? = nil, 
         highestBidderName: String? = nil, images: [String] = [], videos: [String] = [], 
         arModelURL: String? = nil, address: PropertyAddress, location: GeoPoint,
         features: PropertyFeatures, auctionStartTime: Date, auctionEndTime: Date,
         auctionDuration: AuctionDuration, status: AuctionStatus, 
         category: PropertyCategory, bidHistory: [BidEntry] = [], 
         watchlistUsers: [String] = [], createdAt: Date, updatedAt: Date,
         winnerId: String? = nil, winnerName: String? = nil, finalPrice: Double? = nil,
         paymentStatus: PaymentStatus? = nil, transactionId: String? = nil,
         panoramicImages: [PanoramicImage] = [], walkthroughVideoURL: String? = nil) {
        self.id = nil
        self.sellerId = sellerId
        self.sellerName = sellerName
        self.title = title
        self.description = description
        self.startingPrice = startingPrice
        self.currentBid = currentBid
        self.highestBidderId = highestBidderId
        self.highestBidderName = highestBidderName
        self.images = images
        self.videos = videos
        self.arModelURL = arModelURL
        self.address = address
        self.location = location
        self.features = features
        self.auctionStartTime = auctionStartTime
        self.auctionEndTime = auctionEndTime
        self.auctionDuration = auctionDuration
        self.status = status
        self.category = category
        self.bidHistory = bidHistory
        self.watchlistUsers = watchlistUsers
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.winnerId = winnerId
        self.winnerName = winnerName
        self.finalPrice = finalPrice
        self.paymentStatus = paymentStatus
        self.transactionId = transactionId
        self.panoramicImages = panoramicImages
        self.walkthroughVideoURL = walkthroughVideoURL
    }
    
    // Custom initializer for safer decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields with fallbacks
        self.sellerId = try container.decodeIfPresent(String.self, forKey: .sellerId) ?? "unknown"
        self.sellerName = try container.decodeIfPresent(String.self, forKey: .sellerName) ?? "Unknown Seller"
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? "No description available"
        self.startingPrice = try container.decodeIfPresent(Double.self, forKey: .startingPrice) ?? 0.0
        self.currentBid = try container.decodeIfPresent(Double.self, forKey: .currentBid) ?? startingPrice
        
        // Handle address with fallback
        if let address = try? container.decode(PropertyAddress.self, forKey: .address) {
            self.address = address
        } else {
            self.address = PropertyAddress(
                street: "Unknown Street",
                city: "Unknown City",
                state: "Unknown State",
                postalCode: "00000",
                country: "Unknown Country"
            )
        }
        
        // Handle location with fallback
        if let location = try? container.decode(GeoPoint.self, forKey: .location) {
            self.location = location
        } else {
            self.location = GeoPoint(latitude: 0.0, longitude: 0.0)
        }
        
        // Handle features with fallback
        if let features = try? container.decode(PropertyFeatures.self, forKey: .features) {
            self.features = features
        } else {
            self.features = PropertyFeatures(
                bedrooms: 1,
                bathrooms: 1,
                area: 0.0,
                yearBuilt: nil,
                parkingSpaces: nil,
                hasGarden: false,
                hasPool: false,
                hasGym: false,
                floorNumber: nil,
                totalFloors: nil,
                propertyType: "Unknown"
            )
        }
        
        // Handle dates with fallbacks
        self.auctionStartTime = try container.decodeIfPresent(Date.self, forKey: .auctionStartTime) ?? Date()
        self.auctionEndTime = try container.decodeIfPresent(Date.self, forKey: .auctionEndTime) ?? Date().addingTimeInterval(24*60*60) // 24 hours from now
        
        // Handle auctionDuration with default fallback
        self.auctionDuration = (try? container.decode(AuctionDuration.self, forKey: .auctionDuration)) ?? .oneDay
        self.status = (try? container.decode(AuctionStatus.self, forKey: .status)) ?? .upcoming
        self.category = (try? container.decode(PropertyCategory.self, forKey: .category)) ?? .residential
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        
        // Optional fields with defaults
        self.highestBidderId = try container.decodeIfPresent(String.self, forKey: .highestBidderId)
        self.highestBidderName = try container.decodeIfPresent(String.self, forKey: .highestBidderName)
        self.images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        self.videos = try container.decodeIfPresent([String].self, forKey: .videos) ?? []
        self.arModelURL = try container.decodeIfPresent(String.self, forKey: .arModelURL)
        self.bidHistory = (try? container.decode([BidEntry].self, forKey: .bidHistory)) ?? []
        self.watchlistUsers = try container.decodeIfPresent([String].self, forKey: .watchlistUsers) ?? []
        self.winnerId = try container.decodeIfPresent(String.self, forKey: .winnerId)
        self.winnerName = try container.decodeIfPresent(String.self, forKey: .winnerName)
        self.finalPrice = try container.decodeIfPresent(Double.self, forKey: .finalPrice)
        self.paymentStatus = try container.decodeIfPresent(PaymentStatus.self, forKey: .paymentStatus)
        self.transactionId = try container.decodeIfPresent(String.self, forKey: .transactionId)
        self.panoramicImages = (try? container.decode([PanoramicImage].self, forKey: .panoramicImages)) ?? []
        self.walkthroughVideoURL = try container.decodeIfPresent(String.self, forKey: .walkthroughVideoURL)
        
        // Handle ID separately - it's set manually
        self.id = nil
    }
}

// MARK: - Property Address
struct PropertyAddress: Codable {
    let street: String
    let city: String
    let state: String
    let postalCode: String
    let country: String
    
    var fullAddress: String {
        return "\(street), \(city), \(state) \(postalCode), \(country)"
    }
}

// MARK: - Property Features
struct PropertyFeatures: Codable {
    let bedrooms: Int
    let bathrooms: Int
    let area: Double
    let yearBuilt: Int?
    let parkingSpaces: Int?
    let hasGarden: Bool
    let hasPool: Bool
    let hasGym: Bool
    let floorNumber: Int?
    let totalFloors: Int?
    let propertyType: String
}

// MARK: - Auction Status
enum AuctionStatus: String, CaseIterable, Codable {
    case upcoming = "upcoming"
    case active = "active"
    case ended = "ended"
    case sold = "sold"
    case cancelled = "cancelled"
    
    var displayText: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .active: return "Live Auction"
        case .ended: return "Auction Ended"
        case .sold: return "Sold"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: SwiftUI.Color {
        switch self {
        case .upcoming: return .orange
        case .active: return .green
        case .ended: return .gray
        case .sold: return .blue
        case .cancelled: return .red
        }
    }
    
    // Custom initializer to handle different status formats
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Try exact match first
        if let status = AuctionStatus(rawValue: rawValue) {
            self = status
            return
        }
        
        // Handle alternative values
        switch rawValue.lowercased() {
        case "live": self = .active
        case "running": self = .active
        case "finished": self = .ended
        case "completed": self = .ended
        case "closed": self = .ended
        case "pending": self = .upcoming
        case "waiting": self = .upcoming
        default: 
            print("⚠️ Unknown auction status: \(rawValue), defaulting to 'upcoming'")
            self = .upcoming
        }
    }
}

// MARK: - Property Category
enum PropertyCategory: String, CaseIterable, Codable {
    case residential = "Residential"
    case commercial = "Commercial"
    case land = "Land"
    case luxury = "Luxury"
    case investment = "Investment"
}

// MARK: - Bid Entry
struct BidEntry: Identifiable, Codable {
    let id: String
    let bidderId: String
    let bidderName: String
    let amount: Double
    let timestamp: Date
    let bidType: BidType
    
    init(id: String = UUID().uuidString, bidderId: String, bidderName: String, amount: Double, timestamp: Date = Date(), bidType: BidType = .regular) {
        self.id = id
        self.bidderId = bidderId
        self.bidderName = bidderName
        self.amount = amount
        self.timestamp = timestamp
        self.bidType = bidType
    }
    
    // Custom initializer to handle missing ID fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode id, if not present generate one
        if let decodedId = try? container.decode(String.self, forKey: .id) {
            self.id = decodedId
        } else {
            self.id = UUID().uuidString
        }
        
        self.bidderId = try container.decode(String.self, forKey: .bidderId)
        self.bidderName = try container.decode(String.self, forKey: .bidderName)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Try to decode bidType, default to regular if not present
        if let decodedBidType = try? container.decode(BidType.self, forKey: .bidType) {
            self.bidType = decodedBidType
        } else {
            self.bidType = .regular
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, bidderId, bidderName, amount, timestamp, bidType
    }
}

// MARK: - Bid Type
enum BidType: String, Codable {
    case regular = "regular"
    case autobid = "autobid"
    case buyNow = "buyNow"
}

// MARK: - Auction Duration
enum AuctionDuration: String, CaseIterable, Codable {
    case fiveMinutes = "5"
    case tenMinutes = "10"
    case fifteenMinutes = "15"
    case thirtyMinutes = "30"
    case oneHour = "60"
    case twoHours = "120"
    case threeHours = "180"
    case oneDay = "1440"
    case twoDays = "2880"
    case custom = "custom"
    
    var displayText: String {
        switch self {
        case .fiveMinutes: return "5 Minutes"
        case .tenMinutes: return "10 Minutes"
        case .fifteenMinutes: return "15 Minutes"
        case .thirtyMinutes: return "30 Minutes"
        case .oneHour: return "1 Hour"
        case .twoHours: return "2 Hours"
        case .threeHours: return "3 Hours"
        case .oneDay: return "1 Day"
        case .twoDays: return "2 Days"
        case .custom: return "Custom"
        }
    }
    
    var minutes: Int {
        return Int(self.rawValue) ?? 10
    }
    
    var timeInterval: TimeInterval {
        return TimeInterval(minutes * 60)
    }
    
    var seconds: Int {
        return minutes * 60
    }
    
    // Custom initializer to handle different formats
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Try to find exact match first
        if let duration = AuctionDuration(rawValue: rawValue) {
            self = duration
            return
        }
        
        // If no exact match, try to convert common values
        switch rawValue {
        case "2880": self = .twoDays
        case "live", "active": self = .oneHour // Default fallback
        default:
            // Try to parse as number and find closest match
            if let minutes = Int(rawValue) {
                switch minutes {
                case 0...7: self = .fiveMinutes
                case 8...12: self = .tenMinutes
                case 13...22: self = .fifteenMinutes
                case 23...45: self = .thirtyMinutes
                case 46...90: self = .oneHour
                case 91...150: self = .twoHours
                case 151...720: self = .threeHours
                case 721...2160: self = .oneDay
                case 2161...: self = .twoDays
                default: self = .oneHour
                }
            } else {
                self = .oneHour // Default fallback
            }
        }
    }
}

// MARK: - Mock Data Extensions
extension AuctionProperty {
    static func mockProperty() -> AuctionProperty {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let mockData: [String: Any] = [
            "sellerId": "seller-1",
            "sellerName": "John Doe",
            "title": "Beautiful Family Home",
            "description": "A lovely 3-bedroom house in a great neighborhood",
            "startingPrice": 500000.0,
            "currentBid": 550000.0,
            "highestBidderId": "bidder-1",
            "highestBidderName": "Jane Smith",
            "images": ["https://example.com/image1.jpg"],
            "videos": [],
            "address": [
                "street": "123 Main St",
                "city": "City",
                "state": "State",
                "postalCode": "12345",
                "country": "USA"
            ],
            "location": [
                "latitude": 37.7749,
                "longitude": -122.4194
            ],
            "features": [
                "bedrooms": 3,
                "bathrooms": 2,
                "area": 1500.0,
                "yearBuilt": 2020,
                "parkingSpaces": 2,
                "hasGarden": true,
                "hasPool": false,
                "hasGym": false,
                "propertyType": "House"
            ],
            "auctionStartTime": ISO8601DateFormatter().string(from: Date()),
            "auctionEndTime": ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)),
            "auctionDuration": "60",
            "status": "active",
            "category": "Residential",
            "bidHistory": [],
            "watchlistUsers": [],
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "updatedAt": ISO8601DateFormatter().string(from: Date()),
            "panoramicImages": []
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: mockData)
            return try decoder.decode(AuctionProperty.self, from: jsonData)
        } catch {
            print("Error creating mock property: \(error)")
            // Return a minimal property that will work
            fatalError("Could not create mock property")
        }
    }
}

// MARK: - User Bid Model
struct UserBid: Identifiable, Codable {
    let id: String
    let propertyId: String
    let propertyTitle: String
    let bidAmount: Double
    let bidTime: Date
    let status: BidStatus
    let isWinning: Bool
    
    enum BidStatus: String, Codable, CaseIterable {
        case active = "active"
        case outbid = "outbid"
        case won = "won"
        case lost = "lost"
        
        var displayText: String {
            switch self {
            case .active: return "Active"
            case .outbid: return "Outbid"
            case .won: return "Won"
            case .lost: return "Lost"
            }
        }
        
        var color: String {
            switch self {
            case .active: return "blue"
            case .outbid: return "orange"
            case .won: return "green"
            case .lost: return "red"
            }
        }
    }
    
    static var example: UserBid {
        UserBid(
            id: "bid1",
            propertyId: "prop1",
            propertyTitle: "Modern Villa with Ocean View",
            bidAmount: 450000,
            bidTime: Date(),
            status: .active,
            isWinning: true
        )
    }
}

// MARK: - Auction Chat Room Model
struct AuctionChatRoom: Identifiable, Codable {
    let id: String
    let propertyId: String
    let propertyTitle: String
    let participants: [String]
    let messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    let isActive: Bool
    
    struct ChatMessage: Identifiable, Codable {
        let id: String
        let senderId: String
        let senderName: String
        let message: String
        let timestamp: Date
        let messageType: MessageType
        
        enum MessageType: String, Codable {
            case text = "text"
            case bid = "bid"
            case system = "system"
        }
    }
    
    static var example: AuctionChatRoom {
        AuctionChatRoom(
            id: "chat1",
            propertyId: "prop1",
            propertyTitle: "Modern Villa with Ocean View",
            participants: ["user1", "user2", "user3"],
            messages: [
                ChatMessage(
                    id: "msg1",
                    senderId: "user1",
                    senderName: "John Doe",
                    message: "Great property!",
                    timestamp: Date(),
                    messageType: .text
                )
            ],
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        )
    }
}
