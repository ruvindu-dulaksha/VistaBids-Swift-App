import SwiftUI

struct PaymentHistoryView: View {
    @ObservedObject var paymentService: PaymentService
    @State private var transactionHistory: [TransactionHistory] = []
    @State private var isLoading = true
    @State private var selectedFilter: TransactionFilter = .all
    @Environment(\.dismiss) private var dismiss
    
    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case completed = "Completed"
        case pending = "Pending"
        case failed = "Failed"
        case refunded = "Refunded"
    }
    
    var filteredTransactions: [TransactionHistory] {
        switch selectedFilter {
        case .all:
            return transactionHistory
        case .completed:
            return transactionHistory.filter { $0.status == .completed }
        case .pending:
            return transactionHistory.filter { $0.status == .pending }
        case .failed:
            return transactionHistory.filter { $0.status == .failed }
        case .refunded:
            return transactionHistory.filter { $0.status == .refunded }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                if isLoading {
                    Spacer()
                    ProgressView("Loading payment history...")
                    Spacer()
                } else if filteredTransactions.isEmpty {
                    EmptyHistoryView(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredTransactions, id: \.id) { transaction in
                            PaymentTransactionCard(transaction: transaction)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Payment History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadTransactionHistory()
            }
            .refreshable {
                await refreshHistory()
            }
        }
    }
    
    private func loadTransactionHistory() {
        Task {
            isLoading = true
            transactionHistory = await paymentService.getTransactionHistory()
            isLoading = false
        }
    }
    
    @MainActor
    private func refreshHistory() async {
        transactionHistory = await paymentService.getTransactionHistory()
    }
}

struct PaymentTransactionCard: View {
    let transaction: TransactionHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.propertyTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                PaymentStatusBadge(status: transaction.status)
            }
            
            // Amount and details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(transaction.amount, specifier: "%.2f") \(transaction.currency)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(amountColor)
                    
                    if let fees = transaction.fees, fees > 0 {
                        Text("Fees: \(fees, specifier: "%.2f") \(transaction.currency)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let method = transaction.paymentMethod {
                    PaymentMethodIcon(method: method)
                }
            }
            
            // Transaction ID
            if !transaction.transactionId.isEmpty {
                HStack {
                    Text("Transaction ID:")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                    Text(transaction.transactionId)
                        .font(.caption)
                        .monospaced()
                        .foregroundColor(Color.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .payment:
            return .primary
        case .refund:
            return .green
        case .auctionWin:
            return .blue
        }
    }
}

struct PaymentStatusBadge: View {
    let status: TransactionStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
            .foregroundColor(textColor)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .completed:
            return .green.opacity(0.2)
        case .pending:
            return .orange.opacity(0.2)
        case .failed:
            return .red.opacity(0.2)
        case .refunded:
            return .blue.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch status {
        case .completed:
            return .green
        case .pending:
            return .orange
        case .failed:
            return .red
        case .refunded:
            return .blue
        }
    }
}

struct PaymentMethodIcon: View {
    let method: PaymentMethod
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundColor(.secondary)
            Text(method.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var iconName: String {
        switch method {
        case .creditCard:
            return "creditcard.fill"
        case .debitCard:
            return "creditcard"
        case .bankTransfer:
            return "building.columns.fill"
        case .digitalWallet:
            return "wallet.pass.fill"
        }
    }
}

struct EmptyHistoryView: View {
    let filter: PaymentHistoryView.TransactionFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No \(filter.rawValue.lowercased()) transactions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Your transaction history will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PaymentHistoryView(paymentService: PaymentService())
}
