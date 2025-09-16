//
//  TransactionHistoryView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on  2025-08-21.
//

import SwiftUI

struct TransactionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userStatsService: UserStatsService
    @State private var selectedFilter: TransactionFilter = .all
    @State private var showingFilterSheet = false
    
    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case purchase = "Purchases"
        case sale = "Sales"
        case bid = "Bids"
        case refund = "Refunds"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .purchase: return "cart.fill"
            case .sale: return "dollarsign.circle.fill"
            case .bid: return "hand.raised.fill"
            case .refund: return "arrow.clockwise.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Cards
                if !userStatsService.transactionHistory.isEmpty {
                    TransactionSummaryView(transactions: userStatsService.transactionHistory)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                
                // Filter Bar
                HStack {
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: selectedFilter.icon)
                            Text(selectedFilter.rawValue)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accentBlues)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentBlues, lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        userStatsService.loadUserStats()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(.accentBlues)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Transactions List
                if userStatsService.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading transactions...")
                        Spacer()
                    }
                } else if filteredTransactions.isEmpty {
                    EmptyTransactionsView(filter: selectedFilter)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                                TransactionDateSection(
                                    date: date,
                                    transactions: groupedTransactions[date] ?? []
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Transaction History")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSelectionView(selectedFilter: $selectedFilter)
            }
            .onAppear {
                userStatsService.loadUserStats()
            }
        }
    }
    
    private var filteredTransactions: [TransactionRecord] {
        switch selectedFilter {
        case .all:
            return userStatsService.transactionHistory
        case .purchase:
            return userStatsService.transactionHistory.filter { $0.type == .purchase }
        case .sale:
            return userStatsService.transactionHistory.filter { $0.type == .sale }
        case .bid:
            return userStatsService.transactionHistory.filter { $0.type == .bid }
        case .refund:
            return userStatsService.transactionHistory.filter { $0.type == .refund }
        }
    }
    
    private var groupedTransactions: [String: [TransactionRecord]] {
        Dictionary(grouping: filteredTransactions) { transaction in
            formatDateGroup(transaction.timestamp.dateValue())
        }
    }
    
    private func formatDateGroup(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return "This Week"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

struct TransactionSummaryView: View {
    let transactions: [TransactionRecord]
    
    var totalSpent: Double {
        transactions.filter { $0.type == .purchase }.reduce(0) { $0 + $1.amount }
    }
    
    var totalEarned: Double {
        transactions.filter { $0.type == .sale }.reduce(0) { $0 + $1.amount }
    }
    
    var totalBids: Int {
        transactions.filter { $0.type == .bid }.count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Total Spent",
                value: "$\(Int(totalSpent))",
                icon: "cart.fill",
                color: .red
            )
            
            SummaryCard(
                title: "Total Earned",
                value: "$\(Int(totalEarned))",
                icon: "dollarsign.circle.fill",
                color: .green
            )
            
            SummaryCard(
                title: "Total Bids",
                value: "\(totalBids)",
                icon: "hand.raised.fill",
                color: .blue
            )
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct TransactionDateSection: View {
    let date: String
    let transactions: [TransactionRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.leading, 4)
            
            ForEach(transactions) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: TransactionRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // Transaction Icon
            Image(systemName: transaction.type.icon)
                .font(.title3)
                .foregroundColor(transaction.type.color)
                .frame(width: 24, height: 24)
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.propertyTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(transaction.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    TransactionStatusBadge(status: transaction.status)
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(transaction.amount, type: transaction.type))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(amountColor(for: transaction.type))
                
                Text(formatTime(transaction.timestamp.dateValue()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatAmount(_ amount: Double, type: TransactionRecord.TransactionType) -> String {
        let prefix = (type == .purchase || type == .bid) ? "-" : "+"
        return "\(prefix)$\(Int(amount))"
    }
    
    private func amountColor(for type: TransactionRecord.TransactionType) -> Color {
        switch type {
        case .purchase, .bid:
            return .red
        case .sale, .refund:
            return .green
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension TransactionRecord.TransactionType {
    var icon: String {
        switch self {
        case .purchase: return "cart.fill"
        case .sale: return "dollarsign.circle.fill"
        case .bid: return "hand.raised.fill"
        case .refund: return "arrow.clockwise.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .purchase: return .red
        case .sale: return .green
        case .bid: return .blue
        case .refund: return .orange
        }
    }
    
    var displayName: String {
        switch self {
        case .purchase: return "Purchase"
        case .sale: return "Sale"
        case .bid: return "Bid"
        case .refund: return "Refund"
        }
    }
}

struct FilterSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilter: TransactionHistoryView.TransactionFilter
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ForEach(TransactionHistoryView.TransactionFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: filter.icon)
                                .font(.title3)
                                .foregroundColor(.accentBlues)
                                .frame(width: 24)
                            
                            Text(filter.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .font(.headline)
                                    .foregroundColor(.accentBlues)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if filter != TransactionHistoryView.TransactionFilter.allCases.last {
                        Divider()
                            .padding(.leading, 64)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Filter Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct EmptyTransactionsView: View {
    let filter: TransactionHistoryView.TransactionFilter
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: filter.icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No \(filter.rawValue)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgrounds)
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all:
            return "You haven't made any transactions yet. Start exploring properties to begin your journey!"
        case .purchase:
            return "You haven't purchased any properties yet. Find your dream property and make an offer!"
        case .sale:
            return "You haven't sold any properties yet. List your properties to start earning!"
        case .bid:
            return "You haven't placed any bids yet. Join auctions and start bidding!"
        case .refund:
            return "You don't have any refunds. This is actually a good thing!"
        }
    }
}

// MARK: - Transaction Status Badge
struct TransactionStatusBadge: View {
    let status: TransactionRecord.TransactionStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .completed:
            return .green
        case .pending:
            return .orange
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
}

#Preview {
    TransactionHistoryView()
        .environmentObject(UserStatsService.shared)
}
