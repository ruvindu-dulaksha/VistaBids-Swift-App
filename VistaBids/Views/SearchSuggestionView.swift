//
//  SearchSuggestionView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-23.
//

import SwiftUI

struct SearchSuggestionView: View {
    let suggestions: [String]
    let onSuggestionSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !suggestions.isEmpty {
                Text("Suggestions")
                    .font(.caption)
                    .foregroundColor(.secondaryTextColor)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        onSuggestionSelected(suggestion)
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondaryTextColor)
                            Text(suggestion)
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .background(Color.cardBackground)
                }
            } else {
                Text("No suggestions found")
                    .font(.caption)
                    .foregroundColor(.secondaryTextColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
        }
    }
}

// Search Status View
struct SearchStatusView: View {
    let count: Int
    let searchText: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            if count > 0 {
                Text("\(count) properties found for \"\(searchText)\"")
                    .font(.caption)
                    .foregroundColor(.secondaryTextColor)
            } else {
                Text("No properties found for \"\(searchText)\"")
                    .font(.caption)
                    .foregroundColor(.secondaryTextColor)
            }
            Spacer()
            Button("Done") {
                onDismiss()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.accentBlues)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.cardBackground.opacity(0.8))
        .cornerRadius(8)
    }
}

#Preview {
    VStack {
        SearchSuggestionView(
            suggestions: ["Beach", "House", "Apartment", "Condo", "Land"],
            onSuggestionSelected: { _ in }
        )
        .background(Color.gray.opacity(0.1))
        
        SearchStatusView(
            count: 24,
            searchText: "Beach House",
            onDismiss: {}
        )
    }
}
