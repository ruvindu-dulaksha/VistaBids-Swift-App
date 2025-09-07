//
//  CommunityScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-08.
//

import SwiftUI

struct CommunityScreen: View {
    @StateObject private var communityService = CommunityService()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @State private var showingNewPost = false
    @State private var showingNewEvent = false
    @State private var showingNewGroup = false
    @State private var showingChat = false
    @State private var selectedLanguage = "en"
    
    private let tabs = ["Feed", "Groups", "Events", "Chat"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with language selector
                HStack {
                    Text("Community")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    LanguageSelectorOriginal(selectedLanguage: $selectedLanguage)
                }
                .padding()
                .background(Color.backgrounds)
                
                // Segmented Control
                Picker("Tabs", selection: $selectedTab) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Text(tabs[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Feed Tab
                    FeedView(communityService: communityService, selectedLanguage: selectedLanguage)
                        .tag(0)
                    
                    // Groups Tab
                    GroupsView(communityService: communityService, selectedLanguage: selectedLanguage)
                        .tag(1)
                    
                    // Events Tab
                    EventsView(communityService: communityService, selectedLanguage: selectedLanguage)
                        .tag(2)
                    
                    // Chat Tab
                    ChatView(communityService: communityService, selectedLanguage: selectedLanguage)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color.backgrounds)
            .sheet(isPresented: $showingNewPost) {
                NewPostView(communityService: communityService)
            }
            .sheet(isPresented: $showingNewEvent) {
                NewEventView(communityService: communityService)
            }
            .sheet(isPresented: $showingNewGroup) {
                NewGroupView(communityService: communityService)
            }
            .sheet(isPresented: $showingChat) {
                ChatListView(communityService: communityService)
            }
        }
        .preferredColorScheme(themeManager.currentTheme == .system ? nil : 
                             (themeManager.isDarkMode ? .dark : .light))
    }
}

// MARK: - Language Selector
struct LanguageSelectorOriginal: View {
    @Binding var selectedLanguage: String
    
    private let languages = [
        ("en", "🇺🇸 EN"),
        ("es", "🇪🇸 ES"),
        ("fr", "🇫🇷 FR"),
        ("de", "🇩🇪 DE"),
        ("ja", "🇯🇵 JP"),
        ("zh", "🇨🇳 ZH")
    ]
    
    var body: some View {
        Menu {
            ForEach(languages, id: \.0) { code, display in
                Button(action: {
                    selectedLanguage = code
                }) {
                    Text(display)
                }
            }
        } label: {
            HStack {
                Text(languages.first { $0.0 == selectedLanguage }?.1 ?? "🇺🇸 EN")
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentBlues)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

// MARK: - Feed View
struct FeedView: View {
    @ObservedObject var communityService: CommunityService
    let selectedLanguage: String
    @State private var showingNewPost = false
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(communityService.posts) { post in
                        PostCardOriginal(post: post, selectedLanguage: selectedLanguage, communityService: communityService)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .refreshable {
                await communityService.loadPosts()
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingNewPost = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentBlues)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        )
        .sheet(isPresented: $showingNewPost) {
            NewPostView(communityService: communityService)
        }
        .onAppear {
            Task {
                await communityService.loadPosts()
            }
        }
    }
}

// MARK: - Groups View
struct GroupsView: View {
    @ObservedObject var communityService: CommunityService
    let selectedLanguage: String
    @State private var showingNewGroup = false
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(communityService.groups) { group in
                        GroupCardOriginal(group: group, selectedLanguage: selectedLanguage)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .refreshable {
                await communityService.loadGroups()
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingNewGroup = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentBlues)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        )
        .sheet(isPresented: $showingNewGroup) {
            NewGroupView(communityService: communityService)
        }
        .onAppear {
            Task {
                await communityService.loadGroups()
            }
        }
    }
}

// MARK: - Events View
struct EventsView: View {
    @ObservedObject var communityService: CommunityService
    let selectedLanguage: String
    @State private var showingNewEvent = false
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(communityService.events) { event in
                        EventCardOriginal(event: event, selectedLanguage: selectedLanguage)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .refreshable {
                await communityService.loadEvents()
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingNewEvent = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentBlues)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        )
        .sheet(isPresented: $showingNewEvent) {
            NewEventView(communityService: communityService)
        }
        .onAppear {
            Task {
                await communityService.loadEvents()
            }
        }
    }
}

// MARK: - Chat View
struct ChatView: View {
    @ObservedObject var communityService: CommunityService
    let selectedLanguage: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ChatListView(communityService: communityService)
    }
}

// MARK: - Post Card
struct PostCardOriginal: View {
    let post: CommunityPost
    let selectedLanguage: String
    @ObservedObject var communityService: CommunityService
    @State private var translatedPost: CommunityPost?
    @State private var isTranslating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                AsyncImage(url: URL(string: post.authorAvatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(post.author)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(post.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if post.originalLanguage != selectedLanguage {
                    Button(action: {
                        translatePost()
                    }) {
                        HStack {
                            if isTranslating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Translating...")
                            } else if translatedPost?.isTranslated == true && translatedPost?.translatedLanguage == selectedLanguage {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Translated")
                            } else {
                                Image(systemName: "translate")
                                Text("Translate to \(languageDisplayName(selectedLanguage))")
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Group {
                                if translatedPost?.isTranslated == true && translatedPost?.translatedLanguage == selectedLanguage {
                                    Color.green.opacity(0.1)
                                } else {
                                    Color.accentBlues.opacity(0.1)
                                }
                            }
                        )
                        .foregroundColor(
                            translatedPost?.isTranslated == true && translatedPost?.translatedLanguage == selectedLanguage ? .green : .accentBlues
                        )
                        .cornerRadius(8)
                    }
                    .disabled(isTranslating)
                }
            }
            
            // Content
            Text(translatedPost?.translatedContent ?? post.content)
                .font(.body)
                .foregroundColor(.primary)
            
            // Images if any
            if !post.imageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.imageURLs, id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 200, height: 150)
                                    .clipped()
                                    .cornerRadius(8)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 200, height: 150)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Location if available
            if let location = post.location {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.accentBlues)
                    Text(location.address ?? "Unknown location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Actions
            HStack {
                Button(action: {
                    // Like action
                }) {
                    HStack {
                        Image(systemName: "heart")
                        Text("\(post.likes)")
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: {
                    // Comment action
                }) {
                    HStack {
                        Image(systemName: "message")
                        Text("\(post.comments)")
                    }
                    .foregroundColor(.accentBlues)
                }
                
                Spacer()
                
                Button(action: {
                    // Share action
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.accentBlues)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func translatePost() {
        isTranslating = true
        Task {
            do {
                translatedPost = await communityService.translatePost(post, to: selectedLanguage)
                
                // Check if translation was successful
                if let error = communityService.error {
                    print("⚠️ Translation error: \(error)")
                    // Reset to show original post on error
                    translatedPost = post
                } else if translatedPost?.isTranslated == true {
                    print("✅ Translation successful to \(selectedLanguage)")
                } else {
                    print("ℹ️ No translation needed - same language")
                }
            } catch {
                print("⚠️ Translation failed: \(error.localizedDescription)")
                translatedPost = post // Show original on error
            }
            isTranslating = false
        }
    }
    
    private func languageDisplayName(_ code: String) -> String {
        let languageNames: [String: String] = [
            "en": "English",
            "es": "Spanish", 
            "fr": "French",
            "de": "German",
            "ja": "Japanese",
            "zh": "Chinese"
        ]
        return languageNames[code] ?? code.uppercased()
    }
}

// MARK: - Group Card
struct GroupCardOriginal: View {
    let group: CommunityGroup
    let selectedLanguage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AsyncImage(url: URL(string: group.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(group.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.accentBlues)
                    Text("\(group.members.count) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if group.isPrivate {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.accentBlues)
                        .font(.caption)
                }
            }
            
            Text(group.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Event Card
struct EventCardOriginal: View {
    let event: CommunityEvent
    let selectedLanguage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(event.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.accentBlues)
                    Text(event.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(event.attendees.count)")
                        .font(.headline)
                        .foregroundColor(.accentBlues)
                    Text("attending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(event.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                    Image(systemName: "location")
                        .foregroundColor(.accentBlues)
                    Text(event.location.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    CommunityScreen()
}
