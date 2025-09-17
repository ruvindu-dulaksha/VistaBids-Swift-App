//
//  TransactionReceiptGenerator.swift
//  VistaBids
//
//  Created by Ruvindu Dulakshaa on 2025-09-05.
//

import Foundation
import MessageUI
import PDFKit

class TransactionReceiptGenerator {
    static let shared = TransactionReceiptGenerator()
    
    private init() {}
    
    //  PDF Generation
    func generateReceiptPDF(transaction: TransactionHistory) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "VistaBids",
            kCGPDFContextAuthor: "VistaBids Payment System",
            kCGPDFContextTitle: "Payment Receipt"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Draw content
            let attributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ]
            
            // Header
            drawHeader(in: context.cgContext, pageRect: pageRect)
            
            // Transaction Details
            drawTransactionDetails(transaction, in: context.cgContext, pageRect: pageRect, attributes: attributes)
            
            // Property Details
            drawPropertyDetails(transaction, in: context.cgContext, pageRect: pageRect, attributes: attributes)
            
            // Payment Details
            drawPaymentDetails(transaction, in: context.cgContext, pageRect: pageRect, attributes: attributes)
            
            // Footer
            drawFooter(in: context.cgContext, pageRect: pageRect)
        }
        
        return data
    }
    
    private func drawHeader(in context: CGContext, pageRect: CGRect) {
        let headerText = "VistaBids Payment Receipt"
        let attributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
        ]
        
        let textSize = headerText.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (pageRect.width - textSize.width) / 2,
            y: 50,
            width: textSize.width,
            height: textSize.height
        )
        
        headerText.draw(in: textRect, withAttributes: attributes)
    }
    
    private func drawTransactionDetails(_ transaction: TransactionHistory, in context: CGContext, pageRect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        var yPosition: CGFloat = 120
        
        // Transaction ID
        drawTextLine("Transaction ID: \(transaction.transactionId)", at: &yPosition, in: pageRect, attributes: attributes)
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .medium
        drawTextLine("Date: \(dateFormatter.string(from: transaction.date))", at: &yPosition, in: pageRect, attributes: attributes)
        
        // Payment Status
        drawTextLine("Status: \(transaction.status.rawValue.capitalized)", at: &yPosition, in: pageRect, attributes: attributes)
    }
    
    private func drawPropertyDetails(_ transaction: TransactionHistory, in context: CGContext, pageRect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        var yPosition: CGFloat = 200
        
        drawSectionHeader("Property Details", at: &yPosition, in: pageRect)
        
        drawTextLine("Property: \(transaction.propertyTitle)", at: &yPosition, in: pageRect, attributes: attributes)
    }
    
    private func drawPaymentDetails(_ transaction: TransactionHistory, in context: CGContext, pageRect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        var yPosition: CGFloat = 300
        
        drawSectionHeader("Payment Details", at: &yPosition, in: pageRect)
        
        // Amount details
        drawTextLine("Amount: $\(String(format: "%.2f", transaction.amount))", at: &yPosition, in: pageRect, attributes: attributes)
        
        if let fees = transaction.fees {
            drawTextLine("Fees: $\(String(format: "%.2f", fees))", at: &yPosition, in: pageRect, attributes: attributes)
            
            // Total
            let boldAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)
            ]
            let total = transaction.amount + fees
            drawTextLine("Total Amount: $\(String(format: "%.2f", total))", at: &yPosition, in: pageRect, attributes: boldAttributes)
        } else {
            // Total
            let boldAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)
            ]
            drawTextLine("Total Amount: $\(String(format: "%.2f", transaction.amount))", at: &yPosition, in: pageRect, attributes: boldAttributes)
        }
        
        // Payment Method
        yPosition += 20
        if let paymentMethod = transaction.paymentMethod {
            drawTextLine("Payment Method: \(paymentMethod.displayText)", at: &yPosition, in: pageRect, attributes: attributes)
        }
    }
    
    private func drawFooter(in context: CGContext, pageRect: CGRect) {
        let footerText = "Thank you for using VistaBids"
        let attributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
        ]
        
        let textSize = footerText.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (pageRect.width - textSize.width) / 2,
            y: pageRect.height - 50,
            width: textSize.width,
            height: textSize.height
        )
        
        footerText.draw(in: textRect, withAttributes: attributes)
    }
    
    private func drawSectionHeader(_ text: String, at yPosition: inout CGFloat, in pageRect: CGRect) {
        let attributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)
        ]
        
        drawTextLine(text, at: &yPosition, in: pageRect, attributes: attributes)
        yPosition += 10 // Add some extra spacing after header
    }
    
    private func drawTextLine(_ text: String, at yPosition: inout CGFloat, in pageRect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        let textRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 20)
        text.draw(in: textRect, withAttributes: attributes)
        yPosition += 25
    }
    
    //  Error
    enum ReceiptError: LocalizedError {
        case pdfGenerationFailed
        
        var errorDescription: String? {
            switch self {
            case .pdfGenerationFailed:
                return "Failed to generate receipt PDF"
            }
        }
    }
}
