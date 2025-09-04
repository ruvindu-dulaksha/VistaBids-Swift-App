//
//  SearchInsightView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-08-21.
//

import SwiftUI

struct SearchInsightView: View {
    let properties: [SaleProperty]
    
    private var averagePrice: Double {
        guard !properties.isEmpty else { return 0 }
        let sum = properties.reduce(0.0) { $0 + $1.price }
        return sum / Double(properties.count)
    }
    
    private var lowestPrice: Double {
        properties.min(by: { $0.price < $1.price })?.price ?? 0.0
    }
    
    private var highestPrice: Double {
        properties.max(by: { $0.price < $1.price })?.price ?? 0.0
    }
    
    private var mostCommonType: String {
        let types = properties.map { $0.propertyType.displayName }
        let counts = Dictionary(grouping: types, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    private var activeListings: Int {
        properties.filter { $0.status == .active }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Insights")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 16) {
                InsightItemView(
                    title: "Average Price",
                    value: "$\(Int(averagePrice).formatted())",
                    icon: "dollarsign.circle.fill",
                    color: .blue
                )
                
                InsightItemView(
                    title: "Active Listings",
                    value: "\(activeListings)",
                    icon: "house.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                InsightItemView(
                    title: "Price Range",
                    value: "$\(Int(lowestPrice).formatted()) - $\(Int(highestPrice).formatted())",
                    icon: "chart.bar.fill",
                    color: .orange
                )
                
                InsightItemView(
                    title: "Popular Type",
                    value: mostCommonType,
                    icon: "building.2.fill",
                    color: .purple
                )
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}

struct InsightItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondaryTextColor)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

#Preview {
    let properties = [
        SaleProperty.example,
        SaleProperty.example,
        SaleProperty.example
    ]
    
    return SearchInsightView(properties: properties)
        .padding()
}
