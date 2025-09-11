//
//  TranslationIconView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-09-07.
//

import SwiftUI

struct TranslationIconView: View {
    @EnvironmentObject var translationManager: TranslationManager
    @State private var showingTranslation = false
    @State private var animateIcon = false
    
    var body: some View {
        Button(action: {
            showingTranslation = true
            triggerHapticFeedback()
        }) {
            ZStack {
                Image(systemName: "globe")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .rotationEffect(.degrees(animateIcon ? 20 : 0))
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateIcon)
                
                // Active language indicator
                if translationManager.isTranslated {
                    VStack {
                        HStack {
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(Color.accentBlues)
                                    .frame(width: 12, height: 12)
                                
                                Text(translationManager.targetLanguage.prefix(2).uppercased())
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 6, y: -6)
                        }
                        Spacer()
                    }
                    .frame(width: 24, height: 24)
                }
            }
        }
        .frame(width: 44, height: 44)
        .onChange(of: translationManager.isTranslated) { _, isTranslated in
            if isTranslated {
                withAnimation {
                    animateIcon = true
                    
                    // Reset animation after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        animateIcon = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingTranslation) {
            TranslationView()
        }
    }
    
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    TranslationIconView()
        .environmentObject(TranslationManager.shared)
}
