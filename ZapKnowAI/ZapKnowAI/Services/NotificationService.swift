//
//  NotificationService.swift
//  ZapKnowAI
//
//  Created by Zigao Wang on 4/3/25.
//

import Foundation
import UserNotifications
import BackgroundTasks

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    // Keys for background tasks
    private let backgroundTaskIdentifier = "com.zigaowang.ZapKnowAI.backgroundFetch"
    private let requestProcessingTaskIdentifier = "com.zigaowang.ZapKnowAI.requestProcessing"
    
    // Keys for UserDefaults
    private let activeRequestsKey = "activeRequests"
    
    // Notification categories and actions
    private let categoryIdentifier = "REQUEST_COMPLETED"
    private let viewActionIdentifier = "VIEW_ACTION"
    
    private override init() {
        super.init()
        registerForNotifications()
        configureBackgroundTasks()
    }
    
    // Request notification permissions
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
                if granted {
                    self.configureNotificationCategories()
                }
            }
        }
    }
    
    // Check current notification permissions
    func checkPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isAuthorized = settings.authorizationStatus == .authorized || 
                              settings.authorizationStatus == .provisional
            DispatchQueue.main.async {
                completion(isAuthorized)
            }
        }
    }
    
    // Register for background notifications
    private func registerForNotifications() {
        // Set up notification categories with actions
        configureNotificationCategories()
        
        // Register as delegate to handle notification responses
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Configure notification categories and actions
    private func configureNotificationCategories() {
        // Action to view the completed request
        let viewAction = UNNotificationAction(
            identifier: viewActionIdentifier,
            title: NSLocalizedString("View Results", comment: "View completed request action"),
            options: .foreground
        )
        
        // Category for completed requests
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // Configure background task handling
    private func configureBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundFetch(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: requestProcessingTaskIdentifier, using: nil) { task in
            self.handleProcessingTask(task: task as! BGProcessingTask)
        }
    }
    
    // Schedule background fetch
    func scheduleBackgroundTasks() {
        scheduleAppRefresh()
        scheduleBackgroundProcessing()
    }
    
    // Schedule app refresh for periodic checks
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes minimum
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background fetch scheduled")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    // Schedule background processing for longer tasks
    private func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: requestProcessingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background processing scheduled")
        } catch {
            print("Could not schedule background processing: \(error)")
        }
    }
    
    // Handle background app refresh
    private func handleBackgroundFetch(task: BGAppRefreshTask) {
        // Schedule a new refresh before we execute this one
        scheduleAppRefresh()
        
        // Create a task expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Check for completed requests
        checkRequestStatus { success in
            task.setTaskCompleted(success: success)
        }
    }
    
    // Handle background processing task
    private func handleProcessingTask(task: BGProcessingTask) {
        // Schedule a new processing task
        scheduleBackgroundProcessing()
        
        // Create a task expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Process pending requests
        processRequests { success in
            task.setTaskCompleted(success: success)
        }
    }
    
    // Process pending requests in the background
    private func processRequests(completion: @escaping (Bool) -> Void) {
        // Get active requests
        guard let activeRequests = getActiveRequests(), !activeRequests.isEmpty else {
            completion(true)
            return
        }
        
        // Create a dispatch group to wait for all requests
        let group = DispatchGroup()
        var overallSuccess = true
        
        for requestInfo in activeRequests {
            group.enter()
            
            // Check if this request is complete
            checkRequestCompletion(requestInfo: requestInfo) { success, isComplete in
                if !success {
                    overallSuccess = false
                }
                
                if isComplete {
                    // Send notification that the request is complete
                    self.sendCompletionNotification(for: requestInfo)
                    
                    // Remove this request from active requests
                    self.removeActiveRequest(requestId: requestInfo.id)
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(overallSuccess)
        }
    }
    
    // Check request status
    private func checkRequestStatus(completion: @escaping (Bool) -> Void) {
        processRequests(completion: completion)
    }
    
    // Track a new request in the background
    func trackRequest(requestId: String, query: String) {
        var activeRequests = getActiveRequests() ?? []
        
        // Create a new request info object
        let requestInfo = RequestInfo(
            id: requestId,
            query: query,
            timestamp: Date()
        )
        
        // Add to active requests
        activeRequests.append(requestInfo)
        saveActiveRequests(activeRequests)
        
        // Schedule background tasks
        scheduleBackgroundTasks()
    }
    
    // Stop tracking a request when completed or canceled
    func stopTrackingRequest(requestId: String) {
        removeActiveRequest(requestId: requestId)
    }
    
    // Handle request completion and send notification
    func requestCompleted(requestId: String) {
        // Get active requests
        guard let activeRequests = getActiveRequests() else { return }
        
        // Find the specific request
        guard let requestInfo = activeRequests.first(where: { $0.id == requestId }) else { return }
        
        // Send notification
        sendCompletionNotification(for: requestInfo)
        
        // Remove from active requests
        stopTrackingRequest(requestId: requestId)
    }
    
    // Check if a specific request is complete
    private func checkRequestCompletion(requestInfo: RequestInfo, completion: @escaping (Bool, Bool) -> Void) {
        // For demo purposes, we'll have the ZhiDaoService handle this
        // In a real implementation, you would make a network request to check status
        ZhiDaoService.shared.checkRequestStatus(requestId: requestInfo.id) { success, isComplete in
            completion(success, isComplete)
        }
    }
    
    // Send a notification when a request is completed
    private func sendCompletionNotification(for requestInfo: RequestInfo) {
        // Check if notifications are enabled in UserSettings
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else {
            print("Notifications are disabled in user settings")
            return
        }
        
        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("回答已准备就绪", comment: "Answer is ready notification title")
        content.body = String(format: NSLocalizedString("您对于 '%@' 的问题已有答案", comment: "Format for question answered notification"), requestInfo.query)
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = categoryIdentifier
        
        // Store the request ID in the notification for retrieval when tapped
        content.userInfo = ["requestId": requestInfo.id]
        
        // Create an immediate trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create the request
        let identifier = "request-\(requestInfo.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add the request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            } else {
                print("Successfully scheduled notification for request: \(requestInfo.id)")
            }
        }
    }
    
    // Get active requests from UserDefaults
    private func getActiveRequests() -> [RequestInfo]? {
        guard let data = UserDefaults.standard.data(forKey: activeRequestsKey) else { return nil }
        
        do {
            return try JSONDecoder().decode([RequestInfo].self, from: data)
        } catch {
            print("Error decoding active requests: \(error)")
            return nil
        }
    }
    
    // Save active requests to UserDefaults
    private func saveActiveRequests(_ requests: [RequestInfo]) {
        do {
            let data = try JSONEncoder().encode(requests)
            UserDefaults.standard.set(data, forKey: activeRequestsKey)
        } catch {
            print("Error encoding active requests: \(error)")
        }
    }
    
    // Remove an active request
    private func removeActiveRequest(requestId: String) {
        guard var activeRequests = getActiveRequests() else { return }
        
        activeRequests.removeAll { $0.id == requestId }
        saveActiveRequests(activeRequests)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Always show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification response
        let requestId = response.notification.request.identifier
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case viewActionIdentifier:
            // Handle "View Results" action - would open the specific conversation
            if let requestId = userInfo["requestId"] as? String {
                NotificationCenter.default.post(name: NSNotification.Name("OpenRequestResults"), object: nil, userInfo: ["requestId": requestId])
            }
        default:
            // Default action (notification tapped) - open the app
            break
        }
        
        // Clear badge count
        UNUserNotificationCenter.current().setBadgeCount(0)
        
        completionHandler()
    }
}

// MARK: - Request Info Model
struct RequestInfo: Codable, Identifiable {
    let id: String
    let query: String
    let timestamp: Date
}
