//
//  ZapKnowAIApp.swift
//  ZapKnowAI
//
//  Created by Pacer Club on 3/26/24.
//

import SwiftUI
import BackgroundTasks
import UserNotifications

@main
struct ZapKnowAIApp: App {
    @StateObject private var userSettings = UserSettings()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Initialize notification services when app starts
        _ = NotificationService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            if userSettings.hasCompletedOnboarding {
                ContentView(userSettings: userSettings)
                    .preferredColorScheme(.light) // Start with light mode by default
                    .accentColor(.blue)
                    .onAppear {
                        // Check and request notification permissions if needed
                        if userSettings.notificationsEnabled {
                            NotificationService.shared.checkPermissions { granted in
                                if !granted {
                                    NotificationService.shared.requestPermissions { success in
                                        // Update settings based on user response
                                        userSettings.notificationsEnabled = success
                                    }
                                }
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenRequestResults"))) { notification in
                        // Handle opening specific request when notification is tapped
                        if let requestId = notification.userInfo?["requestId"] as? String {
                            // Here you would navigate to the specific conversation
                            print("Opening request results for ID: \(requestId)")
                        }
                    }
            } else {
                OnboardingView(userSettings: userSettings) {
                    // Onboarding completion handler
                    // The UserSettings property is already updated in the OnboardingView
                }
                .preferredColorScheme(.light)
                .accentColor(.blue)
            }
        }
        .backgroundTask(.appRefresh("com.zigaowang.ZapKnowAI.backgroundFetch")) {
            // This is for SwiftUI-based background refresh tasks
            NotificationService.shared.scheduleBackgroundTasks()
            // No return value needed for SwiftUI backgroundTask
        }
    }
}
