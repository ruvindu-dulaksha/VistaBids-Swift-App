import SwiftUI
import FirebaseAuth

struct CommentView: View {
    let postId: String
    @ObservedObject var communityService: CommunityService
    @State private var comments: [PostComment] = []
    @State private var newComment: String = ""
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Comments")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing)
            }
            
            // Comments list
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                Spacer()
            } else if comments.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "bubble.left")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No comments yet")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Text("Be the first to comment")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Comment input
            HStack {
                TextField("Add a comment...", text: $newComment)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: submitComment) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(newComment.isEmpty ? .gray : .blue)
                }
                .disabled(newComment.isEmpty)
            }
            .padding()
        }
        .onAppear {
            loadComments()
        }
    }
    
    private func loadComments() {
        Task {
            isLoading = true
            comments = await communityService.getComments(for: postId)
            isLoading = false
        }
    }
    
    private func submitComment() {
        guard !newComment.isEmpty else { return }
        
        let commentText = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commentText.isEmpty else { return }
        
        Task {
            print("💬 Adding comment to post: \(postId)")
            newComment = ""  // Clear the field immediately for better UX
            
            await communityService.addComment(to: postId, content: commentText)
            await loadComments()
            
            // Post a notification to refresh the feed
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("RefreshCommunityFeed"), object: nil)
            }
        }
    }
}

struct CommentRow: View {
    let comment: PostComment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Author avatar
                if let avatarURL = comment.authorAvatar, !avatarURL.isEmpty {
                    AsyncImage(url: URL(string: avatarURL)) { image in
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
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.author)
                        .font(.headline)
                    
                    Text(comment.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(comment.content)
                .font(.body)
                .padding(.leading, 8)
                .padding(.top, 4)
            
            Divider()
        }
    }
}

#Preview {
    CommentView(postId: "sample-post-id", communityService: CommunityService())
}
