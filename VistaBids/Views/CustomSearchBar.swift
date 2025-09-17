//
//  CustomSearchBar.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2024-08-09.
//

import SwiftUI

struct CustomSearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    // Dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                   to: nil, 
                                                   from: nil, 
                                                   for: nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    CustomSearchBar(text: .constant(""), placeholder: "Search")
        .previewLayout(.sizeThatFits)
}
