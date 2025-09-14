import SwiftUI

struct PaymentAlertCard: View {
    let payment: PaymentReminder
    let onPaymentComplete: () -> Void
    @StateObject private var paymentService = PaymentService()
    @State private var showingPayment = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Payment Required")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Please complete your payment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time remaining badge
                TimeRemainingBadge(deadline: payment.deadline)
            }
            
            // Property info
            HStack {
                AsyncImage(url: URL(string: payment.propertyImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "house.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 45)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(payment.propertyTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    Text("\(payment.amount, specifier: "%.2f") \(payment.currency)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            // Action button
            Button(action: {
                showingPayment = true
            }) {
                HStack {
                    Image(systemName: "creditcard.fill")
                    Text("Pay Now")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingPayment) {
            NavigationView {
                VStack {
                    Text("Payment Required")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("Property: \(payment.propertyTitle)")
                        .font(.headline)
                        .padding()
                    
                    Text("Amount: \(payment.amount, specifier: "%.2f") \(payment.currency)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding()
                    
                    Spacer()
                    
                    Button("Complete Payment") {
                        onPaymentComplete()
                        showingPayment = false
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
                }
                .navigationTitle("Payment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showingPayment = false
                        }
                    }
                }
            }
        }
    }
}

struct TimeRemainingBadge: View {
    let deadline: Date
    @State private var timeRemaining: String = ""
    
    var body: some View {
        Text(timeRemaining)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(timeColor.opacity(0.2))
            )
            .foregroundColor(timeColor)
            .onAppear {
                updateTimeRemaining()
                Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                    updateTimeRemaining()
                }
            }
    }
    
    private var timeColor: Color {
        let hoursRemaining = Calendar.current.dateComponents([.hour], from: Date(), to: deadline).hour ?? 0
        
        if hoursRemaining <= 2 {
            return .red
        } else if hoursRemaining <= 12 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func updateTimeRemaining() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date(), to: deadline)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if hours > 0 {
            timeRemaining = "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            timeRemaining = "\(minutes)m"
        } else {
            timeRemaining = "OVERDUE"
        }
    }
}

#Preview {
    PaymentAlertCard(
        payment: PaymentReminder(
            auctionId: "123",
            propertyTitle: "Beautiful Villa in Beverly Hills",
            propertyImageURL: "https://example.com/image.jpg",
            amount: 125000.0,
            currency: "USD",
            deadline: Date().addingTimeInterval(7200) // 2 hours from now
        ),
        onPaymentComplete: {}
    )
    .padding()
}
