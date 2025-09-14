import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct CommunityChatView: View {
    @ObservedObject var communityService: CommunityService
    @StateObject private var mapService = MapService.shared
    @State private var showingNewChat = false
    @State private var showingMap = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), // Default to Colombo, Sri Lanka
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Community Chat")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingMap.toggle()
                        if showingMap {
                            setupLocationServices()
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.accentBlues)
                            .padding(8)
                            .background(Color.secondaryBackground)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        showingNewChat = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.accentBlues)
                            .padding(8)
                            .background(Color.secondaryBackground)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                if showingMap {
                    // Map view showing current location
                    UserLocationMapView(region: $region, mapService: mapService)
                        .frame(height: 300)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Chat list
                ChatListView(communityService: communityService)
            }
            .sheet(isPresented: $showingNewChat) {
                NewChatView(communityService: communityService)
            }
            .onAppear {
                Task {
                    await communityService.loadChatRooms()
                }
            }
            .animation(.easeInOut, value: showingMap)
        }
    }
    
    private func setupLocationServices() {
        // Request location permissions when the view appears
        mapService.requestLocationPermission()
        mapService.startLocationUpdates()
        
        // Update the region when current location changes
        if let currentLocation = mapService.currentLocation {
            updateRegionToCurrentLocation()
        } else {
            // Add observer for when location becomes available
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let currentLocation = mapService.currentLocation {
                    updateRegionToCurrentLocation()
                }
            }
        }
    }
    
    private func updateRegionToCurrentLocation() {
        if let currentLocation = mapService.currentLocation {
            withAnimation {
                region.center = currentLocation.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
        }
    }
}

// Custom map view that shows the user's current location
struct UserLocationMapView: View {
    @Binding var region: MKCoordinateRegion
    @ObservedObject var mapService: MapService
    @State private var locationButtonColor: Color = .accentBlues
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(coordinateRegion: $region, showsUserLocation: true, userTrackingMode: .none)
                .onChange(of: mapService.currentLocation) { oldValue, newValue in
                    if let location = newValue {
                        withAnimation {
                            region.center = location.coordinate
                        }
                    }
                }
            
            VStack(spacing: 10) {
                // Location button
                Button(action: {
                    centerOnUserLocation()
                    // Visual feedback
                    withAnimation(.easeInOut(duration: 0.3)) {
                        locationButtonColor = .green
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                locationButtonColor = .accentBlues
                            }
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(locationButtonColor)
                            .frame(width: 44, height: 44)
                            .shadow(radius: 2)
                        
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                    }
                }
                
                // Zoom in button
                Button(action: {
                    withAnimation {
                        region.span = MKCoordinateSpan(
                            latitudeDelta: max(region.span.latitudeDelta * 0.5, 0.001),
                            longitudeDelta: max(region.span.longitudeDelta * 0.5, 0.001)
                        )
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(radius: 2)
                        
                        Image(systemName: "plus")
                            .foregroundColor(.accentBlues)
                    }
                }
                
                // Zoom out button
                Button(action: {
                    withAnimation {
                        region.span = MKCoordinateSpan(
                            latitudeDelta: min(region.span.latitudeDelta * 2.0, 0.5),
                            longitudeDelta: min(region.span.longitudeDelta * 2.0, 0.5)
                        )
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(radius: 2)
                        
                        Image(systemName: "minus")
                            .foregroundColor(.accentBlues)
                    }
                }
            }
            .padding()
        }
    }
    
    private func centerOnUserLocation() {
        if mapService.authorizationStatus == .denied || mapService.authorizationStatus == .restricted {
            // Open settings
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        } else {
            mapService.requestLocationPermission()
            mapService.startLocationUpdates()
            
            // Use currentLocation if available, otherwise request updates
            if let currentLocation = mapService.currentLocation {
                withAnimation {
                    region.center = currentLocation.coordinate
                    region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                }
            }
        }
    }
}

#Preview {
    CommunityChatView(communityService: CommunityService())
}

#Preview {
    CommunityChatView(communityService: CommunityService())
}
