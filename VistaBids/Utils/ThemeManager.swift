//
//  ThemeManager.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-08.
//

import SwiftUI
import Foundation

// MARK: - Theme Mode Enum
enum ThemeMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: ThemeMode {
        didSet {
            saveTheme()
            updateAppearance()
        }
    }
    
    @Published var isDarkMode: Bool = false
    
    private let themeKey = "app_theme_mode"
    
    init() {
        // Load saved theme or default to system
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = ThemeMode(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
        
        updateAppearance()
        
        // Listen for system theme changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemThemeChanged),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
    }
    
    private func updateAppearance() {
        DispatchQueue.main.async {
            switch self.currentTheme {
            case .light:
                self.isDarkMode = false
                self.setAppearance(.light)
            case .dark:
                self.isDarkMode = true
                self.setAppearance(.dark)
            case .system:
                let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
                self.isDarkMode = systemIsDark
                self.setAppearance(.unspecified)
            }
        }
    }
    
    private func setAppearance(_ style: UIUserInterfaceStyle) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.overrideUserInterfaceStyle = style
        }
    }
    
    @objc private func systemThemeChanged() {
        if currentTheme == .system {
            updateAppearance()
        }
    }
    
    func toggleTheme() {
        switch currentTheme {
        case .light:
            currentTheme = .dark
        case .dark:
            currentTheme = .system
        case .system:
            currentTheme = .light
        }
    }
}

// MARK: - Theme Colors

