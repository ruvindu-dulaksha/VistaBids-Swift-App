//
//  DarkModeGuide.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-11.
//

import SwiftUI


// Dark Mode Testing Utilities
#if DEBUG
struct DarkModePreview<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Text("Light Mode")
                    .font(.caption)
                    .padding()
                content
            }
            .preferredColorScheme(.light)
            
            VStack {
                Text("Dark Mode")
                    .font(.caption)
                    .padding()
                content
            }
            .preferredColorScheme(.dark)
            .background(Color.black)
        }
    }
}

// Usage in previews:
// #Preview {
//     DarkModePreview {
//         YourView()
//     }
// }
#endif
