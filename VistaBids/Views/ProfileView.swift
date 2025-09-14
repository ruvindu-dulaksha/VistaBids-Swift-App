import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject private var authService: APIService
    @State private var showingSettings = false
    @StateObject private var biddingService = BiddingService()
    @StateObject private var paymentService = PaymentService()
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pendingPayments: [PaymentReminder] = []
    @State private var showingPaymentHistory = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = authService.currentUser {
                        HStack {
                            if let photoURL = user.photoURL {
                                AsyncImage(url: photoURL) { image in
                                    image.resizable()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            }
                            
                            VStack(alignment: .leading) {
                                Text(user.displayName ?? "User")
                                    .font(.headline)
                                Text(user.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Payment Alerts Section
                if !pendingPayments.isEmpty {
                    Section("Payment Required") {
                        ForEach(pendingPayments, id: \.auctionId) { payment in
                            PaymentAlertCard(payment: payment) {
                                loadPendingPayments()
                            }
                        }
                    }
                    .headerProminence(.increased)
                }
                
                Section("Activity") {
                    NavigationLink(destination: EnhancedUserActivityView()) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.accentBlues)
                            Text("Your Activity")
                        }
                    }
                    
                    NavigationLink(destination: PaymentHistoryView(paymentService: paymentService)) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Payment History")
                                Text("View all transactions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: Text("Your Properties")) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.green)
                            Text("Your Properties")
                        }
                    }
                    
                    NavigationLink(destination: Text("Favorites")) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Favorites")
                        }
                    }
                }
                
                Section("Account") {
                    NavigationLink("Settings") {
                        SettingsView()
                    }
                    
                    Button(role: .destructive) {
                        try? authService.signOut()
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                loadPendingPayments()
                schedulePaymentReminders()
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    private func loadPendingPayments() {
        Task {
            pendingPayments = await paymentService.getPendingPaymentReminders()
        }
    }
    
    private func schedulePaymentReminders() {
        Task {
            await notificationManager.schedulePaymentReminders()
        }
    }
    
    @MainActor
    private func refreshData() async {
        pendingPayments = await paymentService.getPendingPaymentReminders()
        await notificationManager.schedulePaymentReminders()
    }
}

#Preview {
    ProfileView()
        .environmentObject(APIService())
}