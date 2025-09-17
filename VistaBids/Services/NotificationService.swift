//
//  NotificationService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-21.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

// App Notification Model
struct AppNotification: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let body: String
    let type: NotificationType
    let data: [String: String]?
    let timestamp: Date
    var isRead: Bool
    let priority: NotificationPriority
    
    enum NotificationType: String, Codable, CaseIterable {
        case newBidding = "new_bidding"
        case newSelling = "new_selling"
        case outbid = "outbid"
        case auctionWon = "auction_won"
        case auctionEnded = "auction_ended"
        case communityEvent = "community_event"
        case groupMessage = "group_message"
        case general = "general"
        
        var icon: String {
            switch self {
            case .newBidding: return "hammer.fill"
            case .newSelling: return "house.fill"
            case .outbid: return "exclamationmark.triangle.fill"
            case .auctionWon: return "trophy.fill"
            case .auctionEnded: return "clock.fill"
            case .communityEvent: return "calendar"
            case .groupMessage: return "message.fill"
            case .general: return "bell.fill"
            }
        }
        
        var color: String {
            switch self {
            case .newBidding: return "blue"
            case .newSelling: return "green"
            case .outbid: return "red"
            case .auctionWon: return "yellow"
            case .auctionEnded: return "gray"
            case .communityEvent: return "purple"
            case .groupMessage: return "blue"
            case .general: return "gray"
            }
        }
        
        var displayName: String {
            switch self {
            case .newBidding: return "New Bidding"
            case .newSelling: return "New Property"
            case .outbid: return "Outbid Alert"
            case .auctionWon: return "Auction Won"
            case .auctionEnded: return "Auction Ended"
            case .communityEvent: return "Community Event"
            case .groupMessage: return "Group Message"
            case .general: return "Notification"
            }
        }
    }
    
    enum NotificationPriority: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case urgent = "urgent"
    }
}

//  Enhanced Notification Service
@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    private let db = Firestore.firestore()
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var hasNewNotification: Bool = false
    
    private var fcmToken: String?
    private var notificationListener: ListenerRegistration?
    
    override init() {
        super.init()
        setupNotifications()
        setupFCMTokenRefresh()
        startListeningToNotifications()
    }
    
    deinit {
        notificationListener?.remove()
    }
    
    // Setup Methods
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("✅ Push notifications authorized")
                } else {
                    print("❌ Push notifications denied")
                }
            }
        }
    }
    
    private func setupFCMTokenRefresh() {
        Messaging.messaging().token { [weak self] token, error in
            if let token = token {
                self?.fcmToken = token
                print("📱 FCM token: \(token)")
                Task {
                    await self?.updateUserFCMToken(token)
                }
            } else if let error = error {
                print("❌ Error fetching FCM token: \(error)")
            }
        }
    }
    
    private func updateUserFCMToken(_ token: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "fcmToken": token,
                "lastTokenUpdate": FieldValue.serverTimestamp()
            ])
            print("✅ FCM token updated for user: \(userId)")
        } catch {
            print("❌ Error updating FCM token: \(error)")
        }
    }
    
    // Notification Listening
    private func startListeningToNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        notificationListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    if let error = error {
                        print("❌ Error listening to notifications: \(error)")
                    }
                    return
                }
                
                let newNotifications = documents.compactMap { document in
                    try? document.data(as: AppNotification.self)
                }
                
                let oldUnreadCount = self.unreadCount
                self.notifications = newNotifications
                self.unreadCount = newNotifications.filter { !$0.isRead }.count
                
                // Trigger animation if new notifications arrived
                if self.unreadCount > oldUnreadCount {
                    self.hasNewNotification = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.hasNewNotification = false
                    }
                }
                
                print("📱 Loaded \(newNotifications.count) notifications, \(self.unreadCount) unread")
            }
    }
    
    // Public Methods
    func markAsRead(_ notificationId: String) async {
        do {
            try await db.collection("notifications").document(notificationId).updateData([
                "isRead": true
            ])
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index] = AppNotification(
                    id: notifications[index].id,
                    userId: notifications[index].userId,
                    title: notifications[index].title,
                    body: notifications[index].body,
                    type: notifications[index].type,
                    data: notifications[index].data,
                    timestamp: notifications[index].timestamp,
                    isRead: true,
                    priority: notifications[index].priority
                )
                unreadCount = notifications.filter { !$0.isRead }.count
            }
        } catch {
            print("❌ Error marking notification as read: \(error)")
        }
    }
    
    func sendLocalNotification(_ notification: AppNotification) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.badge = NSNumber(value: unreadCount + 1)
        
        if let data = notification.data {
            content.userInfo = data
        }
        
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Local notification sent: \(notification.title)")
        } catch {
            print("❌ Error sending local notification: \(error)")
        }
    }
    
    func clearAllNotifications() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let batch = db.batch()
            
            for notification in notifications {
                let ref = db.collection("notifications").document(notification.id)
                batch.deleteDocument(ref)
            }
            
            try await batch.commit()
            
            // Clear local state
            notifications.removeAll()
            unreadCount = 0
            
            // Clear badge
            UIApplication.shared.applicationIconBadgeNumber = 0
            
            print("✅ Cleared all notifications")
        } catch {
            print("❌ Error clearing all notifications: \(error)")
        }
    }
    
    func updateNotificationPreferences() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let preferences = [
            "pushNotificationsEnabled": UserDefaults.standard.bool(forKey: "pushNotificationsEnabled"),
            "emailNotificationsEnabled": UserDefaults.standard.bool(forKey: "emailNotificationsEnabled"),
            "smsNotificationsEnabled": UserDefaults.standard.bool(forKey: "smsNotificationsEnabled"),
            "biddingNotifications": UserDefaults.standard.bool(forKey: "biddingNotifications"),
            "auctionNotifications": UserDefaults.standard.bool(forKey: "auctionNotifications"),
            "paymentNotifications": UserDefaults.standard.bool(forKey: "paymentNotifications"),
            "communityNotifications": UserDefaults.standard.bool(forKey: "communityNotifications"),
            "marketingNotifications": UserDefaults.standard.bool(forKey: "marketingNotifications"),
            "quietHoursEnabled": UserDefaults.standard.bool(forKey: "quietHoursEnabled"),
            "selectedSound": UserDefaults.standard.string(forKey: "selectedSound") ?? "Default",
            "lastUpdated": FieldValue.serverTimestamp()
        ] as [String : Any]
        
        do {
            try await db.collection("users").document(userId).updateData([
                "notificationPreferences": preferences
            ])
            print("✅ Updated notification preferences")
        } catch {
            print("❌ Error updating notification preferences: \(error)")
        }
    }
    
    func markAllAsRead() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let batch = db.batch()
            let unreadNotifications = notifications.filter { !$0.isRead }
            
            for notification in unreadNotifications {
                let ref = db.collection("notifications").document(notification.id)
                batch.updateData(["isRead": true], forDocument: ref)
            }
            
            try await batch.commit()
            
            // Update local state
            for i in 0..<notifications.count {
                notifications[i] = AppNotification(
                    id: notifications[i].id,
                    userId: notifications[i].userId,
                    title: notifications[i].title,
                    body: notifications[i].body,
                    type: notifications[i].type,
                    data: notifications[i].data,
                    timestamp: notifications[i].timestamp,
                    isRead: true,
                    priority: notifications[i].priority
                )
            }
            unreadCount = 0
            
            print("✅ Marked all notifications as read")
        } catch {
            print("❌ Error marking all notifications as read: \(error)")
        }
    }
    
    func deleteNotification(_ notificationId: String) async {
        do {
            try await db.collection("notifications").document(notificationId).delete()
            notifications.removeAll { $0.id == notificationId }
            unreadCount = notifications.filter { !$0.isRead }.count
            print("✅ Deleted notification: \(notificationId)")
        } catch {
            print("❌ Error deleting notification: \(error)")
        }
    }
    
    // Send Notifications
    func sendNotificationToAllUsers(
        title: String,
        body: String,
        type: AppNotification.NotificationType,
        data: [String: String]? = nil,
        priority: AppNotification.NotificationPriority = .medium,
        excludeUserId: String? = nil
    ) async {
        do {
            // Get all users
            let usersSnapshot = try await db.collection("users").getDocuments()
            let batch = db.batch()
            
            for userDocument in usersSnapshot.documents {
                let userId = userDocument.documentID
                
                // Skip excluded user (like the one who created the listing)
                if let excludeUserId = excludeUserId, userId == excludeUserId {
                    continue
                }
                
                let notification = AppNotification(
                    id: UUID().uuidString,
                    userId: userId,
                    title: title,
                    body: body,
                    type: type,
                    data: data,
                    timestamp: Date(),
                    isRead: false,
                    priority: priority
                )
                
                let notificationRef = db.collection("notifications").document(notification.id)
                try batch.setData(from: notification, forDocument: notificationRef)
            }
            
            try await batch.commit()
            
            // Send push notifications
            await sendPushNotificationToAllUsers(
                title: title,
                body: body,
                data: data,
                excludeUserId: excludeUserId
            )
            
            print("✅ Sent notification to all users: \(title)")
        } catch {
            print("❌ Error sending notification to all users: \(error)")
        }
    }
    
    func sendNotificationToUser(
        userId: String,
        title: String,
        body: String,
        type: AppNotification.NotificationType,
        data: [String: String]? = nil,
        priority: AppNotification.NotificationPriority = .medium
    ) async {
        do {
            let notification = AppNotification(
                id: UUID().uuidString,
                userId: userId,
                title: title,
                body: body,
                type: type,
                data: data,
                timestamp: Date(),
                isRead: false,
                priority: priority
            )
            
            try await db.collection("notifications").document(notification.id).setData(from: notification)
            
            // Send push notification
            await sendPushNotificationToUser(userId: userId, title: title, body: body, data: data)
            
            print("✅ Sent notification to user \(userId): \(title)")
        } catch {
            print("❌ Error sending notification to user: \(error)")
        }
    }
    
    // Push Notifications
    private func sendPushNotificationToAllUsers(
        title: String,
        body: String,
        data: [String: String]?,
        excludeUserId: String?
    ) async {
        // This would typically be implemented on the server side using FCM Admin SDK
        // For now, we'll just log it
        print("📤 Would send push notification to all users: \(title)")
    }
    
    private func sendPushNotificationToUser(
        userId: String,
        title: String,
        body: String,
        data: [String: String]?
    ) async {
        do {
            // Get user's FCM token
            let userDoc = try await db.collection("users").document(userId).getDocument()
            guard let fcmToken = userDoc.data()?["fcmToken"] as? String else {
                print("⚠️ No FCM token found for user: \(userId)")
                return
            }
            
            // This would typically be implemented on the server side using FCM Admin SDK
            print("📤 Would send push notification to \(userId): \(title)")
            
        } catch {
            print("❌ Error sending push notification: \(error)")
        }
    }
    
    //  Convenience Methods for Specific Events
    func notifyNewBiddingProperty(property: AuctionProperty) async {
        let title = "🏠 New Property Available for Bidding!"
        let body = "\(property.title) is now available for auction. Starting bid: $\(Int(property.startingPrice))"
        let data = [
            "propertyId": property.id ?? "",
            "propertyType": "auction",
            "startingBid": "\(property.startingPrice)"
        ]
        
        await sendNotificationToAllUsers(
            title: title,
            body: body,
            type: .newBidding,
            data: data,
            priority: .medium,
            excludeUserId: property.sellerId
        )
    }
    
    func notifyNewSellingProperty(property: SaleProperty) async {
        let title = "🏡 New Property Listed for Sale!"
        let body = "\(property.title) is now available for sale. Price: $\(Int(property.price))"
        let data = [
            "propertyId": property.id ?? "",
            "propertyType": "sale",
            "price": "\(property.price)"
        ]
        
        await sendNotificationToAllUsers(
            title: title,
            body: body,
            type: .newSelling,
            data: data,
            priority: .medium,
            excludeUserId: property.seller.id
        )
    }
    
    func notifyOutbid(userId: String, propertyTitle: String, newBidAmount: Double) async {
        let title = "⚠️ You've been outbid!"
        let body = "Someone bid $\(Int(newBidAmount)) on \(propertyTitle). Place a higher bid to stay in the race!"
        let data = [
            "propertyTitle": propertyTitle,
            "newBidAmount": "\(newBidAmount)"
        ]
        
        await sendNotificationToUser(
            userId: userId,
            title: title,
            body: body,
            type: .outbid,
            data: data,
            priority: .high
        )
    }
    
    func notifyAuctionWon(userId: String, propertyTitle: String, winningBid: Double) async {
        let title = "🎉 Congratulations! You won the auction!"
        let body = "You won the auction for \(propertyTitle) with a bid of $\(Int(winningBid))"
        let data = [
            "propertyTitle": propertyTitle,
            "winningBid": "\(winningBid)"
        ]
        
        await sendNotificationToUser(
            userId: userId,
            title: title,
            body: body,
            type: .auctionWon,
            data: data,
            priority: .urgent
        )
    }
    
    func notifyCommunityEvent(event: CommunityEvent) async {
        let title = "📅 New Community Event"
        let body = "\(event.title) - \(event.description)"
        let data = [
            "eventId": event.id ?? "",
            "eventTitle": event.title
        ]
        
        await sendNotificationToAllUsers(
            title: title,
            body: body,
            type: .communityEvent,
            data: data,
            priority: .medium,
            excludeUserId: event.userId
        )
    }
    
    func notifyGroupMessage(groupId: String, senderName: String, message: String) async {
        // This would typically get group members and send to them
        let title = "💬 New Group Message"
        let body = "\(senderName): \(message)"
        let data = [
            "groupId": groupId,
            "senderName": senderName
        ]
        
        // For now, we'll send to all users (in reality, you'd get group members)
        await sendNotificationToAllUsers(
            title: title,
            body: body,
            type: .groupMessage,
            data: data,
            priority: .medium
        )
    }
}

extension NotificationService {
    // Demo & Sample Data Methods
    
    /// Creates sample notifications for development and demo purposes
    func createSampleNotifications() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let sampleNotifications: [AppNotification] = [
            AppNotification(
                id: UUID().uuidString,
                userId: userId,
                title: "🎉 Auction Won!",
                body: "Congratulations! You won the auction for Beautiful Oceanfront Villa with a bid of $1,250,000. Complete payment within 24 hours.",
                type: .auctionWon,
                data: ["propertyId": "property-001", "winningBid": "1250000"],
                timestamp: Date().addingTimeInterval(-300), // 5 minutes ago
                isRead: false,
                priority: .high
            ),
            AppNotification(
                id: UUID().uuidString,
                userId: userId,
                title: "🔨 You've been outbid!",
                body: "Someone placed a higher bid on Modern Downtown Condo. Current bid: $850,000. Place a new bid to stay in the auction.",
                type: .outbid,
                data: ["propertyId": "property-002", "currentBid": "850000"],
                timestamp: Date().addingTimeInterval(-900), // 15 minutes ago
                isRead: false,
                priority: .high
            ),
            AppNotification(
                id: UUID().uuidString,
                userId: userId,
                title: "⏰ Auction Starting Soon",
                body: "Luxury Penthouse Suite auction starts in 15 minutes. Don't miss out on this premium property!",
                type: .newBidding,
                data: ["propertyId": "property-003", "startTime": "15"],
                timestamp: Date().addingTimeInterval(-1800), // 30 minutes ago
                isRead: true,
                priority: .medium
            ),
            AppNotification(
                id: UUID().uuidString,
                userId: userId,
                title: "🏠 New Property Listed",
                body: "A new property matching your preferences has been listed: Cozy Family Home in Green Valley. Starting at $650,000.",
                type: .newSelling,
                data: ["propertyId": "property-004", "price": "650000"],
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                isRead: true,
                priority: .medium
            ),
            AppNotification(
                id: UUID().uuidString,
                userId: userId,
                title: "📅 Community Event",
                body: "Real Estate Investment Workshop tomorrow at 2 PM. Learn valuable investment strategies from industry experts!",
                type: .communityEvent,
                data: ["eventId": "event-001", "eventTime": "tomorrow"],
                timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                isRead: false,
                priority: .medium
            ),
            AppNotification(
                id: UUID().uuidString,
                userId: userId,
                title: "🎯 Auction Ended",
                body: "The auction for Suburban Family House has ended. Winner: John Doe with $920,000. Better luck next time!",
                type: .auctionEnded,
                data: ["propertyId": "property-005", "winner": "John Doe", "winningBid": "920000"],
                timestamp: Date().addingTimeInterval(-10800), // 3 hours ago
                isRead: true,
                priority: .low
            )
        ]
        
        // Send each sample notification
        for notification in sampleNotifications {
            await sendLocalNotification(notification)
            // Small delay between notifications
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        print("✅ Created \(sampleNotifications.count) sample notifications")
    }
}

// UNUserNotificationCenterDelegate
extension NotificationService: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("📱 Notification tapped: \(userInfo)")
        
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
}

//  MessagingDelegate
extension NotificationService: @preconcurrency MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        self.fcmToken = fcmToken
        print("📱 FCM token refreshed: \(fcmToken)")
        
        Task {
            await updateUserFCMToken(fcmToken)
        }
    }
}
