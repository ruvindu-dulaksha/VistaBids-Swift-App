//
//  BidWinnerNotificationView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-09-12.
//

import SwiftUI

struct BidWinnerNotificationView: View {
    let property: AuctionProperty
    @Binding var showNotification: Bool
    @State private var showPaymentView = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showNotification = false
                    }
                }
            
            // Notification card
            VStack(spacing: 20) {
                // Celebration animation
                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: showNotification)
                    
                    Text("🎉 Congratulations! 🎉")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("You won the bid!")
                        .font(.headline)
                        .foregroundColor(.accentBlues)
                }
                
                // Property details
                VStack(spacing: 8) {
                    AsyncImage(url: URL(string: property.images.first ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 120, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text(property.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Winning Bid: $\(Int(property.finalPrice ?? property.currentBid))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Divider()
                
                // Action message
                VStack(spacing: 8) {
                    Text("Please proceed to payment")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Complete your payment within 24 hours to secure your property")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Later") {
                        withAnimation {
                            showNotification = false
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.secondary)
                    .cornerRadius(8)
                    
                    Button("Pay Now") {
                        print("💳 Pay Now button tapped!")
                        print("💳 Before: showPaymentView = \(showPaymentView)")
                        showPaymentView = true
                        print("💳 After: showPaymentView = \(showPaymentView)")
                        print("💳 NOT dismissing notification yet - letting PaymentView handle it")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentBlues)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .fontWeight(.semibold)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 32)
            .scaleEffect(showNotification ? 1.0 : 0.8)
            .opacity(showNotification ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showNotification)
        }
        .fullScreenCover(isPresented: $showPaymentView, onDismiss: {
            // When PaymentView is dismissed, also dismiss the notification
            showNotification = false
        }) {
            PaymentView(property: property, showPaymentView: $showPaymentView)
        }
    }
}

#Preview {
    BidWinnerNotificationView(
        property: AuctionProperty.mockProperty(),
        showNotification: .constant(true)
    )
}
