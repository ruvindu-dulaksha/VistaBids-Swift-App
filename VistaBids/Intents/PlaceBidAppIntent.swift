//
//  PlaceBidAppIntent.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-19.
//

import AppIntents
import SwiftUI

@available(iOS 16.0, *)
struct PlaceBidAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Place a bid"
    static var description: LocalizedStringResource = "Place a bid on a property auction"

    @Parameter(title: "Bid Amount", description: "The amount you want to bid")
    var amount: Double

    @Parameter(title: "Property ID", description: "The property you want to bid on")
    var propertyId: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Place a bid of $\(\.$amount)") {
            \.$amount
            \.$propertyId
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        print("🎯 App Intent: Placing bid of $\(amount)")

        // Here you would integrate with your bidding service
        // For now, we'll just show a success message

        let message = "Bid of $\(amount) placed successfully!"
        print("✅ \(message)")

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

@available(iOS 16.0, *)
struct GetAuctionStatusAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Get auction status"
    static var description: LocalizedStringResource = "Check the current status of an auction"

    @Parameter(title: "Property ID", description: "The property auction to check")
    var propertyId: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Get auction status") {
            \.$propertyId
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        print("🎯 App Intent: Getting auction status")

        // Here you would check your auction status
        let status = "Auction is currently active with 5 bids"

        return .result(dialog: IntentDialog(stringLiteral: status))
    }
}