import SwiftUI

struct ChatListView: View {
    @ObservedObject var communityService: CommunityService
    @State private var searchText = ""
    @State private var showingNewChat = false
    @State private var selectedChatRoom: ChatRoom?
    @State private var selectedLanguage = "en"
    
    var filteredChatRooms: [ChatRoom] {
        if searchText.isEmpty {
            return communityService.chatRooms
        } else {
            return communityService.chatRooms.filter { chatRoom in
                chatRoom.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Language selector
            HStack {
                Spacer()
                LanguageSelector(selectedLanguage: $selectedLanguage)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search chats", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.inputFields)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom)
            
            if communityService.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                Spacer()
            } else if filteredChatRooms.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "message.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Chat Rooms")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Start a new conversation or join a community chat")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button(action: {
                        showingNewChat = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Chat")
                        }
                        .padding()
                        .background(Color.accentBlues)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
                Spacer()
            } else {
                // Chat rooms list
                List {
                    ForEach(filteredChatRooms) { chatRoom in
                        ChatRoomRow(chatRoom: chatRoom)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedChatRoom = chatRoom
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewChat) {
            NewChatView(communityService: communityService)
        }
        .sheet(item: $selectedChatRoom) { chatRoom in
            ChatDetailView(chatRoom: chatRoom, communityService: communityService, selectedLanguage: $selectedLanguage)
        }
        .onAppear {
            Task {
                await communityService.loadChatRooms()
            }
        }
    }
}

struct ChatRoomRow: View {
    let chatRoom: ChatRoom
    
    var body: some View {
        HStack(spacing: 12) {
            // Chat image
            AsyncImage(url: URL(string: chatRoom.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                if chatRoom.isGroup {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.accentBlues)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.accentBlues)
                        .clipShape(Circle())
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Chat info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chatRoom.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if chatRoom.isGroup {
                        Image(systemName: "person.3.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let lastMessageTime = chatRoom.lastMessageTime {
                        Text(timeAgo(from: lastMessageTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let lastMessage = chatRoom.lastMessage {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("No messages yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

struct NewChatView: View {
    @ObservedObject var communityService: CommunityService
    @Environment(\.dismiss) private var dismiss
    @State private var chatName = ""
    @State private var isGroup = false
    @State private var selectedUsers: [String] = ["user1", "user2"] // Sample users
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chat Details")) {
                    TextField("Chat Name", text: $chatName)
                    
                    Toggle("Group Chat", isOn: $isGroup)
                    
                    if isGroup {
                        Text("Selected Participants: \(selectedUsers.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Participants")) {
                    // In a real app, you would fetch users from a database
                    // and allow the user to select from a list
                    ForEach(["user1", "user2", "user3", "user4", "user5"], id: \.self) { userId in
                        HStack {
                            Text(getUserName(for: userId))
                            Spacer()
                            if selectedUsers.contains(userId) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentBlues)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedUsers.contains(userId) {
                                selectedUsers.removeAll { $0 == userId }
                            } else {
                                selectedUsers.append(userId)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Create Chat") {
                        createChat()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(chatName.isEmpty || selectedUsers.isEmpty)
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getUserName(for userId: String) -> String {
        switch userId {
        case "user1": return "John Smith"
        case "user2": return "Sarah Johnson"
        case "user3": return "Mike Chen"
        case "user4": return "Emily Davis"
        case "user5": return "David Wilson"
        default: return "Unknown User"
        }
    }
    
    private func createChat() {
        Task {
            let name = isGroup ? chatName : getUserName(for: selectedUsers.first ?? "")
            if let _ = await communityService.createChatRoom(
                name: name,
                participants: selectedUsers,
                isGroup: isGroup
            ) {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}

struct ChatDetailView: View {
    let chatRoom: ChatRoom
    @ObservedObject var communityService: CommunityService
    @Binding var selectedLanguage: String
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            HStack {
                AsyncImage(url: URL(string: chatRoom.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    if chatRoom.isGroup {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.accentBlues)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.accentBlues)
                            .clipShape(Circle())
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(chatRoom.name)
                        .font(.headline)
                    
                    if chatRoom.isGroup {
                        Text("\(chatRoom.participants.count) participants")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Language selector in header
                LanguageSelector(selectedLanguage: $selectedLanguage)
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.secondaryBackground)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color.cardBackground)
            
            // Messages list
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                Spacer()
            } else if messages.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Messages Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Be the first to send a message to this chat")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    isCurrentUser: message.senderId == "currentUser",
                                    selectedLanguage: selectedLanguage
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: selectedLanguage) { _, _ in
                        // Reload messages when language changes
                        Task {
                            await loadMessages()
                        }
                    }
                }
            }
            
            // Message input
            HStack {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.inputFields)
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(messageText.isEmpty ? .gray : .accentBlues)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .onAppear {
            Task {
                await loadMessages()
            }
        }
    }
    
    private func loadMessages() async {
        isLoading = true
        let loadedMessages = await communityService.loadMessages(forChatId: chatRoom.id ?? "unknown")
        await MainActor.run {
            messages = loadedMessages
            isLoading = false
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        Task {
            await communityService.sendMessage(
                toChatId: chatRoom.id ?? "unknown",
                content: messageText
            )
            
            await loadMessages()
            
            await MainActor.run {
                messageText = ""
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let selectedLanguage: String
    @State private var translatedMessage: ChatMessage?
    @State private var isTranslating = false
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            } else {
                if let avatar = message.senderAvatar, !isCurrentUser {
                    AsyncImage(url: URL(string: avatar)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.gray)
                            .clipShape(Circle())
                    }
                }
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                    Text(translatedMessage?.translatedContent ?? message.content)
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isCurrentUser ? Color.accentBlues : Color.secondaryBackground)
                        .cornerRadius(16)
                    
                    HStack(spacing: 4) {
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if message.originalLanguage != selectedLanguage {
                            Button(action: {
                                translateMessage()
                            }) {
                                if isTranslating {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                } else if translatedMessage?.translatedContent != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                } else {
                                    Image(systemName: "globe")
                                        .foregroundColor(.accentBlues)
                                        .font(.caption2)
                                }
                            }
                            .disabled(isTranslating)
                        }
                    }
                }
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private func translateMessage() {
        isTranslating = true
        
        // Simulate translation for demo purposes
        // In a real app, this would call a translation service
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            var translated = message
            translated.translatedContent = "Translated: \(message.content) [to \(selectedLanguage)]"
            translatedMessage = translated
            isTranslating = false
        }
    }
}

struct LanguageSelector: View {
    @Binding var selectedLanguage: String
    
    private let languages = [
        ("en", "🇺🇸 English"),
        ("es", "🇪🇸 Spanish"),
        ("fr", "🇫🇷 French"),
        ("de", "🇩🇪 German"),
        ("ja", "🇯🇵 Japanese"),
        ("zh", "🇨🇳 Chinese")
    ]
    
    var body: some View {
        Menu {
            ForEach(languages, id: \.0) { code, display in
                Button(action: {
                    selectedLanguage = code
                }) {
                    HStack {
                        Text(display)
                        if selectedLanguage == code {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "globe")
                Text(languages.first(where: { $0.0 == selectedLanguage })?.1.split(separator: " ").first ?? "🇺🇸")
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentBlues.opacity(0.2))
            .foregroundColor(.accentBlues)
            .cornerRadius(8)
        }
    }
}

#Preview {
    NavigationView {
        ChatListView(communityService: CommunityService())
    }
}
