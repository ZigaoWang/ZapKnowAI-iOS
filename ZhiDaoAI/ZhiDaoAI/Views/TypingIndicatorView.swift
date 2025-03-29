import SwiftUI
import Foundation

struct TypingIndicatorView: View {
    @State private var showFirstDot = false
    @State private var showSecondDot = false
    @State private var showThirdDot = false
    
    var body: some View {
        HStack(spacing: 4) {
            // Animated dots
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(hex: "3B82F6"))
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale(for: index))
                    .opacity(dotOpacity(for: index))
                    .animation(
                        Animation
                            .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: index == 0 ? showFirstDot : (index == 1 ? showSecondDot : showThirdDot)
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "3B82F6").opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            startAnimation()
        }
    }
    
    private func dotScale(for index: Int) -> CGFloat {
        switch index {
        case 0:
            return showFirstDot ? 1.2 : 0.8
        case 1:
            return showSecondDot ? 1.2 : 0.8
        case 2:
            return showThirdDot ? 1.2 : 0.8
        default:
            return 1.0
        }
    }
    
    private func dotOpacity(for index: Int) -> Double {
        switch index {
        case 0:
            return showFirstDot ? 1.0 : 0.5
        case 1:
            return showSecondDot ? 1.0 : 0.5
        case 2:
            return showThirdDot ? 1.0 : 0.5
        default:
            return 1.0
        }
    }
    
    private func startAnimation() {
        withAnimation {
            showFirstDot = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                showSecondDot = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                showThirdDot = true
            }
        }
    }
}

// Enhanced version with text label
struct TypingIndicatorWithLabel: View {
    var message: String = "正在生成回答"
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Text label
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isDarkMode ? .white.opacity(0.9) : .black.opacity(0.8))
            
            // Typing indicator
            TypingIndicatorView()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "3B82F6").opacity(0.2), lineWidth: 1)
        )
    }
}

// Floating typing indicator that appears at the bottom of the answer
struct FloatingTypingIndicator: View {
    @Binding var isVisible: Bool
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        TypingIndicatorWithLabel()
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
            .padding(.bottom, 8)
    }
}

struct TypingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TypingIndicatorView()
                .previewDisplayName("Basic Indicator")
            
            TypingIndicatorWithLabel()
                .previewDisplayName("With Label")
            
            TypingIndicatorWithLabel(message: "正在分析论文")
                .previewDisplayName("Custom Message")
            
            FloatingTypingIndicator(isVisible: .constant(true))
                .previewDisplayName("Floating Indicator")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
