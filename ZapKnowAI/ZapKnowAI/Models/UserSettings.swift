//
//  UserSettings.swift
//  ZapKnowAI
//
//  Created by Zigao Wang on 4/2/25.
//

import Foundation
import SwiftUI

class UserSettings: ObservableObject {
    // MARK: - Published Properties
    
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var hasAgreedToTerms: Bool {
        didSet {
            UserDefaults.standard.set(hasAgreedToTerms, forKey: "hasAgreedToTerms")
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    // MARK: - Shared Instance
    
    static let shared = UserSettings()
    
    // MARK: - Initialization
    
    init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.hasAgreedToTerms = UserDefaults.standard.bool(forKey: "hasAgreedToTerms")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    // MARK: - Reset Settings
    
    func resetSettings() {
        userName = ""
        hasCompletedOnboarding = false
        hasAgreedToTerms = false
        // Keep notification setting and dark mode unchanged during reset
    }
}
