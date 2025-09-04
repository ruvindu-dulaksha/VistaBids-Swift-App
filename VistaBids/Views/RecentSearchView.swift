//
//  RecentSearchView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2023-08-23.
//

import SwiftUI

struct RecentSearchView: View {
    let searchHistory: [String]
    let onSearchSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent Searches")
                .font(.caption)
                .foregroundColor(.secondaryTextColor)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            ForEach(searchHistory.reversed().prefix(5), id: \.self) { search in
                Button {
                    onSearchSelected(search)
                } label: {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondaryTextColor)
                        Text(search)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundColor(.accentBlues)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.cardBackground)
            }
            
            if !searchHistory.isEmpty {
                Divider()
                    .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - UserDefaults Extension for Search History
extension UserDefaults {
    private enum Keys {
        static let recentSearches = "recentSearches"
    }
    
    var recentSearches: [String] {
        get {
            return array(forKey: Keys.recentSearches) as? [String] ?? []
        }
        set {
            set(newValue, forKey: Keys.recentSearches)
        }
    }
    
    func addRecentSearch(_ searchText: String) {
        var searches = recentSearches
        
        // Remove if it already exists to avoid duplicates
        if let existingIndex = searches.firstIndex(of: searchText) {
            searches.remove(at: existingIndex)
        }
        
        // Add the new search at the beginning
        searches.append(searchText)
        
        // Keep only the last 10 searches
        if searches.count > 10 {
            searches.removeFirst()
        }
        
        recentSearches = searches
    }
    
    func clearRecentSearches() {
        recentSearches = []
    }
}

#Preview {
    RecentSearchView(
        searchHistory: ["Beach House", "Apartment in New York", "Rental Properties", "Land for Sale", "Mountain View"],
        onSearchSelected: { _ in }
    )
    .background(Color.gray.opacity(0.1))
}
