import SwiftUI

struct NewChatView: View {
    @ObservedObject var communityService: CommunityService
    @Environment(\.dismiss) private var dismiss
    @State private var chatName = ""
    @State private var isGroup = false
    @State private var selectedUsers: [String] = []
    @State private var availableUsers: [ChatUser] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chat Details")) {
                    TextField("Chat Name", text: $chatName)
                        .autocapitalization(.words)
                    
                    Toggle("Group Chat", isOn: $isGroup)
                    
                    if isGroup {
                        Text("Selected Participants: \(selectedUsers.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Participants")) {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if availableUsers.isEmpty {
                        Text("No users available")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(availableUsers) { user in
                            HStack {
                                if let avatarUrl = user.avatarURL, !avatarUrl.isEmpty {
                                    AsyncImage(url: URL(string: avatarUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 40, height: 40)
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(user.displayName)
                                
                                Spacer()
                                
                                if selectedUsers.contains(user.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentBlues)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleUserSelection(user.id)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Create Chat") {
                        createChat()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(chatName.isEmpty || selectedUsers.isEmpty)
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadUsers()
            }
        }
    }
    
    private func toggleUserSelection(_ userId: String) {
        if selectedUsers.contains(userId) {
            selectedUsers.removeAll { $0 == userId }
        } else {
            selectedUsers.append(userId)
        }
    }
    
    private func loadUsers() {
        // Simulate loading users
        isLoading = true
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            availableUsers = [
                ChatUser(id: "user1", displayName: "John Smith", avatarURL: nil),
                ChatUser(id: "user2", displayName: "Emma Johnson", avatarURL: nil),
                ChatUser(id: "user3", displayName: "Michael Brown", avatarURL: nil),
                ChatUser(id: "user4", displayName: "Olivia Davis", avatarURL: nil),
                ChatUser(id: "user5", displayName: "William Wilson", avatarURL: nil)
            ]
            isLoading = false
        }
    }
    
    private func createChat() {
        Task {
            // For a non-group chat, use the other user's name as the chat name
            let finalChatName = isGroup ? chatName : (availableUsers.first { selectedUsers.contains($0.id) }?.displayName ?? chatName)
            
            if let _ = await communityService.createChatRoom(
                name: finalChatName,
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

// Simple ChatUser model for the chat creation
struct ChatUser: Identifiable {
    let id: String
    let displayName: String
    let avatarURL: String?
}

#Preview {
    NewChatView(communityService: CommunityService())
}
