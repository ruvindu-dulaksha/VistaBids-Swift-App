import SwiftUI
import MapKit
import FirebaseAuth

struct EnhancedBiddingView: View {
    let property: AuctionProperty
    @StateObject private var biddingService = BiddingService()
    @StateObject private var timerService = AuctionTimerService()
    @StateObject private var paymentService = PaymentService()
    @State private var bidAmount: String = ""
    @State private var showBidConfirmation = false
    @State private var showBidSuccess = false
    @State private var showPaymentView = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var isInWatchlist = false
    @State private var showWinnerDialog = false
    @State private var timeRemaining: String = ""
    @State private var auctionProgress: Double = 0.0
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private var isWinner: Bool {
        property.winnerId == currentUserId && property.status == .ended
    }
    
    private var canBid: Bool {
        
        // biddingService.canPlaceBid(on: property)
        property.status == .active
    }
    
    private var minimumBidAmount: Double {
         
        // biddingService.getMinimumBidAmount(for: property)
        property.currentBid + 100
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with timer and status
                auctionHeaderView
                
                // Property images carousel
                propertyImageCarousel
                
                // Property details
                propertyDetailsView
                
                // Current bid information
                currentBidView
                
                // Auction timer and progress
                auctionTimerView
                
                // Bidding section
                if canBid {
                    biddingSection
                } else if isWinner {
                    winnerSection
                } else if property.status == .ended {
                    auctionEndedSection
                } else {
                    upcomingAuctionSection
                }
                
                // Action buttons
                actionButtonsView
                
                // Bid history
                bidHistoryView
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleWatchlist) {
                    Image(systemName: isInWatchlist ? "heart.fill" : "heart")
                        .foregroundColor(isInWatchlist ? .red : .gray)
                }
            }
        }
        .onAppear {
            setupAuctionMonitoring()
        }
       
        // .onReceive(timerService.$properties) { properties in
        //     if let updatedProperty = properties.first(where: { $0.id == property.id }) {
        //         updateTimeRemaining(for: updatedProperty)
        //     }
        // }
        .sheet(isPresented: $showPaymentView) {
            PaymentView(
                property: property,
                showPaymentView: $showPaymentView
            )
        }
        .alert("Auction Winner! 🎉", isPresented: $showWinnerDialog) {
            Button("Make Payment") {
                showPaymentView = true
            }
            Button("Later") { }
        } message: {
            Text("Congratulations! You won the auction for \(property.title) with a bid of $\(property.currentBid, specifier: "%.2f"). Complete payment within 24 hours.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // Auction Header
    private var auctionHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(property.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(property.address.street), \(property.address.city)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                AuctionStatusBadge(status: property.status)
            }
            
            // Auction duration info
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("Duration: \(property.auctionDuration.displayText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    //Property Images
    private var propertyImageCarousel: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(0..<property.images.count, id: \.self) { index in
                AsyncImage(url: URL(string: property.images[index])) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 250)
                .clipped()
                .cornerRadius(12)
                .tag(index)
                .onTapGesture {
                    showImageViewer = true
                }
            }
        }
        .frame(height: 250)
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
    
    // Property Details
    private var propertyDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Property Details")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                PropertyDetailCard(
                    icon: "bed.double",
                    title: "Bedrooms",
                    value: "\(property.features.bedrooms)"
                )
                
                PropertyDetailCard(
                    icon: "bathtub",
                    title: "Bathrooms",
                    value: "\(property.features.bathrooms)"
                )
                
                PropertyDetailCard(
                    icon: "square",
                    title: "Area",
                    value: String(format: "%.0f sq ft", property.features.area)
                )
                
                PropertyDetailCard(
                    icon: "car",
                    title: "Parking",
                    value: "\(property.features.parkingSpaces ?? 0)"
                )
            }
            
            if !property.description.isEmpty {
                Text("Description")
                    .font(.headline)
                    .padding(.top)
                
                Text(property.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Current Bid View
    private var currentBidView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Current Bid")
                    .font(.headline)
                Spacer()
                Text("$\(property.currentBid, specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            if let highestBidderName = property.highestBidderName {
                HStack {
                    Text("Highest Bidder:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(highestBidderName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                Text("Starting Price:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(property.startingPrice, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Auction Timer
    private var auctionTimerView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                Text("Time Remaining")
                    .font(.headline)
                Spacer()
            }
            
            Text(timeRemaining)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(getTimerColor())
                .multilineTextAlignment(.center)
            
            // Progress bar
            ProgressView(value: auctionProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: getTimerColor()))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("Started: \(property.auctionStartTime, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Ends: \(property.auctionEndTime, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Bidding Section
    private var biddingSection: some View {
        VStack(spacing: 16) {
            Text("Place Your Bid")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Minimum bid: $\(minimumBidAmount, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("$")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    TextField("Enter bid amount", text: $bidAmount)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            Button(action: placeBid) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "hammer")
                        Text("Place Bid")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isValidBid ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isValidBid || isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Winner Section
    private var winnerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            
            Text("🎉 Congratulations!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("You won this auction!")
                .font(.headline)
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Winning Amount")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("$\(property.finalPrice ?? property.currentBid, specifier: "%.2f")")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            if property.paymentStatus == .pending {
                VStack(spacing: 12) {
                    Text("⏰ Payment due within 24 hours")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Button(action: { showPaymentView = true }) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Complete Payment")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
            } else if property.paymentStatus == .completed {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Payment Completed")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Auction Ended Section
    private var auctionEndedSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("Auction Ended")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            if let winnerName = property.winnerName {
                VStack(spacing: 8) {
                    Text("Winner")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(winnerName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Winning Bid: $\(property.finalPrice ?? property.currentBid, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else {
                Text("No winner - Auction ended without bids")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    //  Upcoming Auction Section
    private var upcomingAuctionSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("Auction Not Started")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("Starts in:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(timeUntilStart)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Action Buttons
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            Button(action: shareProperty) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: contactSeller) {
                HStack {
                    Image(systemName: "phone")
                    Text("Contact")
                }
                .font(.subheadline)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    //  Bid History
    private var bidHistoryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bid History")
                .font(.headline)
            
            if property.bidHistory.isEmpty {
                Text("No bids yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(property.bidHistory.prefix(5), id: \.id) { bid in
                    BidHistoryRow(bid: bid)
                }
                
                if property.bidHistory.count > 5 {
                    Text("+ \(property.bidHistory.count - 5) more bids")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Computed Properties
    private var isValidBid: Bool {
        guard let amount = Double(bidAmount) else { return false }
        return amount >= minimumBidAmount
    }
    
    private var timeUntilStart: String {
        let interval = property.auctionStartTime.timeIntervalSince(Date())
        return interval > 0 ? formatTimeInterval(interval) : "Started"
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    private func setupAuctionMonitoring() {
        biddingService.startListeningToAuctionUpdates(for: property.id ?? "")
        timerService.startAuctionTimer(for: property)
        updateTimeRemaining(for: property)
        updateAuctionProgress()
        
        // Check if user is in watchlist
        isInWatchlist = property.watchlistUsers.contains(currentUserId ?? "")
        
        // Show winner dialog if user just won
        if isWinner && property.paymentStatus == .pending {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showWinnerDialog = true
            }
        }
    }
    
    private func updateTimeRemaining(for property: AuctionProperty) {
        timeRemaining = timerService.getTimeRemainingText(for: property.id ?? "")
        updateAuctionProgress()
    }
    
    private func updateAuctionProgress() {
        let totalDuration = property.auctionEndTime.timeIntervalSince(property.auctionStartTime)
        let elapsed = Date().timeIntervalSince(property.auctionStartTime)
        auctionProgress = min(max(elapsed / totalDuration, 0), 1)
    }
    
    private func getTimerColor() -> Color {
        let remaining = property.auctionEndTime.timeIntervalSince(Date())
        if remaining < 300 { // Less than 5 minutes
            return .red
        } else if remaining < 900 { // Less than 15 minutes
            return .orange
        } else {
            return .blue
        }
    }
    
    private func placeBid() {
        guard let amount = Double(bidAmount) else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await biddingService.placeBid(on: property.id ?? "", amount: amount, maxAutoBid: nil)
                await MainActor.run {
                    bidAmount = ""
                    showBidSuccess = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func toggleWatchlist() {
        Task {
            do {
                if isInWatchlist {
                    try await biddingService.removeFromWatchlist(propertyId: property.id ?? "")
                } else {
                    try await biddingService.addToWatchlist(propertyId: property.id ?? "")
                }
                await MainActor.run {
                    isInWatchlist.toggle()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handlePaymentComplete() {
        showPaymentView = false
        // Refresh property data to show updated payment status
        Task {
            
        }
    }
    
    private func shareProperty() {
        // Implement share functionality
        print("Sharing property: \(property.title)")
    }
    
    private func contactSeller() {
        // Implement contact seller functionality
        print("Contacting seller: \(property.sellerName)")
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let days = Int(interval) / 86400
        let hours = Int(interval.truncatingRemainder(dividingBy: 86400)) / 3600
        let minutes = Int(interval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// Supporting Views

struct AuctionStatusBadge: View {
    let status: AuctionStatus
    
    var body: some View {
        Text(status.displayText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(16)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .upcoming:
            return .blue
        case .active:
            return .green
        case .ended:
            return .gray
        case .sold:
            return .orange
        case .cancelled:
            return .red
        }
    }
}

struct PropertyDetailCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BidHistoryRow: View {
    let bid: BidEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bid.bidderName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(bid.timestamp, formatter: timeFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("$\(bid.amount, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
}

#Preview {
    NavigationView {
        EnhancedBiddingView(
            property: AuctionProperty.mockProperty()
        )
    }
}
