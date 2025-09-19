//
//  BiddingServiceTests.swift
//  VistaBidsTests
//
//  Created by Ruvindu Dulaksha on 2025-09-19.
//

import Testing
import Foundation
import FirebaseFirestore
@testable import VistaBids

struct BiddingServiceTests {

    @Test func testBidInitialization() {
        // Given
        let bid = Bid(
            id: "bid-123",
            propertyId: "property-456",
            userId: "user-789",
            amount: 150000.0,
            timestamp: Date()
        )

        // Then
        #expect(bid.id == "bid-123")
        #expect(bid.propertyId == "property-456")
        #expect(bid.userId == "user-789")
        #expect(bid.amount == 150000.0)
        #expect(bid.formattedAmount == "US$150,000.00")
    }

    @Test func testBidEntryInitialization() {
        // Given
        let bidEntry = BidEntry(
            id: "entry-123",
            bidderId: "user-456",
            bidderName: "Test User",
            amount: 200000.0,
            timestamp: Date(),
            bidType: .regular
        )

        // Then
        #expect(bidEntry.id == "entry-123")
        #expect(bidEntry.bidderId == "user-456")
        #expect(bidEntry.bidderName == "Test User")
        #expect(bidEntry.amount == 200000.0)
        #expect(bidEntry.bidType == .regular)
    }

    @Test func testUserBidInitialization() {
        // Given
        let userBid = UserBid(
            id: "user-bid-123",
            propertyId: "property-456",
            propertyTitle: "Test Property",
            bidAmount: 150000.0,
            bidTime: Date(),
            status: .active,
            isWinning: true
        )

        // Then
        #expect(userBid.id == "user-bid-123")
        #expect(userBid.propertyId == "property-456")
        #expect(userBid.propertyTitle == "Test Property")
        #expect(userBid.bidAmount == 150000.0)
        #expect(userBid.status == .active)
        #expect(userBid.isWinning == true)
    }

    @Test func testUserBidStatusDisplayName() {
        // Given
        let activeBid = UserBid(
            id: "1",
            propertyId: "prop1",
            propertyTitle: "Property 1",
            bidAmount: 100000,
            bidTime: Date(),
            status: .active,
            isWinning: true
        )

        let wonBid = UserBid(
            id: "2",
            propertyId: "prop1",
            propertyTitle: "Property 1",
            bidAmount: 120000,
            bidTime: Date(),
            status: .won,
            isWinning: true
        )

        let lostBid = UserBid(
            id: "3",
            propertyId: "prop1",
            propertyTitle: "Property 1",
            bidAmount: 90000,
            bidTime: Date(),
            status: .lost,
            isWinning: false
        )

        // Then
        #expect(activeBid.status.displayText == "Active")
        #expect(wonBid.status.displayText == "Won")
        #expect(lostBid.status.displayText == "Lost")
    }

    @Test func testBidAmountValidation() {
        // Given
        let validBid = Bid(
            id: "1",
            propertyId: "prop1",
            userId: "user1",
            amount: 100000,
            timestamp: Date()
        )

        let zeroBid = Bid(
            id: "2",
            propertyId: "prop1",
            userId: "user1",
            amount: 0,
            timestamp: Date()
        )

        let negativeBid = Bid(
            id: "3",
            propertyId: "prop1",
            userId: "user1",
            amount: -50000,
            timestamp: Date()
        )

        // Then
        #expect(validBid.amount > 0)
        #expect(zeroBid.amount == 0) // Invalid but model allows it
        #expect(negativeBid.amount < 0) // Invalid but model allows it
    }

    @Test func testAuctionPropertyStatusDisplayName() {
        // Given
        let activeProperty = AuctionProperty(
            sellerId: "seller1",
            sellerName: "Test Seller",
            title: "Active Property",
            description: "Test description",
            startingPrice: 100000,
            currentBid: 120000,
            images: [],
            videos: [],
            address: PropertyAddress(
                street: "123 Test St",
                city: "Test City",
                state: "Test State",
                postalCode: "12345",
                country: "Test Country"
            ),
            location: GeoPoint(latitude: 0, longitude: 0),
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
            auctionStartTime: Date().addingTimeInterval(-3600),
            auctionEndTime: Date().addingTimeInterval(3600),
            auctionDuration: .oneHour,
            status: .active,
            category: .residential,
            createdAt: Date(),
            updatedAt: Date()
        )

        let endedProperty = AuctionProperty(
            sellerId: "seller2",
            sellerName: "Test Seller 2",
            title: "Ended Property",
            description: "Test description 2",
            startingPrice: 200000,
            currentBid: 250000,
            images: [],
            videos: [],
            address: PropertyAddress(
                street: "456 Test St",
                city: "Test City 2",
                state: "Test State 2",
                postalCode: "67890",
                country: "Test Country 2"
            ),
            location: GeoPoint(latitude: 0, longitude: 0),
            features: PropertyFeatures(
                bedrooms: 4,
                bathrooms: 3,
                area: 2000,
                yearBuilt: 2021,
                parkingSpaces: 3,
                hasGarden: false,
                hasPool: true,
                hasGym: false,
                floorNumber: nil,
                totalFloors: nil,
                propertyType: "Villa"
            ),
            auctionStartTime: Date().addingTimeInterval(-7200),
            auctionEndTime: Date().addingTimeInterval(-3600),
            auctionDuration: .twoHours,
            status: .ended,
            category: .luxury,
            createdAt: Date().addingTimeInterval(-7200),
            updatedAt: Date().addingTimeInterval(-3600)
        )

        // Then
        #expect(activeProperty.status.displayText == "Live Auction")
        #expect(endedProperty.status.displayText == "Auction Ended")
    }

    @Test func testBidTypeEnum() {
        // Given
        let regularBid = BidType.regular
        let autoBid = BidType.autobid
        let buyNowBid = BidType.buyNow

        // Then
        #expect(regularBid.rawValue == "regular")
        #expect(autoBid.rawValue == "autobid")
        #expect(buyNowBid.rawValue == "buyNow")
    }

    @Test func testAuctionDurationTimeInterval() {
        // Given
        let oneHour = AuctionDuration.oneHour
        let oneDay = AuctionDuration.oneDay

        // Then
        #expect(oneHour.timeInterval == 3600) // 1 hour in seconds
        #expect(oneDay.timeInterval == 86400) // 24 hours in seconds
    }

}