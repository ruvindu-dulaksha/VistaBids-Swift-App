import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase is configured in VistaBidsApp.swift init()
        // No need to configure it here to avoid "Default app has already been configured" error
        
        return true
    }
}