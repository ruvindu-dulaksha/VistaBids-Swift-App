//
//  FavoritesView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-21.
//

import SwiftUI

struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userStatsService: UserStatsService
    @State private var selectedFilter = "All"
    
    private let filters = ["All", "Houses", "Apartments", "Commercial", "Land"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FavoriteFilterChip(
                                title: filter,
                                isSelected: selectedFilter == filter,
                                action: {
                                    selectedFilter = filter
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                
                // Favorites List
                if userStatsService.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading your favorites...")
                        Spacer()
                    }
                } else if userStatsService.favoriteProperties.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredFavorites) { property in
                                FavoritePropertyCard(
                                    property: property,
                                    onRemove: {
                                        Task {
                                            await userStatsService.removeFromFavorites(propertyId: property.id)
                                        }
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        userStatsService.loadUserStats()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                    }
                }
            }
            .onAppear {
                userStatsService.loadUserStats()
            }
        }
    }
    
    private var filteredFavorites: [SaleProperty] {
        if selectedFilter == "All" {
            return userStatsService.favoriteProperties
        }
        return userStatsService.favoriteProperties.filter { property in
            property.propertyType.displayName.lowercased().contains(selectedFilter.lowercased())
        }
    }
}

struct FavoriteFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .accentBlues)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.accentBlues : Color.clear)
                        .stroke(Color.accentBlues, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FavoritePropertyCard: View {
    let property: SaleProperty
    let onRemove: () -> Void
    @State private var showingRemoveAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Property Image
            AsyncImage(url: URL(string: property.images.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "house.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 80, height: 80)
            .cornerRadius(12)
            .clipped()
            
            // Property Details
            VStack(alignment: .leading, spacing: 4) {
                Text(property.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(property.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text("$\(Int(property.price))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentBlues)
                    
                    Spacer()
                    
                    Text(property.propertyType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentBlues.opacity(0.1))
                        .foregroundColor(.accentBlues)
                        .cornerRadius(4)
                }
                
                HStack(spacing: 12) {
                    PropertyFeatureBadge(icon: "bed.double.fill", value: "\(property.bedrooms)")
                    PropertyFeatureBadge(icon: "shower.fill", value: "\(property.bathrooms)")
                    PropertyFeatureBadge(icon: "square.fill", value: "\(Int(property.area)) sqft")
                }
            }
            
            Spacer()
            
            // Remove Button
            Button(action: {
                showingRemoveAlert = true
            }) {
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .alert("Remove from Favorites", isPresented: $showingRemoveAlert) {
            Button("Remove", role: .destructive) {
                onRemove()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove this property from your favorites?")
        }
    }
}

struct PropertyFeatureBadge: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Favorites Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start exploring properties and add them to your favorites by tapping the heart icon")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                // Navigate to property search/home
            }) {
                Text("Explore Properties")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.accentBlues)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgrounds)
    }
}

#Preview {
    FavoritesView()
        .environmentObject(UserStatsService.shared)
}
