import SwiftUI

struct ArticleCardView: View {
    let article: Article
    let isDarkMode: Bool
    
    var body: some View {
        Button(action: {
            if let url = URL(string: article.url) {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .lineLimit(2)
                
                Text(article.content)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(isDarkMode ? .white.opacity(0.8) : Color(hex: "4B5563"))
                    .lineLimit(3)
                
                HStack {
                    Text(article.url)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color(hex: "3B82F6"))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "3B82F6"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                    .shadow(color: isDarkMode ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 