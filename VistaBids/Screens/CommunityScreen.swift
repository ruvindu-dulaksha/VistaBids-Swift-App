//
//  CommunityScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-08.
//

import SwiftUI
import FirebaseAuth

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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button("Clear & Upload") {
                        Task {
                            await communityService.clearAndUploadFreshData()
                        }
                    }
                    .font(.caption)
                    
                    Button("Load Posts") {
                        Task {
                            await communityService.loadPosts()
                        }
                    }
                    .font(.caption)
                }
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
    @State private var refreshTrigger = false
    
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
        .onAppear {
            print("🧩 FeedView: onAppear - current posts count: \(communityService.posts.count)")
            Task {
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
            
            // Create a notification observer to reload posts when comments are added or likes change
            NotificationCenter.default.addObserver(forName: NSNotification.Name("RefreshCommunityFeed"), object: nil, queue: .main) { _ in
                print("📢 Received notification to refresh community feed")
                Task {
                    await communityService.loadPosts()
                }
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
    @State private var internalSelectedLanguage: String
    
    init(communityService: CommunityService, selectedLanguage: String) {
        self.communityService = communityService
        self.selectedLanguage = selectedLanguage
        _internalSelectedLanguage = State(initialValue: selectedLanguage)
    }
    
    var body: some View {
        CommunityChatView(communityService: communityService)
            .onChange(of: selectedLanguage) { _, newValue in
                internalSelectedLanguage = newValue
            }
    }
}

// MARK: - Post Card
struct PostCardOriginal: View {
    let post: CommunityPost
    let selectedLanguage: String
    @ObservedObject var communityService: CommunityService
    @State private var translatedPost: CommunityPost?
    @State private var isTranslating = false
    @State private var showingComments = false
    @State private var selectedPostId: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Debug info - remove this later
            if post.originalLanguage != selectedLanguage {
                Text("🔍 Debug: Post(\(post.originalLanguage)) vs Selected(\(selectedLanguage))")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            
            // Header
            HStack {
                AsyncImage(url: URL(string: post.authorAvatar ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_), .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    }
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
                        print("🔄 Translate button tapped - Post Language: \(post.originalLanguage), Selected: \(selectedLanguage)")
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
            Text(getDisplayContent())
                .font(.body)
                .foregroundColor(.primary)
            
            // Images if any
            if !post.imageURLs.isEmpty {
                if post.imageURLs.count == 1 {
                    // Single image - full width with proper aspect ratio
                    AsyncImage(url: URL(string: post.imageURLs[0])) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .clipped()
                        case .failure(_):
                            // Error state with fallback
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.badge.exclamationmark")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                        Text("Image unavailable")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        case .empty:
                            // Loading state
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    ProgressView()
                                        .tint(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Multiple images - horizontal scroll with improved sizing
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(post.imageURLs, id: \.self) { url in
                                AsyncImage(url: URL(string: url)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(1.2, contentMode: .fill)
                                            .frame(width: 240, height: 200)
                                            .clipped()
                                            .cornerRadius(12)
                                    case .failure(_):
                                        // Error state with fallback
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 240, height: 200)
                                            .cornerRadius(12)
                                            .overlay(
                                                VStack(spacing: 6) {
                                                    Image(systemName: "photo.badge.exclamationmark")
                                                        .font(.title2)
                                                        .foregroundColor(.gray)
                                                    Text("Image\nunavailable")
                                                        .font(.caption2)
                                                        .foregroundColor(.gray)
                                                        .multilineTextAlignment(.center)
                                                }
                                            )
                                    case .empty:
                                        // Loading state
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 240, height: 200)
                                            .cornerRadius(12)
                                            .overlay(
                                                ProgressView()
                                                    .tint(.gray)
                                            )
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
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
                    Task {
                        if let id = post.id {
                            print("🧡 Liking post: \(id)")
                            await communityService.likePost(id)
                            // This will force a UI refresh locally while waiting for the notification
                            await MainActor.run {
                                let currentUserId = Auth.auth().currentUser?.uid ?? "currentUser"
                                if var localPostIndex = communityService.posts.firstIndex(where: { $0.id == id }) {
                                    if communityService.posts[localPostIndex].likedBy.contains(currentUserId) {
                                        communityService.posts[localPostIndex].likedBy.removeAll { $0 == currentUserId }
                                        communityService.posts[localPostIndex].likes = max(0, communityService.posts[localPostIndex].likes - 1)
                                    } else {
                                        communityService.posts[localPostIndex].likedBy.append(currentUserId)
                                        communityService.posts[localPostIndex].likes += 1
                                    }
                                }
                            }
                        }
                    }
                }) {
                    HStack {
                        // Check if current user has liked the post
                        // Get current user ID or use "currentUser" as fallback for testing
                        let currentUserId = Auth.auth().currentUser?.uid ?? "currentUser"
                        Image(systemName: post.likedBy.contains(currentUserId) ? "heart.fill" : "heart")
                        Text("\(post.likes)")
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: {
                    // Comment action - Opens comment sheet
                    if let id = post.id {
                        print("💬 Opening comments for post: \(id)")
                        showCommentSheet(for: id)
                    } else {
                        print("⚠️ Cannot open comments: post.id is nil")
                    }
                }) {
                    HStack {
                        Image(systemName: "message")
                        Text("\(post.comments)")
                    }
                    .foregroundColor(.accentBlues)
                }
                
                Spacer()
                
                Button(action: {
                    // Share action using UIActivityViewController
                    let content = post.content
                    let shareItems: [Any] = [content]
                    
                    let ac = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                    
                    // Present the activity controller
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(ac, animated: true)
                    }
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
        .sheet(isPresented: $showingComments) {
            if let postId = selectedPostId {
                CommentView(postId: postId, communityService: communityService)
            }
        }
    }
    
    private func showCommentSheet(for postId: String) {
        // Set the selected post ID first, then show the sheet after a small delay
        // to ensure the binding is updated before the sheet is presented
        selectedPostId = postId
        
        // Ensure we're on the main thread when updating UI state
        DispatchQueue.main.async {
            print("📱 Opening comment sheet for post: \(postId)")
            showingComments = true
        }
    }
    
    private func translatePost() {
        isTranslating = true
        // Clear any previous errors
        communityService.error = nil
        
        Task {
            do {
                let result = await communityService.translatePost(post, to: selectedLanguage)
                
                // Update UI on main thread
                await MainActor.run {
                    translatedPost = result
                    
                    // Check if translation was successful
                    if let error = communityService.error {
                        print("⚠️ Translation error: \(error)")
                        // Reset to show original post on error
                        translatedPost = post
                    } else if result.isTranslated == true {
                        print("✅ Translation successful to \(selectedLanguage)")
                        print("🌐 Translated content: \(result.translatedContent ?? "None")")
                    } else {
                        print("ℹ️ No translation needed - same language")
                    }
                    
                    isTranslating = false
                }
            } catch {
                await MainActor.run {
                    print("⚠️ Translation failed: \(error.localizedDescription)")
                    translatedPost = post // Show original on error
                    isTranslating = false
                }
            }
        }
    }
    
    private func getDisplayContent() -> String {
        // Debug logging
        print("🔍 getDisplayContent() - translatedPost: \(translatedPost != nil)")
        print("🔍 translatedPost?.isTranslated: \(translatedPost?.isTranslated ?? false)")
        print("🔍 translatedPost?.translatedContent: \(translatedPost?.translatedContent ?? "nil")")
        print("🔍 post.content: \(post.content)")
        
        // If we have a translated post and it has translated content, use it
        if let translated = translatedPost,
           translated.isTranslated == true,
           let translatedContent = translated.translatedContent,
           !translatedContent.isEmpty {
            return translatedContent
        }
        
        // Otherwise use original content
        return post.content
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
                AsyncImage(url: URL(string: group.imageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_), .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.gray)
                            )
                    }
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
