//
//  PaymentModels.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-05.
//

import Foundation
import UIKit
import FirebaseFirestore

// MARK: - PaymentMethod
enum PaymentMethod: String, Codable, CaseIterable {
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case bankTransfer = "bank_transfer"
    case digitalWallet = "digital_wallet"
    
    var displayName: String {
        switch self {
        case .creditCard:
            return "Credit Card"
        case .debitCard:
            return "Debit Card"
        case .bankTransfer:
            return "Bank Transfer"
        case .digitalWallet:
            return "Digital Wallet"
        }
    }
    
    var displayText: String {
        return displayName
    }
    
    var icon: String {
        switch self {
        case .creditCard:
            return "creditcard"
        case .debitCard:
            return "creditcard.circle"
        case .bankTransfer:
            return "building.columns"
        case .digitalWallet:
            return "wallet.pass"
        }
    }
}

// MARK: - PaymentStatus
enum PaymentStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    case cancelled = "cancelled"
    
    var displayText: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .refunded:
            return "Refunded"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: UIColor {
        switch self {
        case .pending:
            return .systemYellow
        case .processing:
            return .systemBlue
        case .completed:
            return .systemGreen
        case .failed:
            return .systemRed
        case .refunded:
            return .systemOrange
        case .cancelled:
            return .systemGray
        }
    }
}

// MARK: - TransactionStatus
enum TransactionStatus: String, Codable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .refunded:
            return "Refunded"
        }
    }
}

// MARK: - TransactionType
enum TransactionType: String, Codable {
    case payment = "payment"
    case refund = "refund"
    case auctionWin = "auction_win"
}

// MARK: - DeliveryStatus
enum DeliveryStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case delivered = "delivered"
    case cancelled = "cancelled"
}

// MARK: - CardType
enum CardType: String, Codable {
    case visa = "visa"
    case mastercard = "mastercard"
    case amex = "amex"
    case discover = "discover"
    case unknown = "unknown"
}

// MARK: - CardVerificationMethod
enum CardVerificationMethod: String, Codable {
    case cvv = "cvv"
    case threeDSecure = "3d_secure"
}

// MARK: - PaymentReminder
struct PaymentReminder: Codable, Identifiable {
    var id = UUID()
    let auctionId: String
    let propertyTitle: String
    let propertyImageURL: String
    let amount: Double
    let currency: String
    let deadline: Date
    let isUrgent: Bool
    
    enum CodingKeys: String, CodingKey {
        case auctionId, propertyTitle, propertyImageURL, amount, currency, deadline, isUrgent
    }
    
    init(auctionId: String, propertyTitle: String, propertyImageURL: String, amount: Double, currency: String = "USD", deadline: Date) {
        self.auctionId = auctionId
        self.propertyTitle = propertyTitle
        self.propertyImageURL = propertyImageURL
        self.amount = amount
        self.currency = currency
        self.deadline = deadline
        
        // Mark as urgent if less than 2 hours remaining
        self.isUrgent = deadline.timeIntervalSinceNow < 2 * 60 * 60
    }
}

// MARK: - CardDetails
struct CardDetails: Codable, Identifiable {
    @DocumentID var id: String?
    let cardType: CardType
    let lastFourDigits: String
    let expiryMonth: Int
    let expiryYear: Int
    let cardholderName: String
    let isVerified: Bool
    let verificationMethod: CardVerificationMethod
}

// MARK: - BillingAddress
struct BillingAddress: Codable {
    let street: String
    let city: String
    let state: String
    let postalCode: String
    let country: String
    
    var fullAddress: String {
        return "\(street), \(city), \(state) \(postalCode), \(country)"
    }
}

// MARK: - TransactionFees
struct TransactionFees: Codable {
    let serviceFee: Double
    let processingFee: Double
    let taxes: Double
    
    var totalFees: Double {
        return serviceFee + processingFee + taxes
    }
}

// MARK: - TransactionHistory
struct TransactionHistory: Codable, Identifiable {
    @DocumentID var id: String?
    let transactionId: String
    let userId: String
    let propertyTitle: String
    let amount: Double
    let currency: String
    let type: TransactionType
    let status: TransactionStatus
    let paymentMethod: PaymentMethod?
    let date: Date
    let fees: Double?
    let description: String?
    
    init(transactionId: String, userId: String, propertyTitle: String, amount: Double, currency: String = "USD", type: TransactionType, status: TransactionStatus, paymentMethod: PaymentMethod? = nil, date: Date = Date(), fees: Double? = nil, description: String? = nil) {
        self.transactionId = transactionId
        self.userId = userId
        self.propertyTitle = propertyTitle
        self.amount = amount
        self.currency = currency
        self.type = type
        self.status = status
        self.paymentMethod = paymentMethod
        self.date = date
        self.fees = fees
        self.description = description
    }
}

// MARK: - UserPurchaseHistory
struct UserPurchaseHistory: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let propertyId: String
    let propertyTitle: String
    let propertyImages: [String]
    let purchasePrice: Double
    let purchaseDate: Date
    let transactionId: String
    let paymentStatus: PaymentStatus
    let deliveryStatus: DeliveryStatus
    let propertyAddress: PropertyAddress
    let propertyFeatures: PropertyFeatures
}
