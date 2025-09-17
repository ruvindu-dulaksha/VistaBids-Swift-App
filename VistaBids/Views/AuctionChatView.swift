//
//  AuctionChatView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-16.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AuctionChatView: View {
    let property: AuctionProperty
    let biddingService: BiddingService
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [AuctionChatMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                // Chat Header
                chatHeader
                
                // Messages List
                messagesView
                
                // Message Input
                messageInput
            }
            .navigationTitle("Auction Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadMessages()
                setupRealTimeListener()
            }
        }
    }
    
    private var chatHeader: some View {
        VStack(spacing: 8) {
            HStack {
                AsyncImage(url: URL(string: property.images.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipped()
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(property.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    Text(String(format: "Current Bid: $%.0f", property.currentBid))
                        .font(.caption)
                        .foregroundColor(.accentBlues)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(property.status.displayText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(property.status.color)
                        .cornerRadius(4)
                    
                    if property.status == .active {
                        Text("Ends \(property.auctionEndTime, style: .timer)")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            
            // Chat Notice
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                
                Text("This chat will be removed when the auction ends")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color.backgroundPrimary)
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isLoading {
                        loadingView
                    } else if messages.isEmpty {
                        emptyMessagesView
                    } else {
                        messagesList
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var messageInput: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $newMessage, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(newMessage.isEmpty ? Color.gray : Color.accentBlues)
                    .clipShape(Circle())
            }
            .disabled(newMessage.isEmpty)
        }
        .padding()
        .background(Color.backgroundPrimary)
    }
    
    private func loadMessages() {
        Task {
            do {
                let chatMessages = try await biddingService.getChatMessages(for: property.id ?? "")
                await MainActor.run {
                    messages = chatMessages.sorted { $0.timestamp < $1.timestamp }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func setupRealTimeListener() {
        // Setup real-time listener for new messages
        Task {
            await biddingService.listenToChatMessages(propertyId: property.id ?? "") { newMessages in
                DispatchQueue.main.async {
                    messages = newMessages.sorted { $0.timestamp < $1.timestamp }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        newMessage = ""
        
        Task {
            do {
                // First get the chat room for this property
                let chatRoom = await biddingService.getAuctionChatRoom(for: property.id ?? "")
                let chatRoomId = chatRoom?.id ?? ""
                
                let message = AuctionChatMessage(
                    id: UUID().uuidString,
                    senderID: biddingService.currentUserId,
                    senderName: biddingService.currentUserName,
                    message: messageText,
                    timestamp: Date(),
                    messageType: .text
                )
                
                try await biddingService.sendChatMessage(message: message)
            } catch {
                // Handle error
                print("Failed to send message: \(error)")
            }
        }
    }
    
    
    private var loadingView: some View {
        ProgressView("Loading messages...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyMessagesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No messages yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Be the first to start the conversation about this property")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var messagesList: some View {
        ForEach(messages) { message in
            MessageRow(
                message: message,
                isCurrentUser: message.senderID == biddingService.currentUserId
            )
            .id(message.id)
        }
    }
}

struct MessageRow: View {
    let message: AuctionChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
                messageContent
                    .background(Color.accentBlues)
                    .foregroundColor(.white)
            } else {
                messageContent
                    .background(Color.cardBackground)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
        }
    }
    
    private var messageContent: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            if !isCurrentUser {
                Text(message.senderName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentUser ? .white.opacity(0.8) : .accentBlues)
            }
            
            Text(message.message)
                .font(.body)
                .multilineTextAlignment(isCurrentUser ? .trailing : .leading)
            
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(isCurrentUser ? .white.opacity(0.7) : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .cornerRadius(16)
    }
}

#Preview {
    AuctionChatView(
        property: AuctionProperty(
            sellerId: "seller1",
            sellerName: "John Doe",
            title: "Modern Villa",
            description: "Beautiful modern villa with stunning views.",
            startingPrice: 500000,
            currentBid: 550000,
            highestBidderId: "bidder1",
            highestBidderName: "Jane Smith",
            images: [],
            videos: [],
            arModelURL: nil,
            address: PropertyAddress(
                street: "123 Main Street",
                city: "Colombo",
                state: "Western Province",
                postalCode: "00100",
                country: "Sri Lanka"
            ),
            location: GeoPoint(latitude: 6.9271, longitude: 79.8612),
            features: PropertyFeatures(
                bedrooms: 4,
                bathrooms: 3,
                area: 2500,
                yearBuilt: 2020,
                parkingSpaces: 2,
                hasGarden: true,
                hasPool: true,
                hasGym: false,
                floorNumber: nil,
                totalFloors: nil,
                propertyType: "Villa"
            ),
            auctionStartTime: Date().addingTimeInterval(-3600),
            auctionEndTime: Date().addingTimeInterval(7200),
            auctionDuration: .oneHour,
            status: .active,
            category: .luxury,
            bidHistory: [],
            watchlistUsers: [],
            createdAt: Date(),
            updatedAt: Date(),
            panoramicImages: [],
            walkthroughVideoURL: nil
        ),
        biddingService: BiddingService()
    )
}
