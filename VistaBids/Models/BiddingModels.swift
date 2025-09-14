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
    @DocumentID var id: String?
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
}

// MARK: - Mock Data Extensions
extension AuctionProperty {
    static func mockProperty() -> AuctionProperty {
        return AuctionProperty(
            id: nil,
            sellerId: "seller-1",
            sellerName: "John Doe",
            title: "Beautiful Family Home",
            description: "A lovely 3-bedroom house in a great neighborhood",
            startingPrice: 500000,
            currentBid: 550000,
            highestBidderId: "bidder-1",
            highestBidderName: "Jane Smith",
            images: ["https://example.com/image1.jpg"],
            videos: [],
            arModelURL: nil,
            address: PropertyAddress(
                street: "123 Main St",
                city: "City",
                state: "State",
                postalCode: "12345",
                country: "USA"
            ),
            location: GeoPoint(latitude: 37.7749, longitude: -122.4194),
            features: PropertyFeatures(
                bedrooms: 3,
                bathrooms: 2,
                area: 1500,
                yearBuilt: 2020,
                parkingSpaces: 2,
                hasGarden: true,
                hasPool: false,
                hasGym: false,
                floorNumber: nil,
                totalFloors: nil,
                propertyType: "House"
            ),
            auctionStartTime: Date(),
            auctionEndTime: Date().addingTimeInterval(3600),
            auctionDuration: AuctionDuration.oneHour,
            status: AuctionStatus.active,
            category: PropertyCategory.residential,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: Date(),
            updatedAt: Date(),
            winnerId: nil,
            winnerName: nil,
            finalPrice: nil,
            paymentStatus: PaymentStatus.pending,
            transactionId: nil,
            panoramicImages: [],
            walkthroughVideoURL: nil
        )
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
