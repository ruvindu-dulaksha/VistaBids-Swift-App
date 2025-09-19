//
//  PropertyModelTests.swift
//  VistaBidsTests
//
//  Created by Ruvindu Dulaksha on 2025-09-19.
//

import Testing
import Foundation
@testable import VistaBids

struct PropertyModelTests {

    @Test func testPropertyInitialization() {
        // Given
        let property = Property(
            id: "prop-123",
            title: "Test Property",
            description: "A test property description",
            price: 250000.0,
            bedrooms: 3,
            bathrooms: 2,
            area: "1500 sq ft",
            propertyType: .house,
            address: PropertyAddressOld(
                street: "123 Test St",
                city: "Test City",
                state: "Test State",
                zipCode: "12345",
                country: "Test Country"
            ),
            coordinates: PropertyCoordinates(latitude: 6.9271, longitude: 79.8612),
            images: ["https://example.com/image1.jpg"],
            panoramicImages: [],
            walkthroughVideoURL: nil,
            features: [
                PropertyFeature(id: "1", name: "Swimming Pool", icon: "figure.pool.swim", category: .exterior)
            ],
            seller: PropertySeller(
                id: "seller1",
                name: "Test Seller",
                email: "seller@example.com",
                phone: "+1234567890",
                profileImageURL: nil,
                rating: 4.5,
                reviewCount: 10,
                verificationStatus: .verified
            ),
            createdAt: Date(),
            updatedAt: Date(),
            isForAuction: false,
            isForSale: true
        )

        // Then
        #expect(property.id == "prop-123")
        #expect(property.title == "Test Property")
        #expect(property.price == 250000.0)
        #expect(property.bedrooms == 3)
        #expect(property.bathrooms == 2)
        #expect(property.propertyType == .house)
        #expect(property.isForAuction == false)
        #expect(property.isForSale == true)
    }

    @Test func testPropertyEncoding() throws {
        // Given
        let property = Property(
            id: "prop-123",
            title: "Test Property",
            description: "A test property description",
            price: 250000.0,
            bedrooms: 3,
            bathrooms: 2,
            area: "1500 sq ft",
            propertyType: .house,
            address: PropertyAddressOld(
                street: "123 Test St",
                city: "Test City",
                state: "Test State",
                zipCode: "12345",
                country: "Test Country"
            ),
            coordinates: PropertyCoordinates(latitude: 6.9271, longitude: 79.8612),
            images: ["https://example.com/image1.jpg"],
            panoramicImages: [],
            walkthroughVideoURL: nil,
            features: [],
            seller: PropertySeller(
                id: "seller1",
                name: "Test Seller",
                email: "seller@example.com",
                phone: "+1234567890",
                profileImageURL: nil,
                rating: 4.5,
                reviewCount: 10,
                verificationStatus: .verified
            ),
            createdAt: Date(),
            updatedAt: Date(),
            isForAuction: false,
            isForSale: true
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(property)
        let decoder = JSONDecoder()
        let decodedProperty = try decoder.decode(Property.self, from: data)

        // Then
        #expect(decodedProperty.id == property.id)
        #expect(decodedProperty.title == property.title)
        #expect(decodedProperty.price == property.price)
        #expect(decodedProperty.bedrooms == property.bedrooms)
    }

    @Test func testPropertyTypeDisplayName() {
        // Given
        let houseProperty = Property(
            id: "1",
            title: "House",
            description: "House description",
            price: 200000,
            bedrooms: 3,
            bathrooms: 2,
            area: "1500 sq ft",
            propertyType: .house,
            address: PropertyAddressOld(
                street: "123 St",
                city: "City",
                state: "State",
                zipCode: "12345",
                country: "Country"
            ),
            coordinates: PropertyCoordinates(latitude: 0, longitude: 0),
            images: [],
            panoramicImages: [],
            walkthroughVideoURL: nil,
            features: [],
            seller: PropertySeller(
                id: "seller1",
                name: "Seller",
                email: "seller@example.com",
                phone: "+1234567890",
                profileImageURL: nil,
                rating: 4.5,
                reviewCount: 10,
                verificationStatus: .verified
            ),
            createdAt: Date(),
            updatedAt: Date(),
            isForAuction: false,
            isForSale: true
        )

        let apartmentProperty = Property(
            id: "2",
            title: "Apartment",
            description: "Apartment description",
            price: 150000,
            bedrooms: 2,
            bathrooms: 1,
            area: "800 sq ft",
            propertyType: .apartment,
            address: PropertyAddressOld(
                street: "456 St",
                city: "City",
                state: "State",
                zipCode: "12345",
                country: "Country"
            ),
            coordinates: PropertyCoordinates(latitude: 0, longitude: 0),
            images: [],
            panoramicImages: [],
            walkthroughVideoURL: nil,
            features: [],
            seller: PropertySeller(
                id: "seller1",
                name: "Seller",
                email: "seller@example.com",
                phone: "+1234567890",
                profileImageURL: nil,
                rating: 4.5,
                reviewCount: 10,
                verificationStatus: .verified
            ),
            createdAt: Date(),
            updatedAt: Date(),
            isForAuction: false,
            isForSale: true
        )

        // Then
        #expect(houseProperty.propertyType.displayName == "House")
        #expect(apartmentProperty.propertyType.displayName == "Apartment")
    }

    @Test func testPropertyComputedProperties() {
        // Given
        let property = Property(
            id: "prop-123",
            title: "Test Property",
            description: "Description",
            price: 250000.0,
            bedrooms: 3,
            bathrooms: 2,
            area: "1500 sq ft",
            propertyType: .house,
            address: PropertyAddressOld(
                street: "123 Test St",
                city: "Test City",
                state: "Test State",
                zipCode: "12345",
                country: "Test Country"
            ),
            coordinates: PropertyCoordinates(latitude: 6.9271, longitude: 79.8612),
            images: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
            panoramicImages: [],
            walkthroughVideoURL: "https://example.com/video.mp4",
            features: [],
            seller: PropertySeller(
                id: "seller1",
                name: "Test Seller",
                email: "seller@example.com",
                phone: "+1234567890",
                profileImageURL: nil,
                rating: 4.5,
                reviewCount: 10,
                verificationStatus: .verified
            ),
            createdAt: Date(),
            updatedAt: Date(),
            isForAuction: false,
            isForSale: true
        )

        // Then
        #expect(property.formattedPrice == "$250,000")
        #expect(property.primaryImage == "https://example.com/image1.jpg")
        #expect(property.location == "Test City, Test State")
        #expect(property.hasWalkthroughVideo == true)
        #expect(property.hasPanoramicImages == false)
        #expect(property.hasARContent == false)
    }

    @Test func testSalePropertyInitialization() {
        // Given
        let saleProperty = SaleProperty(
            id: "sale-123",
            title: "Sale Property",
            description: "For sale property",
            price: 300000.0,
            bedrooms: 4,
            bathrooms: 3,
            area: "2000 sq ft",
            propertyType: .house,
            address: PropertyAddressOld(
                street: "789 Sale St",
                city: "Sale City",
                state: "Sale State",
                zipCode: "67890",
                country: "Sale Country"
            ),
            coordinates: PropertyCoordinates(latitude: 7.0, longitude: 80.0),
            images: ["https://example.com/sale1.jpg"],
            panoramicImages: [],
            walkthroughVideoURL: nil,
            features: [
                PropertyFeature(id: "1", name: "Garden", icon: "leaf", category: .exterior)
            ],
            seller: PropertySeller(
                id: "seller2",
                name: "Sale Seller",
                email: "sale@example.com",
                phone: "+0987654321",
                profileImageURL: nil,
                rating: 4.8,
                reviewCount: 15,
                verificationStatus: .verified
            ),
            availableFrom: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            status: .active,
            isNew: true
        )

        // Then
        #expect(saleProperty.id == "sale-123")
        #expect(saleProperty.title == "Sale Property")
        #expect(saleProperty.price == 300000.0)
        #expect(saleProperty.status == .active)
        #expect(saleProperty.isNew == true)
    }

    @Test func testSalePropertyStatusDisplayName() {
        // Given
        let activeProperty = SaleProperty(
            id: "1",
            title: "Active Property",
            description: "Active",
            price: 200000,
            bedrooms: 3,
            bathrooms: 2,
            area: "1500 sq ft",
            propertyType: .house,
            address: PropertyAddressOld(
                street: "123 St",
                city: "City",
                state: "State",
                zipCode: "12345",
                country: "Country"
            ),
            coordinates: PropertyCoordinates(latitude: 0, longitude: 0),
            images: [],
            panoramicImages: [],
            walkthroughVideoURL: nil,
            features: [],
            seller: PropertySeller(
                id: "seller1",
                name: "Seller",
                email: "seller@example.com",
                phone: "+1234567890",
                profileImageURL: nil,
                rating: 4.5,
                reviewCount: 10,
                verificationStatus: .verified
            ),
            availableFrom: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            status: .active,
            isNew: false
        )

        let soldProperty = SaleProperty(
            id: "2",
            title: "Sold Property",
            description: "Sold",
            price: 250000,
            bedrooms: 3,
            bathrooms: 2,
            area: "1500 sq ft",
            propertyType: .house,
            address: PropertyAddressOld(
                street: "456 St",
                city: "City",
                state: "State",
                zipCode: "12345",
                country: "Country"
            ),
            coordinates: PropertyCoordinates(latitude: 0, longitude: 0),
            images: [],
            panoramicImages: [],
            walkthroughVideoURL: nil,
            features: [],
            seller: PropertySeller(
                id: "seller1",
                name: "Seller",
                email: "seller@example.com",
                phone: "+1234567890",
                profileImageURL: nil,
                rating: 4.5,
                reviewCount: 10,
                verificationStatus: .verified
            ),
            availableFrom: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            status: .sold,
            isNew: false
        )

        // Then
        #expect(activeProperty.status.displayText == "For Sale")
        #expect(soldProperty.status.displayText == "Sold")
    }

    @Test func testPropertyCoordinates() {
        // Given
        let coordinates = PropertyCoordinates(latitude: 6.9271, longitude: 79.8612)

        // Then
        #expect(coordinates.latitude == 6.9271)
        #expect(coordinates.longitude == 79.8612)
    }

    @Test func testPropertyAddress() {
        // Given
        let address = PropertyAddressOld(
            street: "123 Main St",
            city: "Colombo",
            state: "Western Province",
            zipCode: "00300",
            country: "Sri Lanka"
        )

        // Then
        #expect(address.street == "123 Main St")
        #expect(address.city == "Colombo")
        #expect(address.fullAddress == "123 Main St, Colombo, Western Province 00300, Sri Lanka")
    }

    @Test func testPropertySeller() {
        // Given
        let seller = PropertySeller(
            id: "seller1",
            name: "John Doe",
            email: "john@example.com",
            phone: "+94771234567",
            profileImageURL: "avatar1",
            rating: 4.8,
            reviewCount: 12,
            verificationStatus: .verified
        )

        // Then
        #expect(seller.id == "seller1")
        #expect(seller.name == "John Doe")
        #expect(seller.rating == 4.8)
        #expect(seller.verificationStatus == .verified)
    }

    @Test func testPropertyFeature() {
        // Given
        let feature = PropertyFeature(
            id: "1",
            name: "Swimming Pool",
            icon: "figure.pool.swim",
            category: .exterior
        )

        // Then
        #expect(feature.id == "1")
        #expect(feature.name == "Swimming Pool")
        #expect(feature.category == .exterior)
    }

    @Test func testPropertyFeatureCategoryDisplayName() {
        // Given
        let interiorFeature = PropertyFeature(id: "1", name: "Fireplace", icon: "flame", category: .interior)
        let exteriorFeature = PropertyFeature(id: "2", name: "Garden", icon: "leaf", category: .exterior)

        // Then
        #expect(interiorFeature.category.displayName == "Interior")
        #expect(exteriorFeature.category.displayName == "Exterior")
    }

}