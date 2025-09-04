//
//  NearbyPlacesService.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-08-21.
//

import Foundation
import MapKit
import CoreLocation

class NearbyPlacesService: ObservableObject {
    static let shared = NearbyPlacesService()
    
    @Published var nearbyPlaces: [NearbyPlace] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let geocoder = CLGeocoder()
    
    private init() {}
    
    // MARK: - Fetch Nearby Places using MapKit Local Search
    func fetchNearbyPlaces(
        coordinate: CLLocationCoordinate2D,
        types: [PlaceType] = PlaceType.allCases,
        radius: CLLocationDistance = 5000 // 5km radius
    ) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        var allPlaces: [NearbyPlace] = []
        
        do {
            // Fetch places for each type
            for type in types {
                let places = try await searchPlaces(
                    for: type,
                    coordinate: coordinate,
                    radius: radius
                )
                allPlaces.append(contentsOf: places)
            }
            
            // Remove duplicates and sort by distance
            let uniquePlaces = removeDuplicates(from: allPlaces)
            let sortedPlaces = uniquePlaces.sorted { $0.distance < $1.distance }
            
            await MainActor.run {
                self.nearbyPlaces = sortedPlaces
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    private func searchPlaces(
        for type: PlaceType,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance
    ) async throws -> [NearbyPlace] {
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = getSearchQuery(for: type)
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius,
            longitudinalMeters: radius
        )
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        var nearbyPlaces: [NearbyPlace] = []
        for mapItem in response.mapItems {
            guard let name = mapItem.name else { continue }
            
            let itemCoordinate = mapItem.placemark.coordinate
            let distance = await MapService.shared.calculateDistance(from: coordinate, to: itemCoordinate) / 1000.0 // Convert to km
            
            // Map the place category to our PlaceType
            let placeType = mapPlaceTypeToOurType(mapItem.pointOfInterestCategory)
            
            let nearbyPlace = NearbyPlace(
                id: mapItem.identifier?.rawValue ?? UUID().uuidString,
                name: name,
                type: placeType,
                distance: distance.rounded(toDecimalPlaces: 2),
                coordinate: itemCoordinate
            )
            nearbyPlaces.append(nearbyPlace)
        }
        
        return nearbyPlaces
    }
    
    private func mapPlaceTypeToOurType(_ category: MKPointOfInterestCategory?) -> PlaceType {
        guard let category = category else { return .shopping }
        
        switch category {
        case .restaurant:
            return .restaurant
        case .school:
            return .school
        case .hospital:
            return .hospital
        case .park:
            return .park
        case .store:
            return .shopping
        case .bank:
            return .bank
        case .fitnessCenter:
            return .gym
        case .pharmacy:
            return .pharmacy
        case .gasStation:
            return .gasStation
        case .publicTransport:
            return .busStop
        default:
            return .shopping // Default fallback
        }
    }
    
    private func getSearchQuery(for type: PlaceType) -> String {
        switch type {
        case .restaurant:
            return "restaurant"
        case .school:
            return "school"
        case .hospital:
            return "hospital"
        case .park:
            return "park"
        case .shopping:
            return "shopping center mall"
        case .bank:
            return "bank"
        case .gym:
            return "gym fitness center"
        case .pharmacy:
            return "pharmacy"
        case .gasStation:
            return "gas station"
        case .busStop:
            return "bus stop transit"
        }
    }
    
    private func removeDuplicates(from places: [NearbyPlace]) -> [NearbyPlace] {
        var uniquePlaces: [NearbyPlace] = []
        var seenNames: Set<String> = []
        
        for place in places {
            let key = "\(place.name.lowercased())_\(place.type.rawValue)"
            if !seenNames.contains(key) {
                seenNames.insert(key)
                uniquePlaces.append(place)
            }
        }
        
        return uniquePlaces
    }
    
    // MARK: - Filter places by type
    func filterPlaces(by type: PlaceType) -> [NearbyPlace] {
        return nearbyPlaces.filter { $0.type == type }
            .sorted { $0.distance < $1.distance }
    }
    
    // MARK: - Get nearest places for each type
    func getNearestPlacesByType(limit: Int = 3) -> [PlaceType: [NearbyPlace]] {
        var placesByType: [PlaceType: [NearbyPlace]] = [:]
        
        for type in PlaceType.allCases {
            let typePlaces = nearbyPlaces.filter { $0.type == type }
                .sorted { $0.distance < $1.distance }
                .prefix(limit)
            
            placesByType[type] = Array(typePlaces)
        }
        
        return placesByType
    }
}

// MARK: - Error Handling
extension NearbyPlacesService {
    enum NearbyPlacesError: LocalizedError {
        case locationNotAvailable
        case searchFailed(String)
        case noPlacesFound
        
        var errorDescription: String? {
            switch self {
            case .locationNotAvailable:
                return "Location not available"
            case .searchFailed(let message):
                return "Search failed: \(message)"
            case .noPlacesFound:
                return "No nearby places found"
            }
        }
    }
}