import SwiftUI

struct CommunityChatView: View {
    @ObservedObject var communityService: CommunityService
    @State private var showingNewChat = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Community Chat")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingNewChat = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.accentBlues)
                            .padding(8)
                            .background(Color.secondaryBackground)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                // Chat list
                ChatListView(communityService: communityService)
            }
            .sheet(isPresented: $showingNewChat) {
                NewChatView(communityService: communityService)
            }
            .onAppear {
                Task {
                    await communityService.loadChatRooms()
                }
            }
        }
    }
}

#Preview {
    CommunityChatView(communityService: CommunityService())
}
