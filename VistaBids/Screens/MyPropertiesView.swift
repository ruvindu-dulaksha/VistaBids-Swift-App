//
//  MyPropertiesView.swift
//  VistaBids
//
//  Created by Assistant on 2025-08-21.
//

import SwiftUI

struct MyPropertiesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userStatsService: UserStatsService
    @State private var selectedTab = 0
    @State private var showingAddProperty = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Property Type", selection: $selectedTab) {
                    Text("All").tag(0)
                    Text("For Sale").tag(1)
                    Text("Sold").tag(2)
                    Text("Draft").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Properties List
                if userStatsService.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading your properties...")
                        Spacer()
                    }
                } else if userStatsService.myProperties.isEmpty {
                    PropertyEmptyStateView(
                        icon: "house.fill",
                        title: "No Properties Yet",
                        message: "Start your property business by listing your first property",
                        buttonTitle: "Add Property",
                        buttonAction: {
                            showingAddProperty = true
                        }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredProperties) { property in
                                PropertyCard(property: property)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("My Properties")
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
                        showingAddProperty = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddProperty) {
                AddPropertyFormView()
            }
            .onAppear {
                userStatsService.loadUserStats()
            }
        }
    }
    
    private var filteredProperties: [SaleProperty] {
        switch selectedTab {
        case 1: // For Sale
            return userStatsService.myProperties.filter { $0.status == .active }
        case 2: // Sold
            return userStatsService.myProperties.filter { $0.status == .sold }
        case 3: // Draft
            return userStatsService.myProperties.filter { $0.status == .draft }
        default: // All
            return userStatsService.myProperties
        }
    }
}

struct PropertyCard: View {
    let property: SaleProperty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
            .frame(height: 180)
            .cornerRadius(12)
            .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                // Status Badge
                HStack {
                    StatusBadge(status: property.status)
                    Spacer()
                    Text("$\(Int(property.price))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentBlues)
                }
                
                // Property Title
                Text(property.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                // Location
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(property.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Property Details
                HStack(spacing: 16) {
                    DetailItem(icon: "bed.double.fill", value: "\(property.bedrooms)")
                    DetailItem(icon: "shower.fill", value: "\(property.bathrooms)")
                    DetailItem(icon: "square.fill", value: "\(Int(property.area)) sqft")
                }
                
                // Created Date
                Text("Listed \(formatDate(property.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StatusBadge: View {
    let status: SalePropertyStatus
    
    var body: some View {
        Text(status.displayText)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .active:
            return .green
        case .sold:
            return .blue
        case .draft:
            return .orange
        case .withdrawn:
            return .gray
        case .underOffer:
            return .yellow
        }
    }
}

struct DetailItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AddPropertyFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Property Form")
                    .font(.title)
                    .padding()
                
                Text("This would be the add property form")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Implement save logic
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct PropertyEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String
    let buttonAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: buttonAction) {
                Text(buttonTitle)
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
    MyPropertiesView()
        .environmentObject(UserStatsService.shared)
}
