//
//  PanoramicImage.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2023-10-15.
//

import Foundation

// MARK: - Panoramic Image
struct PanoramicImage: Identifiable, Codable {
    let id: String
    let imageURL: String
    let title: String
    let description: String?
    let roomType: RoomType
    let captureDate: Date
    let isAREnabled: Bool
    
    enum RoomType: String, Codable, CaseIterable {
        case livingRoom = "living_room"
        case bedroom = "bedroom"
        case kitchen = "kitchen"
        case bathroom = "bathroom"
        case exterior = "exterior"
        case garage = "garage"
        case balcony = "balcony"
        case garden = "garden"
        case outdoor = "outdoor"
        
        var displayName: String {
            switch self {
            case .livingRoom: return "Living Room"
            case .bedroom: return "Bedroom"
            case .kitchen: return "Kitchen"
            case .bathroom: return "Bathroom"
            case .exterior: return "Exterior"
            case .garage: return "Garage"
            case .balcony: return "Balcony"
            case .garden: return "Garden"
            case .outdoor: return "Outdoor"
            }
        }
        
        var icon: String {
            switch self {
            case .livingRoom: return "sofa.fill"
            case .bedroom: return "bed.double.fill"
            case .kitchen: return "cooktop.fill"
            case .bathroom: return "bathtub.fill"
            case .exterior: return "house.fill"
            case .garage: return "car.fill"
            case .balcony: return "building.2"
            case .garden: return "leaf.fill"
            case .outdoor: return "mountain.2.fill"
            }
        }
    }
}
