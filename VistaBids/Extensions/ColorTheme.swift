//
//  ColorTheme.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-22.
//

import Foundation
import SwiftUI

extension Color {
    // Primary app colors (already have dark mode variants)
    static let backgrounds = Color("BackgroundColor")
    static let backgroundPrimary = Color("BackgroundColor")
    static let textPrimary = Color("PrimaryTextColor")
    static let inputFields = Color("InputFieldColor")
    static let accentBlues = Color("AccentBlue")
    static let linkTexts = Color("LinkTextColor")
    
    // Semantic colors for better dark mode support
    static let secondaryTextColor = Color.secondary
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let navigationBackground = Color(.systemBackground)
    static let buttonBackground = Color.accentBlues
    static let buttonText = Color.white
    static let disabledBackground = Color(.systemGray4)
    static let disabledText = Color(.systemGray2)
    static let divider = Color(.separator)
    static let overlayBackground = Color(.systemBackground).opacity(0.9)
    
    // Dynamic colors for dark mode compatibility
    static var adaptiveWhite: Color {
        return Color(.label)
    }
    
    static var adaptiveBlack: Color {
        return Color(.systemBackground)
    }
    
    static var adaptiveGray: Color {
        return Color(.systemGray)
    }
    
    static var lightGray: Color {
        return Color(.systemGray5)
    }
}

