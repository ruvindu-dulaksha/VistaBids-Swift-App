//
//  PayWithApplePayButton.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-15.
//

import SwiftUI
import PassKit

struct PayWithApplePayButton: View {
    private let type: PKPaymentButtonType
    private let action: () -> Void
    
    init(_ type: PKPaymentButtonType = .buy, action: @escaping () -> Void) {
        self.type = type
        self.action = action
    }
    
    var body: some View {
        ApplePayButton(type: type)
            .onTapGesture(perform: action)
    }
}

struct ApplePayButton: UIViewRepresentable {
    let type: PKPaymentButtonType
    
    func makeUIView(context: Context) -> PKPaymentButton {
        return PKPaymentButton(paymentButtonType: type, paymentButtonStyle: .black)
    }
    
    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        
    }
}

#Preview {
    PayWithApplePayButton(.buy) {
        print("Apple Pay tapped")
    }
    .frame(width: 200, height: 45)
}
