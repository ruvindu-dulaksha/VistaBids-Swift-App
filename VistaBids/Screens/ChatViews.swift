//
//  ChatViews.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-09.
//

import SwiftUI

//Chat List View
struct ChatListView: View {
    @ObservedObject var communityService: CommunityService
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    
    var filteredChats: [ChatRoom] {
        if searchText.isEmpty {
            return communityService.chatRooms.sorted { 
                ($0.lastMessageTime ?? Date.distantPast) > ($1.lastMessageTime ?? Date.distantPast)
            }
        } else {
            return communityService.chatRooms.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $searchText, placeholder: "Search chats")
            
            // Chat list
            List {
                ForEach(filteredChats) { chat in
                    NavigationLink(destination: ChatDetailView(chatRoom: chat)) {
                        ChatRowView(chatRoom: chat)
                    }
                    .listRowBackground(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                }
            }
            .listStyle(PlainListStyle())
            .overlay(
                Group {
                    if communityService.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                    } else if filteredChats.isEmpty {
                        VStack {
                            Image(systemName: "message.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                                .padding(.bottom, 8)
                            Text("No chats yet")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("Start a conversation to see it here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            )
        }
        .onAppear {
            Task {
                await communityService.loadChatRooms()
            }
        }
        .refreshable {
            await communityService.loadChatRooms()
        }
    }
}

// Chat Row View
struct ChatRowView: View {
    let chatRoom: ChatRoom
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Group {
                if chatRoom.isGroup {
                    ZStack {
                        Circle()
                            .fill(Color.accentBlues.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.accentBlues)
                            .font(.title2)
                    }
                } else {
                    AsyncImage(url: URL(string: chatRoom.imageURL ?? "")) { image in
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
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                }
            }
            
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chatRoom.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let lastMessageTime = chatRoom.lastMessageTime {
                        Text(lastMessageTime, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text(chatRoom.lastMessage ?? "No messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if chatRoom.isGroup {
                        Text("\(chatRoom.participants.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentBlues)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// Chat Detail View
struct ChatDetailView: View {
    let chatRoom: ChatRoom
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var selectedLanguage = "en"
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var communityService = CommunityService()
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                ChatMessageView(
                                    message: message,
                                    isCurrentUser: message.senderId == "currentUser",
                                    selectedLanguage: selectedLanguage
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .refreshable {
                    await loadMessages()
                }
            }
            
            // Message input
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color.inputFields)
                    .cornerRadius(20)
                    .lineLimit(1...5)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(messageText.isEmpty ? Color.gray : Color.accentBlues)
                        .clipShape(Circle())
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        }
        .navigationTitle(chatRoom.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("English") { selectedLanguage = "en" }
                    Button("Español") { selectedLanguage = "es" }
                    Button("Français") { selectedLanguage = "fr" }
                    Button("Deutsch") { selectedLanguage = "de" }
                    Button("日本語") { selectedLanguage = "ja" }
                    Button("中文") { selectedLanguage = "zh" }
                } label: {
                    Image(systemName: "globe")
                }
            }
        }
        .onAppear {
            Task {
                await loadMessages()
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty, let chatId = chatRoom.id else { return }
        
        Task {
            await communityService.sendMessage(toChatId: chatId, content: messageText)
            messageText = ""
            await loadMessages()
        }
    }
    
    private func loadMessages() async {
        guard let chatId = chatRoom.id else { return }
        
        isLoading = true
        messages = await communityService.loadMessages(forChatId: chatId)
        isLoading = false
    }
}

// Chat Message View
struct ChatMessageView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let selectedLanguage: String
    
    @State private var isTranslated = false
    @State private var translatedContent: String?
    @State private var isTranslating = false
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                        Text(isTranslated ? (translatedContent ?? message.content) : message.content)
                            .font(.body)
                            .foregroundColor(isCurrentUser ? .white : .textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isCurrentUser ? Color.accentBlues : Color.inputFields)
                            .cornerRadius(16)
                        
                        HStack {
                            if isTranslated {
                                Image(systemName: "globe")
                                    .font(.caption2)
                                    .foregroundColor(.accentBlues)
                            }
                            
                            Text(message.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !isCurrentUser && selectedLanguage != message.originalLanguage {
                        Button(action: translateMessage) {
                            Image(systemName: isTranslating ? "hourglass" : "translate")
                                .font(.caption)
                                .foregroundColor(.accentBlues)
                                .opacity(isTranslating ? 0.5 : 1.0)
                        }
                        .disabled(isTranslating)
                    }
                }
            }
            
            if !isCurrentUser {
                Spacer(minLength: 50)
            }
        }
        .id(message.id)
    }
    
    private func translateMessage() {
        guard selectedLanguage != message.originalLanguage && !isTranslated else { return }
        
        isTranslating = true
        
        Task {
            // Simulate translation
            try await Task.sleep(nanoseconds: 500_000_000)
            
            let mockTranslation: String
            switch selectedLanguage {
            case "es":
                mockTranslation = "🇪🇸 [Traducido] \(message.content)"
            case "fr":
                mockTranslation = "🇫🇷 [Traduit] \(message.content)"
            case "de":
                mockTranslation = "🇩🇪 [Übersetzt] \(message.content)"
            case "ja":
                mockTranslation = "🇯🇵 [翻訳済み] \(message.content)"
            case "zh":
                mockTranslation = "🇨🇳 [已翻译] \(message.content)"
            default:
                mockTranslation = message.content
            }
            
            await MainActor.run {
                translatedContent = mockTranslation
                isTranslated = true
                isTranslating = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatListView(communityService: CommunityService())
    }
}
