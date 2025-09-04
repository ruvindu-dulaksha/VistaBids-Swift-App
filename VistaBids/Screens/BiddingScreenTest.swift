//
//  BiddingScreenTest.swift
//  VistaBids
//
//  Created by Assistant on 2025-08-24.
//

import SwiftUI

struct BiddingScreenTest: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Testing Property Model Access")
                
                let sampleProperties = [Property.example]
                
                if sampleProperties.isEmpty {
                    Text("No properties available")
                } else {
                    Text("Found \(sampleProperties.count) properties")
                    
                    ForEach(Array(sampleProperties.prefix(2)), id: \.id) { property in
                        VStack(alignment: .leading) {
                            Text(property.title)
                                .font(.headline)
                            Text(property.description)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Test")
        }
    }
}

#Preview {
    BiddingScreenTest()
}
