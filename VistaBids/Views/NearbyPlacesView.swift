//
//  NearbyPlacesView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-08-21.
//

import SwiftUI
import MapKit

struct NearbyPlacesView: View {
    let places: [NearbyPlace]
    let propertyCoordinate: CLLocationCoordinate2D
    @Binding var selectedType: PlaceType
    
    private var filteredPlaces: [NearbyPlace] {
        if selectedType == .restaurant {
            // If restaurant is selected, return all places sorted by distance
            return places.sorted(by: { $0.distance < $1.distance })
        } else {
            // Otherwise filter by the selected type
            return places.filter { $0.type == selectedType }
                .sorted(by: { $0.distance < $1.distance })
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nearby Places")
                .font(.headline)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 16)
            
            // Place type selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PlaceType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.name)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedType == type ? Color.accentBlues : Color.secondaryBackground)
                            .foregroundColor(selectedType == type ? .white : .textPrimary)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // Map with places
            ZStack {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: propertyCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: filteredPlaces) { place in
                    MapMarker(coordinate: place.coordinate, tint: Color(place.type.color))
                }
                .frame(height: 150)
                .cornerRadius(12)
                .disabled(true)
                
                // Property marker
                VStack(spacing: 0) {
                    Image(systemName: "house.fill")
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.accentBlues)
                        .clipShape(Circle())
                }
                .shadow(radius: 2)
            }
            .padding(.horizontal, 16)
            
            // List of places
            VStack(spacing: 8) {
                ForEach(filteredPlaces) { place in
                    HStack {
                        Image(systemName: place.type.icon)
                            .foregroundColor(Color(place.type.color))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(place.name)
                                .font(.subheadline)
                                .foregroundColor(.textPrimary)
                            
                            Text(place.type.name)
                                .font(.caption)
                                .foregroundColor(.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Text(place.formattedDistance)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentBlues)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackground)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cardBackground)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

#Preview {
    let places = [
        NearbyPlace(
            id: "1", 
            name: "Good Restaurant", 
            type: .restaurant, 
            distance: 0.3, 
            coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
        ),
        NearbyPlace(
            id: "2", 
            name: "City Hospital", 
            type: .hospital, 
            distance: 1.2, 
            coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
        ),
        NearbyPlace(
            id: "3", 
            name: "Central School", 
            type: .school, 
            distance: 0.8, 
            coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
        )
    ]
    
    return NearbyPlacesView(
        places: places,
        propertyCoordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        selectedType: .constant(.restaurant)
    )
}
