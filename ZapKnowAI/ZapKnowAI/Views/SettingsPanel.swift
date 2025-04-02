import SwiftUI

struct SettingsPanel: View {
    @Binding var isVisible: Bool
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isVisible = false
                    }
                }
            
            // Settings panel
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text(NSLocalizedString("设置", comment: "Settings title"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isVisible = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isDarkMode ? .white.opacity(0.8) : Color(hex: "4B5563"))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                            )
                    }
                }
                .padding(.bottom, 16)
                
                // About section
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("关于", comment: "About section title"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    HStack(spacing: 16) {
                        // App logo with fallback
                        Group {
                            if let _ = UIImage(named: "AppLogo") {
                                Image("AppLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(10)
                            } else {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: "3B82F6"))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                                    )
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("知道 AI", comment: "App name"))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            
                            Text(NSLocalizedString("版本 1.0.0", comment: "Version number"))
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color(hex: "6B7280"))
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Text(NSLocalizedString("由 Zigao Wang 开发", comment: "Developer credit"))
                        .font(.system(size: 14))
                        .foregroundColor(isDarkMode ? Color(hex: "D1D5DB") : Color(hex: "6B7280"))
                }
                .padding(.bottom, 24)
                
                // Links section
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString("链接", comment: "Links section title"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    LinkButton(
                        icon: "link",
                        title: NSLocalizedString("GitHub 主页", comment: "GitHub profile link"),
                        url: "https://github.com/zigaowang",
                        isDarkMode: isDarkMode
                    )
                    
                    LinkButton(
                        icon: "envelope",
                        title: NSLocalizedString("联系开发者", comment: "Contact developer link"),
                        url: "mailto:info@example.com",
                        isDarkMode: isDarkMode
                    )
                }
                
                Spacer()
                
                // Footer text
                Text(NSLocalizedString("© 2025 知道 AI. 保留所有权利", comment: "Copyright notice"))
                    .font(.system(size: 12))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.5) : Color(hex: "9CA3AF"))
                    .padding(.top, 16)
            }
            .padding(24)
            .frame(width: 320)
            .background(isDarkMode ? Color(hex: "1A1A1A") : Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 0)
        }
        .transition(.opacity)
    }
}

// Link button component
struct LinkButton: View {
    let icon: String
    let title: String
    let url: String
    let isDarkMode: Bool
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "3B82F6"))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "374151"))
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.5) : Color(hex: "9CA3AF"))
            }
            .padding(.vertical, 12)
        }
    }
} 