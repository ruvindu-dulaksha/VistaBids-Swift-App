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
                userId: currentUserId,
                userName: Auth.auth().currentUser?.displayName ?? "Anonymous",
                propertyId: propertyId,
                propertyTitle: property.title,
                propertyImages: property.images,
                auctionId: propertyId,
                bidAmount: amount,
                finalPrice: amount,
                transactionType: .auctionWin,
                paymentMethod: paymentMethod,
                paymentStatus: .processing,
                transactionDate: Date(),
                paymentDate: nil,
                paymentReference: transactionId,
                cardDetails: cardDetails,
                billingAddress: billingAddress,
                fees: fees,
                notes: "Auction win payment for \(property.title)"
            )
            
            // Simulate payment processing delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Save transaction to Firestore
            _ = try await db.collection("transactions").addDocument(from: transaction)
            
            // Send push notification
            await sendPaymentNotification(propertyTitle: transaction.propertyTitle, amount: transaction.finalPrice)
            
            // Update payment status to completed
            let completedTransaction = TransactionHistory(
                id: transaction.id,
                userId: transaction.userId,
                userName: transaction.userName,
                propertyId: transaction.propertyId,
                propertyTitle: transaction.propertyTitle,
                propertyImages: transaction.propertyImages,
                auctionId: transaction.auctionId,
                bidAmount: transaction.bidAmount,
                finalPrice: transaction.finalPrice,
                transactionType: transaction.transactionType,
                paymentMethod: transaction.paymentMethod,
                paymentStatus: .completed,
                transactionDate: transaction.transactionDate,
                paymentDate: Date(),
                paymentReference: transaction.paymentReference,
                cardDetails: transaction.cardDetails,
                billingAddress: transaction.billingAddress,
                fees: transaction.fees,
                notes: transaction.notes
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
    func getTransactionHistory() -> [TransactionHistory] {
        return transactions
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
        guard let transaction = transactions.first(where: { $0.paymentReference == transactionId }) else {
            throw PaymentError.transactionNotFound
        }
        
        // Create a refund transaction record
        let refundTransaction = TransactionHistory(
            userId: transaction.userId,
            userName: transaction.userName,
            propertyId: transaction.propertyId,
            propertyTitle: transaction.propertyTitle,
            propertyImages: transaction.propertyImages,
            auctionId: transaction.auctionId,
            bidAmount: -transaction.finalPrice,
            finalPrice: -transaction.finalPrice,
            transactionType: .refund,
            paymentMethod: transaction.paymentMethod,
            paymentStatus: .completed,
            transactionDate: Date(),
            paymentDate: Date(),
            paymentReference: UUID().uuidString,
            cardDetails: transaction.cardDetails,
            billingAddress: transaction.billingAddress,
            fees: TransactionFees(serviceFee: 0.0, processingFee: 0.0, taxes: 0.0),
            notes: "Refund for transaction: \(transactionId)"
        )
        
        // Add to transaction history
        transactions.append(refundTransaction)
        
        // Save refund transaction to Firestore
        _ = try await db.collection("transactions").addDocument(data: try Firestore.Encoder().encode(refundTransaction))
        
        // Update original transaction status
        if let transactionDocId = transaction.id {
            try await db.collection("transactions").document(transactionDocId).updateData([
                "paymentStatus": PaymentStatus.refunded.rawValue
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
