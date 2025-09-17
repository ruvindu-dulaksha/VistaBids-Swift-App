import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Shared data manager for communication between main app and Intent Extension
class SharedDataManager {
    static let shared = SharedDataManager()
    private let userDefaults = UserDefaults(suiteName: "group.co.dulaksha.VistaBids")
    
    private init() {}
    
    // User Session Management
    func saveUserSession(userId: String, email: String) {
        userDefaults?.set(userId, forKey: "currentUserId")
        userDefaults?.set(email, forKey: "currentUserEmail")
        userDefaults?.set(Date(), forKey: "lastLoginDate")
    }
    
    func getCurrentUserId() -> String? {
        return userDefaults?.string(forKey: "currentUserId")
    }
    
    func getCurrentUserEmail() -> String? {
        return userDefaults?.string(forKey: "currentUserEmail")
    }
    
    func isUserLoggedIn() -> Bool {
        return getCurrentUserId() != nil
    }
    
    func clearUserSession() {
        userDefaults?.removeObject(forKey: "currentUserId")
        userDefaults?.removeObject(forKey: "currentUserEmail")
        userDefaults?.removeObject(forKey: "lastLoginDate")
    }
    
    // MARK: - Quick Access Data
    func saveRecentProperties(_ properties: [String: Any]) {
        userDefaults?.set(properties, forKey: "recentProperties")
    }
    
    func getRecentProperties() -> [String: Any]? {
        return userDefaults?.dictionary(forKey: "recentProperties")
    }
    
    func saveUserBids(_ bids: [String: Any]) {
        userDefaults?.set(bids, forKey: "userBids")
    }
    
    func getUserBids() -> [String: Any]? {
        return userDefaults?.dictionary(forKey: "userBids")
    }
}
