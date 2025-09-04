//
//  MainTabView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-08.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var notificationService = NotificationService.shared
    @State private var showingNewPost = false
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Top App Bar
            TopAppBar(
                title: tabTitle,
                showBackButton: false,
                showThemeToggle: selectedTab != 4, // Hide theme toggle on Profile tab
                actions: topBarActions
            )
            
            // Tab Content
            TabView(selection: $selectedTab) {
                HomeScreen()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "map.fill" : "map")
                        Text("Home")
                    }
                    .tag(0)
                
                BiddingScreen()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "hammer.fill" : "hammer")
                        Text("Bidding")
                    }
                    .tag(1)
                
                SellPropertyScreen()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "plus.circle.fill" : "plus.circle")
                        Text("Sell")
                    }
                    .tag(2)
                
                CommunityScreen()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "person.3.fill" : "person.3")
                        Text("Community")
                    }
                    .tag(3)
                
                ProfileScreen()
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                        Text("Profile")
                    }
                    .tag(4)
            }
            .accentColor(.accentBlues)
        }
        .background(Color.backgrounds)
        .onAppear {
            // Customize tab bar appearance for theme support
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Set shadow
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .sheet(isPresented: $showingNewPost) {
            NewPostView(communityService: CommunityService())
        }
        .sheet(isPresented: $showingSettings) {
            ProfileScreen() // Use ProfileScreen instead of SettingsView since we don't have a settings view
        }
    }
    
    private var tabTitle: String {
        switch selectedTab {
        case 0: return "VistaBids"
        case 1: return "My Bids"
        case 2: return "Sell Property"
        case 3: return "Community"
        case 4: return "Profile"
        default: return "VistaBids"
        }
    }
    
    private var topBarActions: [AppBarAction] {
        switch selectedTab {
        case 0: return [
            AppBarAction(icon: "", action: { }, customView: AnyView(NotificationBellView())),
            //AppBarAction(icon: "magnifyingglass", action: { /* Handle search */ })
        ]
        case 1: return [
            AppBarAction(icon: "", action: { }, customView: AnyView(NotificationBellView()))
        ]
        case 2: return [
            AppBarAction(icon: "", action: { }, customView: AnyView(NotificationBellView()))
        ]
        case 3: return [
            AppBarAction(icon: "plus", action: { 
                showingNewPost = true 
            }),
            AppBarAction(icon: "", action: { }, customView: AnyView(NotificationBellView()))
        ]
        case 4: return []
        default: return [
            AppBarAction(icon: "", action: { }, customView: AnyView(NotificationBellView()))
        ]
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(FirebaseAuthService())
        .environmentObject(ThemeManager())
}
