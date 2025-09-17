//
//  TopAppBar.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-08.
//

import SwiftUI

struct TopAppBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let showBackButton: Bool
    let showThemeToggle: Bool
    let backgroundColor: Color?
    let actions: [AppBarAction]
    
    init(
        title: String = "",
        showBackButton: Bool = false,
        showThemeToggle: Bool = true,
        backgroundColor: Color? = nil,
        actions: [AppBarAction] = []
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.showThemeToggle = showThemeToggle
        self.backgroundColor = backgroundColor
        self.actions = actions
    }
    
    var body: some View {
        HStack {
            // Leading section
            HStack(spacing: 12) {
                if showBackButton {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                if !title.isEmpty {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Trailing section
            HStack(spacing: 16) {
                
                ForEach(actions, id: \.id) { action in
                    if let customView = action.customView {
                        customView
                    } else if !action.icon.isEmpty {
                        Button(action: action.action) {
                            Image(systemName: action.icon)
                                .font(.title3)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
                
                // Theme toggle
                if showThemeToggle {
                    ThemeToggleButton()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            (backgroundColor ?? Color.navigationBackground)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
}

//Theme Toggle Button
struct ThemeToggleButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showThemeSelector = false
    
    var body: some View {
        Button(action: {
            showThemeSelector.toggle()
        }) {
            Image(systemName: themeManager.currentTheme.icon)
                .font(.title3)
                .foregroundColor(.textPrimary)
                .animation(.easeInOut(duration: 0.2), value: themeManager.currentTheme)
        }
        .actionSheet(isPresented: $showThemeSelector) {
            ActionSheet(
                title: Text("Appearance"),
                message: Text("Choose your preferred appearance"),
                buttons: ThemeMode.allCases.map { theme in
                    .default(Text(theme.displayName)) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            themeManager.currentTheme = theme
                        }
                    }
                } + [.cancel()]
            )
        }
    }
}

// App Bar Action
struct AppBarAction {
    let id = UUID()
    let icon: String
    let action: () -> Void
    let customView: AnyView?
    
    init(icon: String, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
        self.customView = nil
    }
    
    init(icon: String, action: @escaping () -> Void, customView: AnyView) {
        self.icon = icon
        self.action = action
        self.customView = customView
    }
}

// Quick Theme Toggle (for floating action)
struct QuickThemeToggle: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                themeManager.toggleTheme()
            }
        }) {
            Image(systemName: themeManager.currentTheme.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentBlues)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    VStack {
        TopAppBar(
            title: "VistaBids",
            showBackButton: false,
            showThemeToggle: true,
            actions: [
                AppBarAction(icon: "bell", action: {}),
                AppBarAction(icon: "magnifyingglass", action: {})
            ]
        )
        .environmentObject(ThemeManager())
        
        Spacer()
        
        QuickThemeToggle()
            .environmentObject(ThemeManager())
    }
    .background(Color.backgrounds)
}
