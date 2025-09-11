//
//  CommunityScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-08.
//

import SwiftUI
import FirebaseAuth

struct CommunityScreenV2: View {
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
                    
                    LanguageSelector(selectedLanguage: $selectedLanguage)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                
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
                    FeedViewV2(communityService: communityService, selectedLanguage: selectedLanguage)
                        .tag(0)
                    
                    // Groups Tab
                    GroupsViewV2(communityService: communityService, selectedLanguage: selectedLanguage)
                        .tag(1)
                    
                    // Events Tab
                    EventsViewV2(communityService: communityService, selectedLanguage: selectedLanguage)
                        .tag(2)
                    
                    // Chat Tab
                    ChatViewV2(communityService: communityService, selectedLanguage: selectedLanguage)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $showingNewPost) {
                NewPostViewV2(communityService: communityService)
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
struct LanguageSelector: View {
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
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

// MARK: - Feed View
struct FeedViewV2: View {
    @ObservedObject var communityService: CommunityService
    let selectedLanguage: String
    @State private var showingNewPost = false
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(communityService.posts) { post in
                        PostCard(post: post, selectedLanguage: selectedLanguage, communityService: communityService)
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
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        )
        .sheet(isPresented: $showingNewPost) {
            NewPostViewV2(communityService: communityService)
        }
        .onAppear {
            Task {
                await communityService.loadPosts()
            }
        }
    }
}

// MARK: - Groups View
struct GroupsViewV2: View {
    @ObservedObject var communityService: CommunityService
    let selectedLanguage: String
    @State private var showingNewGroup = false
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(communityService.groups) { group in
                        GroupCard(group: group, selectedLanguage: selectedLanguage)
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
                            .background(Color.green)
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
struct EventsViewV2: View {
    @ObservedObject var communityService: CommunityService
    let selectedLanguage: String
    @State private var showingNewEvent = false
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(communityService.events) { event in
                        EventCard(event: event, selectedLanguage: selectedLanguage)
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
                            .background(Color.orange)
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
struct ChatViewV2: View {
    @ObservedObject var communityService: CommunityService
    let selectedLanguage: String
    
    var body: some View {
        ChatListView(communityService: communityService)
    }
}

// MARK: - Post Card
struct PostCard: View {
    let post: CommunityPost
    let selectedLanguage: String
    @ObservedObject var communityService: CommunityService
    @State private var translatedPost: CommunityPost?
    @State private var isTranslating = false
    @State private var showingComments = false
    
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
                            Image(systemName: isTranslating ? "clock" : "translate")
                            Text(isTranslating ? "Translating..." : "Translate")
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
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
                        .foregroundColor(.blue)
                    Text(location.address ?? "Unknown location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Actions
            HStack {
                Button(action: {
                    // Like action
                    if let postId = post.id {
                        Task {
                            await communityService.likePost(postId)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: post.likedBy.contains(Auth.auth().currentUser?.uid ?? "") ? "heart.fill" : "heart")
                        Text("\(post.likes)")
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: {
                    // Comment action
                    showingComments = true
                }) {
                    HStack {
                        Image(systemName: "message")
                        Text("\(post.comments)")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    // Share action
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.green)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .sheet(isPresented: $showingComments) {
            if let postId = post.id {
                CommentView(postId: postId, communityService: communityService)
            }
        }
    }
    
    private func translatePost() {
        isTranslating = true
        Task {
            translatedPost = await communityService.translatePost(post, to: selectedLanguage)
            isTranslating = false
        }
    }
}

// MARK: - Group Card
struct GroupCard: View {
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
                        .foregroundColor(.blue)
                    Text("\(group.members.count) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if group.isPrivate {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            Text(group.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Event Card
struct EventCard: View {
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
                        .foregroundColor(.orange)
                    Text(event.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(event.attendees.count)")
                        .font(.headline)
                        .foregroundColor(.blue)
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
                    .foregroundColor(.blue)
                Text(event.location.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    CommunityScreenV2()
}
