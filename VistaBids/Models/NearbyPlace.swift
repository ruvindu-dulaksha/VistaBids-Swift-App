//
//  NearbyPlace.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-21.
//

import Foundation
import MapKit

// MARK: - Nearby Place Model
struct NearbyPlace: Identifiable {
    let id: String
    let name: String
    let type: PlaceType
    let distance: Double  // in kilometers
    let coordinate: CLLocationCoordinate2D
    
    var formattedDistance: String {
        if distance < 1.0 {
            return "\(Int(distance * 1000))m"
        } else {
            return "\(distance)km"
        }
    }
}

// MARK: - Place Type Enum
enum PlaceType: String, CaseIterable {
    case restaurant
    case school
    case hospital
    case park
    case shopping
    case bank
    case gym
    case pharmacy
    case gasStation = "gas_station"
    case busStop = "bus_stop"
    
    var name: String {
        switch self {
        case .restaurant: return "Restaurant"
        case .school: return "School"
        case .hospital: return "Hospital"
        case .park: return "Park"
        case .shopping: return "Shopping Center"
        case .bank: return "Bank"
        case .gym: return "Gym"
        case .pharmacy: return "Pharmacy"
        case .gasStation: return "Gas Station"
        case .busStop: return "Bus Stop"
        }
    }
    
    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .school: return "book"
        case .hospital: return "cross.circle"
        case .park: return "leaf"
        case .shopping: return "cart"
        case .bank: return "banknote"
        case .gym: return "figure.walk"
        case .pharmacy: return "pills"
        case .gasStation: return "fuelpump"
        case .busStop: return "bus"
        }
    }
    
    var color: String {
        switch self {
        case .restaurant: return "orange"
        case .school: return "blue"
        case .hospital: return "red"
        case .park: return "green"
        case .shopping: return "purple"
        case .bank: return "yellow"
        case .gym: return "pink"
        case .pharmacy: return "teal"
        case .gasStation: return "gray"
        case .busStop: return "indigo"
        }
    }
}

// MARK: - Double Extension for Rounding
extension Double {
    func rounded(toDecimalPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
