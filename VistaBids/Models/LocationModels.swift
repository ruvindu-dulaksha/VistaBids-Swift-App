//
//  LocationModels.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha  on 2025-09-11.
//

import Foundation
import MapKit
import CoreLocation

// MARK: - Extended Place Categories
// This extends the existing PlaceType enum with additional categories for enhanced place search
enum ExtendedPlaceCategory: String, CaseIterable, Codable {
    case pharmacy = "pharmacy"
    case gasStation = "gas_station"
    case gym = "gym"
    case supermarket = "supermarket"
    case police = "police"
    case fireStation = "fire_station"
    case library = "library"
    case cinema = "cinema"
    case hotel = "hotel"
    case airport = "airport"
    case beach = "beach"
    case temple = "temple"
    case church = "church"
    case mosque = "mosque"
    
    var displayName: String {
        switch self {
        case .pharmacy: return "Pharmacies"
        case .gasStation: return "Gas Stations"
        case .gym: return "Gyms"
        case .supermarket: return "Supermarkets"
        case .police: return "Police Stations"
        case .fireStation: return "Fire Stations"
        case .library: return "Libraries"
        case .cinema: return "Cinemas"
        case .hotel: return "Hotels"
        case .airport: return "Airports"
        case .beach: return "Beaches"
        case .temple: return "Temples"
        case .church: return "Churches"
        case .mosque: return "Mosques"
        }
    }
    
    var icon: String {
        switch self {
        case .pharmacy: return "plus.circle.fill"
        case .gasStation: return "fuelpump.fill"
        case .gym: return "dumbbell.fill"
        case .supermarket: return "cart.fill"
        case .police: return "shield.fill"
        case .fireStation: return "flame.fill"
        case .library: return "books.vertical.fill"
        case .cinema: return "tv.fill"
        case .hotel: return "bed.double.fill"
        case .airport: return "airplane"
        case .beach: return "water.waves"
        case .temple: return "moon.stars.fill"
        case .church: return "cross.case.fill"
        case .mosque: return "moon.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pharmacy: return "green"
        case .gasStation: return "gray"
        case .gym: return "red"
        case .supermarket: return "orange"
        case .police: return "blue"
        case .fireStation: return "red"
        case .library: return "brown"
        case .cinema: return "purple"
        case .hotel: return "pink"
        case .airport: return "blue"
        case .beach: return "blue"
        case .temple: return "yellow"
        case .church: return "brown"
        case .mosque: return "green"
        }
    }
}