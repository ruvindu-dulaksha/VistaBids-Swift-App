import SwiftUI

struct CommunityChatView: View {
    @ObservedObject var communityService: CommunityService
    @State private var selectedLanguage = "en"
    @State private var showingNewChat = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with language selector
            HStack {
                Text("Community Chat")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                LanguageSelector(selectedLanguage: $selectedLanguage)
                
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
                .environmentObject(TranslationEnvironment(selectedLanguage: $selectedLanguage))
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

// Environment object to pass language preference to nested views
class TranslationEnvironment: ObservableObject {
    @Binding var selectedLanguage: String
    
    init(selectedLanguage: Binding<String>) {
        _selectedLanguage = selectedLanguage
    }
}

#Preview {
    CommunityChatView(communityService: CommunityService())
}
