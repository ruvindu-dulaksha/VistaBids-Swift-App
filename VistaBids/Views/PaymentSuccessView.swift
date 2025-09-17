//
//  PaymentSuccessView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-20.
//

import SwiftUI

struct PaymentSuccessView: View {
    let property: AuctionProperty
    @Binding var showPaymentSuccess: Bool
    @Binding var showPaymentView: Bool
    @Binding var showOTPView: Bool
    let onDismiss: (() -> Void)?
    @State private var showConfetti = false
    @State private var animateSuccess = false
    @State private var showTranslationView = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var translationManager: TranslationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                
                LinearGradient(
                    colors: [
                        Color.backgrounds,
                        Color.accentBlues.opacity(0.1),
                        Color.green.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    
                    VStack(spacing: 24) {
                        ZStack {
                            
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 140, height: 140)
                                .scaleEffect(animateSuccess ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateSuccess)
                            
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .scaleEffect(animateSuccess ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateSuccess)
                            
                            // Main success circle
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 50, weight: .bold))
                                        .foregroundColor(.white)
                                        .scaleEffect(animateSuccess ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.6), value: animateSuccess)
                                )
                        }
                        
                        VStack(spacing: 12) {
                            Text("🎉 Payment Successful! 🎉")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            Text("Congratulations on your purchase!")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                            
                            Text("Your property purchase has been confirmed")
                                .font(.subheadline)
                                .foregroundColor(.secondaryTextColor)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    
                    VStack(spacing: 20) {
                        
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.lightGray.opacity(0.3))
                                    .frame(height: 140)
                                
                                if let firstImage = property.images.first, !firstImage.isEmpty {
                                    AsyncImage(url: URL(string: firstImage)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 140)
                                                .clipped()
                                        case .failure(_):
                                            VStack(spacing: 8) {
                                                Image(systemName: "house.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundStyle(
                                                        LinearGradient(
                                                            colors: [Color.accentBlues, Color.accentBlues.opacity(0.7)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                
                                                VStack(spacing: 4) {
                                                    Text("Property Purchased")
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.textPrimary)
                                                    
                                                    Text("Image will load shortly")
                                                        .font(.caption)
                                                        .foregroundColor(.secondaryTextColor)
                                                }
                                            }
                                            .frame(height: 140)
                                            .frame(maxWidth: .infinity)
                                        case .empty:
                                            VStack(spacing: 8) {
                                                ProgressView()
                                                    .scaleEffect(1.2)
                                                    .tint(.accentBlues)
                                                
                                                Text("Loading property image...")
                                                    .font(.caption)
                                                    .foregroundColor(.secondaryTextColor)
                                            }
                                            .frame(height: 140)
                                            .frame(maxWidth: .infinity)
                                        @unknown default:
                                            VStack(spacing: 8) {
                                                Image(systemName: "house.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.accentBlues)
                                                
                                                Text("Your Property")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.textPrimary)
                                            }
                                            .frame(height: 140)
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "house.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color.accentBlues, Color.accentBlues.opacity(0.7)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        VStack(spacing: 4) {
                                            Text("Property Purchased")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.textPrimary)
                                            
                                            Text("Congratulations on your purchase!")
                                                .font(.caption)
                                                .foregroundColor(.secondaryTextColor)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    .frame(height: 140)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            
                            VStack(spacing: 8) {
                                Text(property.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.accentBlues)
                                        .font(.caption)
                                    Text(property.address.city + ", " + property.address.state)
                                        .font(.subheadline)
                                        .foregroundColor(.secondaryTextColor)
                                }
                            }
                        }
                        
                        
                        VStack(spacing: 12) {
                            Text("Payment Summary")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            
                            VStack(spacing: 8) {
                                PaymentSummaryRow(
                                    label: "Final Price",
                                    value: "$\(Int(property.finalPrice ?? property.currentBid))",
                                    isHighlighted: true
                                )
                                
                                PaymentSummaryRow(
                                    label: "Transaction ID",
                                    value: generateTransactionID(),
                                    isHighlighted: false
                                )
                                
                                PaymentSummaryRow(
                                    label: "Date & Time",
                                    value: Date().formatted(date: .abbreviated, time: .shortened),
                                    isHighlighted: false
                                )
                                
                                PaymentSummaryRow(
                                    label: "Status",
                                    value: "Completed",
                                    isHighlighted: false,
                                    statusColor: .green
                                )
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.accentBlues.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    
                    
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundColor(.accentBlues)
                                .font(.title3)
                            Text("What's Next?")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            NextStepItem(
                                icon: "doc.text.fill",
                                text: "Property transfer documents will be sent to your email",
                                color: .accentBlues
                            )
                            
                            NextStepItem(
                                icon: "phone.fill",
                                text: "Our team will contact you within 24 hours",
                                color: .green
                            )
                            
                            NextStepItem(
                                icon: "key.fill",
                                text: "Property handover will be scheduled",
                                color: .orange
                            )
                            
                            NextStepItem(
                                icon: "bell.fill",
                                text: "You'll receive updates via notifications",
                                color: .purple
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.accentBlues.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.accentBlues.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    Spacer(minLength: 20)
                    
                    
                    VStack(spacing: 12) {
                        // Main continue button
                        Button(action: {
                            updateUserProfile()
                            showPaymentSuccess = false
                            showOTPView = false
                            showPaymentView = false
                            
                            
                            onDismiss?()
                            
                            // Also dismiss this view
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "house.fill")
                                    .font(.headline)
                                Text("Continue to Dashboard")
                                    .fontWeight(.semibold)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentBlues, Color.accentBlues.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .shadow(color: Color.accentBlues.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        // Secondary action button
                        Button(action: {
                            // Action for viewing transaction details
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .font(.subheadline)
                                Text("View Transaction Details")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.clear)
                            .foregroundColor(.accentBlues)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.accentBlues, lineWidth: 1.5)
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Payment Successful")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                TranslationButton(
                    sourceLanguage: "en",
                    contentId: "payment-success-\(property.id)",
                    isCompact: true
                )
            }
        }
        .sheet(isPresented: $showTranslationView) {
            TranslationView()
                .environmentObject(translationManager)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateSuccess = true
            }
        }
    }
    }
    
    private func generateTransactionID() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "VB\(timestamp)"
    }
    
    private func updateUserProfile() {
        
        UserProfileService.shared.addPurchaseHistory(property: property)
    }
}


struct PaymentSummaryRow: View {
    let label: String
    let value: String
    let isHighlighted: Bool
    var statusColor: Color = .textPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .font(isHighlighted ? .subheadline : .caption)
                .fontWeight(isHighlighted ? .semibold : .medium)
                .foregroundColor(.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(isHighlighted ? .headline : .caption)
                .fontWeight(isHighlighted ? .bold : .medium)
                .foregroundColor(isHighlighted ? .green : statusColor)
        }
        .padding(.vertical, isHighlighted ? 8 : 4)
        .padding(.horizontal, isHighlighted ? 16 : 8)
        .background(
            isHighlighted ? 
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1)) : 
            nil
        )
    }
}


struct NextStepItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PaymentSuccessView(
        property: AuctionProperty.mockProperty(),
        showPaymentSuccess: .constant(true),
        showPaymentView: .constant(true),
        showOTPView: .constant(true),
        onDismiss: nil
    )
    .environmentObject(TranslationManager.shared)
}
