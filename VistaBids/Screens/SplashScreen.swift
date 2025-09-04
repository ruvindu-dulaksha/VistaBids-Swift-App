//
//  SplashScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-22.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var progress: CGFloat = 0.0
    @State private var timer: Timer?

    var body: some View {
        if isActive {
            LoginScreen()
        } else {
            ZStack {
                Color("BackgroundColor").edgesIgnoringSafeArea(.all)
                VStack(spacing: 16) {
                    LottieView(name: "splash_lottie", loopMode: .playOnce)
                        .frame(width: 250, height: 250)
                    VStack(spacing: 8) {
                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        ProgressView(value: min(progress, 1.0), total: 1.0)
                            .frame(width: 200)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
            }
            .onAppear {
                startLoadingProgress()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startLoadingProgress() {
        progress = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.2)) {
                progress += 0.1
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                self.timer = nil
                
                // Add a small delay after reaching 100% before transitioning
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
}
