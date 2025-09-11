import SwiftUI
import Firebase
import FirebaseAuth

struct MyBidsView: View {
    @EnvironmentObject private var authService: FirebaseAuthService
    @State private var bids: [Bid] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading your bids...")
                } else if bids.isEmpty {
                    ContentUnavailableView(
                        "No Bids Yet",
                        systemImage: "list.bullet",
                        description: Text("Your bids will appear here")
                    )
                } else {
                    List(bids) { bid in
                        BidRowView(bid: bid)
                    }
                }
            }
            .navigationTitle("My Bids")
            .onAppear {
                loadBids()
            }
        }
    }
    
    private func loadBids() {
        guard let userId = authService.currentUser?.uid else { return }
        isLoading = true
        // TODO: Implement Firebase bid fetching
        isLoading = false
    }
}

#Preview {
    MyBidsView()
        .environmentObject(FirebaseAuthService())
}