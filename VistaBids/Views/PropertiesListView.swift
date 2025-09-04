import SwiftUI
import Firebase

struct PropertiesListView: View {
    @State private var properties: [AuctionProperty] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading properties...")
                } else {
                    List(properties) { property in
                        NavigationLink(destination: PropertyDetailView(property: property, biddingService: BiddingService())) {
                            HStack {
                                AsyncImage(url: URL(string: property.images.first ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(property.title)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text("$\(Int(property.currentBid).formatted())")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Properties")
            .onAppear {
                loadProperties()
            }
        }
    }
    
    private func loadProperties() {
        isLoading = true
        // TODO: Implement Firebase property fetching
        isLoading = false
    }
}

#Preview {
    PropertiesListView()
}