//
//  NotificationBellView.swift
//  VistaBids
//
//  Created by GitHub Copilot on 2025-08-21.
//

import SwiftUI

struct NotificationBellView: View {
    @StateObject private var notificationService = NotificationService.shared
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var showingNotifications = false
    @State private var bellAnimation = false
    @State private var pulseAnimation = false
    @State private var bounceAnimation = false
    
    var body: some View {
        ZStack {
            Button(action: {
                showingNotifications = true
                triggerHapticFeedback()
            }) {
                ZStack {
                    // Bell icon
                    Image(systemName: notificationService.unreadCount > 0 ? "bell.fill" : "bell")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .scaleEffect(bounceAnimation ? 1.2 : 1.0)
                        .rotationEffect(.degrees(bellAnimation ? 15 : 0))
                        .animation(.interpolatingSpring(stiffness: 300, damping: 10), value: bounceAnimation)
                        .animation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true), value: bellAnimation)
                    
                    // Unread count badge
                    if notificationService.unreadCount > 0 {
                        VStack {
                            HStack {
                                Spacer()
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: notificationService.unreadCount > 99 ? 22 : 18, height: 18)
                                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                                    
                                    Text(notificationService.unreadCount > 99 ? "99+" : "\(notificationService.unreadCount)")
                                        .font(.system(size: notificationService.unreadCount > 99 ? 9 : 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .minimumScaleFactor(0.8)
                                }
                                .offset(x: 8, y: -8)
                            }
                            Spacer()
                        }
                        .frame(width: 24, height: 24)
                    }
                }
            }
            .frame(width: 44, height: 44)
            
            // Ripple effect for new notifications
            if notificationService.hasNewNotification {
                RippleEffect()
                    .frame(width: 60, height: 60)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Start pulse animation for badge
            if notificationService.unreadCount > 0 {
                pulseAnimation = true
            }
        }
        .onChange(of: notificationService.unreadCount) { _, newCount in
            if newCount > 0 {
                pulseAnimation = true
            } else {
                pulseAnimation = false
            }
        }
        .onChange(of: notificationService.hasNewNotification) { _, hasNew in
            if hasNew {
                triggerNewNotificationAnimation()
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationView()
        }
    }
    
    private func triggerNewNotificationAnimation() {
        // Bell shake animation
        withAnimation {
            bellAnimation = true
        }
        
        // Bounce animation
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
            bounceAnimation = true
        }
        
        // Reset animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            bellAnimation = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            bounceAnimation = false
        }
        
        // Haptic feedback
                            triggerHapticFeedback(.success)
    }
    
    private func triggerHapticFeedback(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(feedbackType)
    }
}

// MARK: - Ripple Effect for New Notifications
struct RippleEffect: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentBlues.opacity(0.3), lineWidth: 2)
                .scaleEffect(animate ? 1.5 : 0.5)
                .opacity(animate ? 0 : 1)
            
            Circle()
                .stroke(Color.accentBlues.opacity(0.2), lineWidth: 3)
                .scaleEffect(animate ? 1.8 : 0.3)
                .opacity(animate ? 0 : 0.8)
            
            Circle()
                .stroke(Color.accentBlues.opacity(0.1), lineWidth: 4)
                .scaleEffect(animate ? 2.0 : 0.1)
                .opacity(animate ? 0 : 0.6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animate = true
            }
        }
    }
}

// MARK: - Notification Badge (Standalone)
struct NotificationBadge: View {
    let count: Int
    let color: Color
    
    init(count: Int, color: Color = .red) {
        self.count = count
        self.color = color
    }
    
    var body: some View {
        if count > 0 {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: count > 99 ? 22 : 18, height: 18)
                
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: count > 99 ? 9 : 10, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

// MARK: - Animated Bell Icon (Standalone)
struct AnimatedBellIcon: View {
    @State private var isRinging = false
    let hasNotifications: Bool
    
    var body: some View {
        Image(systemName: hasNotifications ? "bell.fill" : "bell")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.textPrimary)
            .rotationEffect(.degrees(isRinging ? 15 : 0))
            .animation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true), value: isRinging)
            .onTapGesture {
                if hasNotifications {
                    isRinging = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isRinging = false
                    }
                }
            }
    }
}

#Preview {
    VStack(spacing: 30) {
        NotificationBellView()
        
        HStack(spacing: 20) {
            ZStack {
                AnimatedBellIcon(hasNotifications: true)
                VStack {
                    HStack {
                        Spacer()
                        NotificationBadge(count: 5)
                            .offset(x: 8, y: -8)
                    }
                    Spacer()
                }
            }
            .frame(width: 44, height: 44)
            
            ZStack {
                AnimatedBellIcon(hasNotifications: false)
            }
            .frame(width: 44, height: 44)
        }
    }
    .padding()
    .background(Color.backgrounds)
}
