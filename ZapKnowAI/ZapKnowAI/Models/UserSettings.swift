//
//  UserSettings.swift
//  ZapKnowAI
//
//  Created by Zigao Wang on 4/2/25.
//

import Foundation
import SwiftUI

class UserSettings: ObservableObject {
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
    
    init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.hasAgreedToTerms = UserDefaults.standard.bool(forKey: "hasAgreedToTerms")
    }
    
    func resetSettings() {
        userName = ""
        hasCompletedOnboarding = false
        hasAgreedToTerms = false
    }
}
