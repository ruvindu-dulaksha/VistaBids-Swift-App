//
//  View+Extensions.swift
//  VistaBids
//
//  Created by Assistant on 2025-08-21.
//

import SwiftUI

extension View {
    // Add shadow to specific edges
    func shadowOnBottom(opacity: Double = 0.15, radius: CGFloat = 10) -> some View {
        self.shadow(color: Color.black.opacity(opacity), radius: radius, x: 0, y: 5)
    }
    
    // Add shadow to top
    func shadowOnTop(opacity: Double = 0.1, radius: CGFloat = 8) -> some View {
        self.shadow(color: Color.black.opacity(opacity), radius: radius, x: 0, y: -3)
    }
    
    // Responsive padding based on device size
    func responsivePadding() -> some View {
        let isSmallDevice = UIScreen.main.bounds.width < 375
        return self.padding(.horizontal, isSmallDevice ? 12 : 20)
    }
}
