//
//  EnhancedUserActivityView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-09-12.
//

import SwiftUI

struct EnhancedUserActivityView: View {
    @StateObject private var profileService = UserProfileService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Activity Type", selection: $selectedTab) {
                Text("Purchases").tag(0)
                Text("Activities").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content based on selected tab
            TabView(selection: $selectedTab) {
                // Purchase History Tab
                PurchaseHistoryView(purchases: profileService.purchaseHistory)
                    .tag(0)
                
                // Activities Tab
                ActivitiesView(activities: profileService.activities)
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("Your Activity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await profileService.loadUserProfile()
            }
        }
        .overlay(
            Group {
                if profileService.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        )
    }
}

struct PurchaseHistoryView: View {
    let purchases: [UserPurchaseHistory]
    
    var body: some View {
        List {
            if purchases.isEmpty {
                EmptyStateView(
                    icon: "house.fill",
                    title: "No Purchases Yet",
                    subtitle: "Your purchased properties will appear here"
                )
            } else {
                ForEach(purchases) { purchase in
                    PurchaseRowView(purchase: purchase)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct ActivitiesView: View {
    let activities: [UserActivity]
    
    var body: some View {
        List {
            if activities.isEmpty {
                EmptyStateView(
                    icon: "clock.fill",
                    title: "No Activities Yet",
                    subtitle: "Your activities will appear here"
                )
            } else {
                ForEach(activities) { activity in
                    ActivityRowView(activity: activity)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct PurchaseRowView: View {
    let purchase: UserPurchaseHistory
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                AsyncImage(url: URL(string: purchase.propertyImages.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(purchase.propertyTitle)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(purchase.propertyAddress.fullAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        Text("$\(Int(purchase.purchasePrice))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text(purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    ActivityPaymentStatusBadge(status: purchase.paymentStatus)
                    DeliveryStatusBadge(status: purchase.deliveryStatus)
                }
            }
            
            // Property details
            HStack {
                PropertyDetailItem(icon: "bed.double.fill", value: "\(purchase.propertyFeatures.bedrooms)")
                PropertyDetailItem(icon: "bathtub.fill", value: "\(purchase.propertyFeatures.bathrooms)")
                PropertyDetailItem(icon: "square.fill", value: "\(Int(purchase.propertyFeatures.area)) sqft")
                
                Spacer()
                
                Text("ID: \(purchase.transactionId)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ActivityRowView: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .foregroundColor(Color(activity.color))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(activity.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let amount = activity.amount {
                        Text("• $\(Int(amount))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            ActivityStatusBadge(status: activity.status)
        }
        .padding(.vertical, 4)
    }
}

struct ActivityPaymentStatusBadge: View {
    let status: PaymentStatus
    
    var body: some View {
        Text(status.displayText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(4)
    }
}

struct DeliveryStatusBadge: View {
    let status: DeliveryStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }
}

struct ActivityStatusBadge: View {
    let status: UserActivity.ActivityStatus
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
}

struct PropertyDetailItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    NavigationView {
        EnhancedUserActivityView()
    }
}
