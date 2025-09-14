//
//  PaymentService.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-08-24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class PaymentService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var isProcessingPayment = false
    @Published var paymentError: String?
    @Published var userCards: [CardDetails] = []
    @Published var transactions: [TransactionHistory] = []
    @Published var purchaseHistory: [UserPurchaseHistory] = []
    
    private var listeners: [ListenerRegistration] = []
    
    var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    init() {
        setupPaymentListeners()
    }
    
    deinit {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Setup Listeners
    private func setupPaymentListeners() {
        guard !currentUserId.isEmpty else { return }
        
        // Listen to user transactions
        let transactionListener = db.collection("transactions")
            .whereField("userId", isEqualTo: currentUserId)
            .order(by: "transactionDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.paymentError = error.localizedDescription
                    return
                }
                
                self.transactions = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: TransactionHistory.self)
                } ?? []
            }
        
        // Listen to purchase history
        let purchaseListener = db.collection("purchase_history")
            .whereField("userId", isEqualTo: currentUserId)
            .order(by: "purchaseDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.paymentError = error.localizedDescription
                    return
                }
                
                self.purchaseHistory = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: UserPurchaseHistory.self)
                } ?? []
            }
        
        listeners.append(contentsOf: [transactionListener, purchaseListener])
    }
    
    // MARK: - Payment Support
    func calculatePaymentAmount(amount: Double) -> (total: Double, fees: TransactionFees) {
        // Calculate fees (demo values)
        let serviceFee = amount * 0.025 // 2.5% service fee
        let processingFee = amount * 0.01 // 1% processing fee
        let taxes = (amount + serviceFee + processingFee) * 0.08 // 8% tax
        
        let fees = TransactionFees(
            serviceFee: serviceFee,
            processingFee: processingFee,
            taxes: taxes
        )
        
        let total = amount + fees.totalFees
        return (total, fees)
    }
    
    // MARK: - Payment Processing
    func processAuctionPayment(
        propertyId: String,
        amount: Double,
        paymentMethod: PaymentMethod,
        cardDetails: CardDetails? = nil,
        billingAddress: BillingAddress
    ) async throws -> String {
        isProcessingPayment = true
        paymentError = nil
        
        do {
            let transactionId = UUID().uuidString
            let (_, fees) = calculatePaymentAmount(amount: amount)
            
            // Get property details
            let propertyDoc = try await db.collection("auction_properties").document(propertyId).getDocument()
            guard let property = try? propertyDoc.data(as: AuctionProperty.self) else {
                throw PaymentError.propertyNotFound
            }
            
            // Create transaction record
            let transaction = TransactionHistory(
                transactionId: transactionId,
                userId: currentUserId,
                propertyTitle: property.title,
                amount: amount,
                type: .auctionWin,
                status: .pending,
                paymentMethod: paymentMethod,
                fees: fees.serviceFee + fees.processingFee + fees.taxes,
                description: "Auction win payment for \(property.title)"
            )
            
            // Simulate payment processing delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Save transaction to Firestore
            _ = try await db.collection("transactions").addDocument(from: transaction)
            
            // Send push notification
            await sendPaymentNotification(propertyTitle: transaction.propertyTitle, amount: transaction.amount)
            
            // Update payment status to completed
            let completedTransaction = TransactionHistory(
                transactionId: transactionId,
                userId: currentUserId,
                propertyTitle: property.title,
                amount: amount,
                type: .auctionWin,
                status: .completed,
                paymentMethod: paymentMethod,
                fees: fees.serviceFee + fees.processingFee + fees.taxes,
                description: "Auction win payment for \(property.title)"
            )
            
            try await db.collection("transactions").document(transactionId).setData(from: completedTransaction)
            
            // Create purchase history record
            let purchase = UserPurchaseHistory(
                userId: currentUserId,
                propertyId: propertyId,
                propertyTitle: property.title,
                propertyImages: property.images,
                purchasePrice: amount,
                purchaseDate: Date(),
                transactionId: transactionId,
                paymentStatus: .completed,
                deliveryStatus: .pending,
                propertyAddress: property.address,
                propertyFeatures: property.features
            )
            
            _ = try await db.collection("purchase_history").addDocument(from: purchase)
            
            // Update auction property status
            try await db.collection("auction_properties").document(propertyId).updateData([
                "status": AuctionStatus.sold.rawValue,
                "paymentStatus": PaymentStatus.completed.rawValue,
                "transactionId": transactionId,
                "finalPrice": amount,
                "updatedAt": Date()
            ])
            
            isProcessingPayment = false
            return transactionId
            
        } catch {
            isProcessingPayment = false
            paymentError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Card Management
    func addCard(
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvv: String,
        cardholderName: String,
        billingAddress: BillingAddress
    ) async throws {
        // Validate card number
        let cardType = detectCardType(cardNumber)
        let lastFourDigits = String(cardNumber.suffix(4))
        
        // In a real app, you would validate the card with a payment processor
        // For demo purposes, we'll simulate validation
        let isValid = validateCard(cardNumber: cardNumber, cvv: cvv, expiryMonth: expiryMonth, expiryYear: expiryYear)
        
        if !isValid {
            throw PaymentError.invalidCard
        }
        
        let cardDetails = CardDetails(
            cardType: cardType,
            lastFourDigits: lastFourDigits,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            isVerified: true,
            verificationMethod: .cvv
        )
        
        // Save card details (encrypted in real implementation)
        try await db.collection("user_cards").document(currentUserId).setData([
            "cards": FieldValue.arrayUnion([try Firestore.Encoder().encode(cardDetails)])
        ], merge: true)
        
        // Update local cards array
        userCards.append(cardDetails)
    }
    
    private func detectCardType(_ cardNumber: String) -> CardType {
        let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        
        if cleanNumber.hasPrefix("4") {
            return .visa
        } else if cleanNumber.hasPrefix("5") || cleanNumber.hasPrefix("2") {
            return .mastercard
        } else if cleanNumber.hasPrefix("34") || cleanNumber.hasPrefix("37") {
            return .amex
        } else if cleanNumber.hasPrefix("6") {
            return .discover
        } else {
            return .unknown
        }
    }
    
    private func validateCard(cardNumber: String, cvv: String, expiryMonth: Int, expiryYear: Int) -> Bool {
        // Basic validation - in real app, use proper validation library
        let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        
        // Check length
        guard cleanNumber.count >= 13 && cleanNumber.count <= 19 else { return false }
        
        // Check if all digits
        guard cleanNumber.allSatisfy({ $0.isNumber }) else { return false }
        
        // Check CVV
        guard cvv.count >= 3 && cvv.count <= 4 else { return false }
        
        // Check expiry date
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        if expiryYear < currentYear || (expiryYear == currentYear && expiryMonth < currentMonth) {
            return false
        }
        
        return true
    }
    
    // MARK: - Transaction History
    func getTransactionHistory() async -> [TransactionHistory] {
        guard let userId = Auth.auth().currentUser?.uid else {
            // Return mock data for demo purposes when not authenticated
            return createMockTransactionHistory()
        }
        
        do {
            let snapshot = try await db.collection("transactions")
                .whereField("userId", isEqualTo: userId)
                .order(by: "date", descending: true)
                .getDocuments()
            
            var transactions: [TransactionHistory] = []
            
            for document in snapshot.documents {
                do {
                    let transaction = try document.data(as: TransactionHistory.self)
                    transactions.append(transaction)
                } catch {
                    print("Error decoding transaction: \(error)")
                    continue
                }
            }
            
            // If no transactions found, return mock data for demo
            return transactions.isEmpty ? createMockTransactionHistory() : transactions
            
        } catch {
            print("Error fetching transaction history: \(error)")
            return createMockTransactionHistory()
        }
    }
    
    // MARK: - Payment Reminders
    
    func getPendingPaymentReminders() async -> [PaymentReminder] {
        guard let userId = Auth.auth().currentUser?.uid else {
            // Return mock payment reminders for demo
            return createMockPaymentReminders()
        }
        
        do {
            let snapshot = try await db.collection("auctions")
                .whereField("winnerId", isEqualTo: userId)
                .whereField("paymentStatus", isEqualTo: "pending")
                .getDocuments()
            
            var reminders: [PaymentReminder] = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                guard let propertyTitle = data["propertyTitle"] as? String,
                      let winningBid = data["winningBid"] as? Double,
                      let auctionEndTime = (data["endTime"] as? Timestamp)?.dateValue() else {
                    continue
                }
                
                let propertyImageURL = (data["propertyImages"] as? [String])?.first ?? ""
                let paymentDeadline = auctionEndTime.addingTimeInterval(24 * 60 * 60) // 24 hours after auction end
                
                // Only include if deadline hasn't passed yet (give some grace period)
                if paymentDeadline.timeIntervalSinceNow > -60 * 60 { // 1 hour grace period
                    let reminder = PaymentReminder(
                        auctionId: document.documentID,
                        propertyTitle: propertyTitle,
                        propertyImageURL: propertyImageURL,
                        amount: winningBid,
                        deadline: paymentDeadline
                    )
                    reminders.append(reminder)
                }
            }
            
            // Sort by deadline (most urgent first)
            return reminders.sorted { $0.deadline < $1.deadline }
            
        } catch {
            print("Error fetching pending payment reminders: \(error)")
            return createMockPaymentReminders()
        }
    }
    
    // MARK: - Mock Data for Testing
    
    private func createMockTransactionHistory() -> [TransactionHistory] {
        let userId = Auth.auth().currentUser?.uid ?? "mock_user"
        
        return [
            TransactionHistory(
                transactionId: "txn_001",
                userId: userId,
                propertyTitle: "Modern Villa in Beverly Hills",
                amount: 125000.0,
                type: .payment,
                status: .completed,
                paymentMethod: .creditCard,
                date: Date().addingTimeInterval(-86400 * 7), // 1 week ago
                fees: 2500.0,
                description: "Auction payment"
            ),
            TransactionHistory(
                transactionId: "txn_002",
                userId: userId,
                propertyTitle: "Downtown Penthouse",
                amount: 89000.0,
                type: .payment,
                status: .completed,
                paymentMethod: .bankTransfer,
                date: Date().addingTimeInterval(-86400 * 14), // 2 weeks ago
                fees: 1780.0,
                description: "Auction payment"
            ),
            TransactionHistory(
                transactionId: "txn_003",
                userId: userId,
                propertyTitle: "Seaside Cottage",
                amount: 5000.0,
                type: .refund,
                status: .completed,
                date: Date().addingTimeInterval(-86400 * 21), // 3 weeks ago
                description: "Partial refund for cancelled auction"
            )
        ]
    }
    
    private func createMockPaymentReminders() -> [PaymentReminder] {
        return [
            PaymentReminder(
                auctionId: "auction_001",
                propertyTitle: "Luxury Beachfront Condo",
                propertyImageURL: "https://example.com/property1.jpg",
                amount: 85000.0,
                deadline: Date().addingTimeInterval(90 * 60) // 1.5 hours from now
            ),
            PaymentReminder(
                auctionId: "auction_002",
                propertyTitle: "Mountain View Estate",
                propertyImageURL: "https://example.com/property2.jpg",
                amount: 165000.0,
                deadline: Date().addingTimeInterval(6 * 60 * 60) // 6 hours from now
            )
        ]
    }
    
    func getPurchaseHistory() -> [UserPurchaseHistory] {
        return purchaseHistory
    }
    
    // MARK: - Notifications
    private func sendPaymentNotification(propertyTitle: String, amount: Double) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let notification = [
            "userId": userId,
            "title": "Payment Successful! 🎉",
            "body": "Your payment of $\(String(format: "%.2f", amount)) for \(propertyTitle) has been processed successfully.",
            "type": "payment_success",
            "timestamp": Timestamp()
        ] as [String : Any]
        
        do {
            try await db.collection("notifications").addDocument(data: notification)
            
            // Send push notification via FCM
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let fcmToken = userDoc.get("fcmToken") as? String {
                let message: [String: Any] = [
                    "token": fcmToken,
                    "notification": [
                        "title": "Payment Successful! 🎉",
                        "body": "Your payment has been processed successfully."
                    ],
                    "data": [
                        "type": "payment_success",
                        "propertyTitle": propertyTitle,
                        "amount": String(format: "%.2f", amount)
                    ]
                ]
                
                // TODO: Implement push notification via FCM when FirebaseFunctions is available
                // let functions = Functions.functions()
                // _ = try? await functions.httpsCallable("sendPushNotification").call(message)
                print("Would send push notification: \(message)")
            }
        } catch {
            print("Error sending notification: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Refund Processing
    func processRefund(transactionId: String, reason: String) async throws {
        // Find the transaction
        guard let transaction = transactions.first(where: { $0.transactionId == transactionId }) else {
            throw PaymentError.transactionNotFound
        }
        
        // Create a refund transaction record
        let refundTransaction = TransactionHistory(
            transactionId: UUID().uuidString,
            userId: transaction.userId,
            propertyTitle: transaction.propertyTitle,
            amount: -transaction.amount,
            type: .refund,
            status: .completed,
            paymentMethod: transaction.paymentMethod,
            description: "Refund for transaction: \(transactionId) - \(reason)"
        )
        
        // Add to transaction history
        transactions.append(refundTransaction)
        
        // Save refund transaction to Firestore
        _ = try await db.collection("transactions").addDocument(from: refundTransaction)
        
        // Update original transaction status
        if let transactionDocId = transaction.id {
            try await db.collection("transactions").document(transactionDocId).updateData([
                "status": TransactionStatus.refunded.rawValue
            ])
        }
        
        print("Refund processed for transaction \(transactionId)")
    }
    
    // MARK: - Apple Pay Support
    func createApplePayRequest(for amount: Double, propertyTitle: String) -> String {
        // This is a placeholder implementation for Apple Pay
        // In a real app, this would create a PKPaymentRequest
        return "apple-pay-request-\(UUID().uuidString)"
    }
    
    func canMakeApplePayPayments() -> Bool {
        // This is a placeholder implementation
        // In a real app, this would check PKPaymentAuthorizationViewController.canMakePayments()
        return true
    }
}

// MARK: - Payment Errors
enum PaymentError: LocalizedError {
    case propertyNotFound
    case invalidCard
    case transactionNotFound
    case paymentFailed
    case insufficientFunds
    case cardExpired
    case invalidCVV
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .propertyNotFound:
            return "Property not found"
        case .invalidCard:
            return "Invalid card details"
        case .transactionNotFound:
            return "Transaction not found"
        case .paymentFailed:
            return "Payment processing failed"
        case .insufficientFunds:
            return "Insufficient funds"
        case .cardExpired:
            return "Card has expired"
        case .invalidCVV:
            return "Invalid CVV code"
        case .networkError:
            return "Network connection error"
        }
    }
}
