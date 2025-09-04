//
//  SearchBar.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-09.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.inputFields)
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    SearchBar(text: .constant(""), placeholder: "Search...")
}
