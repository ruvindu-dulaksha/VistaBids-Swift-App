import SwiftUI

struct BidRowView: View {
    let bid: Bid
    @State private var property: AuctionProperty?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let property = property {
                    Text(property.title)
                        .font(.headline)
                } else {
                    Text("Loading property...")
                        .font(.headline)
                        .redacted(reason: .placeholder)
                }
                
                Text(bid.formattedAmount)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                
                Text(bid.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let property = property {
                if Date() < property.auctionEndTime {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            loadProperty()
        }
    }
    
    private func loadProperty() {
       
    }
}