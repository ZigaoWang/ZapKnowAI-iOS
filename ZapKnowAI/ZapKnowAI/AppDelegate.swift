//
//  AppDelegate.swift
//  ZapKnowAI
//
//  Created by Zigao Wang on 4/3/25.
//

import UIKit
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Reset badge count on app launch
        UNUserNotificationCenter.current().setBadgeCount(0)
        
        // Register for background tasks
        registerBackgroundTasks()
        
        return true
    }
    
    // Register background tasks
    private func registerBackgroundTasks() {
        // Make sure the NotificationService is initialized
        _ = NotificationService.shared
        
        // Register for scene lifecycle notifications
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(sceneWillResignActive), 
                                               name: UIScene.willDeactivateNotification, 
                                               object: nil)
    }
    
    @objc func sceneWillResignActive(_ notification: Notification) {
        // Schedule background tasks when app goes to background
        NotificationService.shared.scheduleBackgroundTasks()
    }
    
    // Handle push notification registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // For integration with backend services, you would save this token
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // Handle silent notifications for background updates
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Check for active requests when receiving a silent notification
        NotificationService.shared.checkPermissions { granted in
            if granted {
                // Only process if notifications are allowed
                NotificationService.shared.scheduleBackgroundTasks()
                completionHandler(.newData)
            } else {
                completionHandler(.noData)
            }
        }
    }
}
