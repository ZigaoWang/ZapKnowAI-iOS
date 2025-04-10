import SwiftUI

struct SavedConversationView: View {
    let conversation: SavedConversation
    let isDarkMode: Bool
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            if let onBack = onBack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(NSLocalizedString("返回", comment: "Back button text"))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color(hex: "3B82F6"))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    // Query section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("原始问题", comment: "Original question section title"))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                        
                        HStack(spacing: 10) {
                            Image(systemName: "questionmark.bubble.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "3B82F6"))
                            
                            Text(conversation.query)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                        }
                        .padding()
                        .background(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                        .cornerRadius(12)
                        .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 4)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Image results
                    if !conversation.imageUrls.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("相关图片", comment: "Related images section title"))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            
                            ScrollView(.horizontal) {
                                HStack(spacing: 10) {
                                    ForEach(conversation.imageUrls, id: \.self) { url in
                                        AsyncImage(url: URL(string: url)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 200)
                                                    .cornerRadius(10)
                                            case .failure(_):
                                                // Don't show anything if image failed to load
                                                EmptyView()
                                            case .empty:
                                                ProgressView()
                                                    .frame(height: 200)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    // Articles section
                    if !conversation.articles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("延伸阅读", comment: "Further reading section title"))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            
                            ForEach(conversation.articles) { articleData in
                                SavedArticleCardView(
                                    article: articleData,
                                    isDarkMode: isDarkMode
                                )
                                .padding(.horizontal)
                                .padding(.bottom, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    // Papers section
                    if !conversation.papers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("参考论文", comment: "Reference papers section title"))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            
                            ForEach(conversation.papers) { paper in
                                SavedPaperCardView(
                                    paper: paper,
                                    isDarkMode: isDarkMode
                                )
                                .padding(.horizontal)
                                .padding(.bottom, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    // Answer section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "text.bubble.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "3B82F6"))
                            
                            Text(NSLocalizedString("研究回答", comment: "Research Answer section title"))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            
                            Spacer()
                            
                            // Copy button
                            Button(action: {
                                UIPasteboard.general.string = conversation.answer
                                // Add haptic feedback
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14))
                                    
                                    Text(NSLocalizedString("复制", comment: "Copy button text"))
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F3F4F6"))
                                )
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Answer content
                        VStack(alignment: .leading, spacing: 0) {
                            MarkdownView_Native(markdown: conversation.answer)
                                .padding(20)
                                .environment(\.colorScheme, isDarkMode ? .dark : .light)
                        }
                        .background(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                        .cornerRadius(20)
                        .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

// Card view for saved article
struct SavedArticleCardView: View {
    let article: ArticleData
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

// Card view for saved paper
struct SavedPaperCardView: View {
    let paper: Paper
    let isDarkMode: Bool
    
    var body: some View {
        Button(action: {
            if let url = URL(string: paper.link) {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(paper.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .lineLimit(2)
                
                if let abstract = paper.abstract {
                    Text(abstract)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(isDarkMode ? .white.opacity(0.8) : Color(hex: "4B5563"))
                        .lineLimit(3)
                }
                
                HStack(spacing: 8) {
                    Text(paper.authors)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(hex: "6B7280"))
                        .lineLimit(1)
                    
                    Text("•")
                        .foregroundColor(isDarkMode ? .white.opacity(0.5) : Color(hex: "9CA3AF"))
                    
                    Text(paper.year)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(hex: "6B7280"))
                }
                
                HStack {
                    Text(paper.link)
                        .font(.system(size: 12))
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