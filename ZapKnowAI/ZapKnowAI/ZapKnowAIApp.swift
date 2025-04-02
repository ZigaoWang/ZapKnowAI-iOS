//
//  ZapKnowAIApp.swift
//  ZapKnowAI
//
//  Created by Pacer Club on 3/26/24.
//

import SwiftUI

@main
struct ZapKnowAIApp: App {
    @StateObject private var userSettings = UserSettings()
    
    var body: some Scene {
        WindowGroup {
            if userSettings.hasCompletedOnboarding {
                ContentView(userSettings: userSettings)
                    .preferredColorScheme(.light) // Start with light mode by default
                    .accentColor(.blue)
            } else {
                OnboardingView(userSettings: userSettings) {
                    // Onboarding completion handler
                    // The UserSettings property is already updated in the OnboardingView
                }
                .preferredColorScheme(.light)
                .accentColor(.blue)
            }
        }
    }
}
