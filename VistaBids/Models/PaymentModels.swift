//
//  PaymentModels.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-09-05.
//

import Foundation
import FirebaseFirestore

// MARK: - PaymentMethod
enum PaymentMethod: String, Codable, CaseIterable {
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case applePay = "apple_pay"
    case bankTransfer = "bank_transfer"
    
    var displayText: String {
        switch self {
        case .creditCard:
            return "Credit Card"
        case .debitCard:
            return "Debit Card"
        case .applePay:
            return "Apple Pay"
        case .bankTransfer:
            return "Bank Transfer"
        }
    }
    
    var icon: String {
        switch self {
        case .creditCard:
            return "creditcard"
        case .debitCard:
            return "creditcard.circle"
        case .applePay:
            return "applelogo"
        case .bankTransfer:
            return "building.columns"
        }
    }
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

// MARK: - TransactionType
enum TransactionType: String, Codable {
    case auctionWin = "auction_win"
    case refund = "refund"
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
    let userId: String
    let userName: String
    let propertyId: String
    let propertyTitle: String
    let propertyImages: [String]
    let auctionId: String
    let bidAmount: Double
    let finalPrice: Double
    let transactionType: TransactionType
    let paymentMethod: PaymentMethod
    let paymentStatus: PaymentStatus
    let transactionDate: Date
    let paymentDate: Date?
    let paymentReference: String
    let cardDetails: CardDetails?
    let billingAddress: BillingAddress
    let fees: TransactionFees
    let notes: String?
    
    var totalAmount: Double {
        return finalPrice + fees.totalFees
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
