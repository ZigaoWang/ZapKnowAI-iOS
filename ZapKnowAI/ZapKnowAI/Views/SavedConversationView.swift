import SwiftUI
import Combine

struct SavedConversationView: View {
    let conversation: SavedConversation
    let isDarkMode: Bool
    var onBack: (() -> Void)? = nil
    @StateObject private var userSettings = UserSettings() // Needed for previews and potentially dark mode state
    
    // State for UI elements similar to ContentView
    @State private var isSourcesExpanded = false
    @State private var isPapersExpanded = false
    @State private var isArticlesExpanded = false
    @State private var isPaperAnalysisExpanded = true
    @State private var showingImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var paperAnalysisContent = ""
    @State private var synthesisContent = ""
    @State private var isPaperAnalysisComplete = false // Track if split happened
    
    // Extracted data from conversation
    private var imageUrls: [String] { conversation.imageUrls }
    private var articles: [ArticleData] { conversation.articles }
    private var papers: [Paper] { conversation.papers }
    private var query: String { conversation.query }
    private var answer: String { conversation.answer }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Original Query Section (optional - could be in header)
                    // Or keep it simple here
                    querySectionView
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    // Images display (Copied & Adapted from ContentView)
                    if !imageUrls.isEmpty {
                        imageSectionView
                            .padding(.vertical, 8)
                    }
                    
                    // Sources section (Copied & Adapted from ContentView)
                    if !papers.isEmpty || !articles.isEmpty {
                        collapsedSourcesSection
                            .padding(.bottom, 8) // Add some spacing
                    }
                    
                    // Paper Analysis section (Copied & Adapted)
                    if !paperAnalysisContent.isEmpty {
                        paperAnalysisView
                    }
                    
                    // Synthesis (final answer) section (Copied & Adapted)
                    if !synthesisContent.isEmpty {
                        synthesisView
                    }
                    
                    Spacer().frame(height: 20) // Bottom padding
                }
            }
            .background(Color(hex: isDarkMode ? "121212" : "F9F9F9")) // Match background
        }
        .onAppear {
            processSavedAnswer(answer)
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            // Ensure ImageViewerView is available or copy it here
            ImageViewerView(urls: imageUrls, currentIndex: $selectedImageIndex)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light) // Apply color scheme
    }
    
    // MARK: - Helper Functions (Copied & Adapted)
    
    private func processSavedAnswer(_ text: String) {
        if let synthesisRange = text.range(of: "SYNTHESIS:", options: .caseInsensitive) {
            let paperAnalysisEnd = synthesisRange.lowerBound
            paperAnalysisContent = String(text[..<paperAnalysisEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let synthesisStart = text.index(after: synthesisRange.upperBound)
            if synthesisStart < text.endIndex {
                synthesisContent = String(text[synthesisStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            isPaperAnalysisComplete = true
            isPaperAnalysisExpanded = false // Collapse analysis by default when viewing history
        } else {
            // No marker, treat the whole thing as the synthesis/answer
            paperAnalysisContent = "" // Clear analysis
            synthesisContent = text
            isPaperAnalysisComplete = true // Mark as complete for consistency
            isPaperAnalysisExpanded = false
        }
    }
    
    private func shortenConversationQuery(_ query: String) -> String {
        let maxLength = 25 // Shorten slightly more for header title
        if query.count <= maxLength {
            return query
        } else {
            let endIndex = query.index(query.startIndex, offsetBy: maxLength)
            return String(query[..<endIndex]) + "..."
        }
    }
    
    // MARK: - Copied & Adapted View Components
    
    private var querySectionView: some View {
         VStack(alignment: .leading, spacing: 8) {
             Text(NSLocalizedString("Original Question", comment: "Original question section title"))
                 .font(.system(size: 16, weight: .semibold))
                 .foregroundColor(isDarkMode ? .white.opacity(0.8) : Color(hex: "374151"))

             HStack(spacing: 12) {
                 Image(systemName: "questionmark.bubble.fill")
                     .font(.system(size: 18))
                     .foregroundColor(Color(hex: "3B82F6"))
                     .frame(width: 24, alignment: .center)

                 Text(query)
                     .font(.system(size: 16))
                     .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                 Spacer()
             }
             .padding(16)
             .background(
                 RoundedRectangle(cornerRadius: 12)
                     .fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
             )
             .overlay(
                 RoundedRectangle(cornerRadius: 12)
                     .stroke(isDarkMode ? Color(hex: "333333") : Color(hex: "E5E7EB"), lineWidth: 1)
             )
         }
     }

    private var imageSectionView: some View {
         VStack(alignment: .leading, spacing: 12) {
             HStack {
                 Image(systemName: "photo.on.rectangle")
                     .font(.system(size: 18))
                     .foregroundColor(Color(hex: "3B82F6"))

                 Text(NSLocalizedString("Related Images", comment: "Related images"))
                     .font(.system(size: 18, weight: .semibold))
                     .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
             }
             .padding(.horizontal, 16)

             ScrollView(.horizontal, showsIndicators: false) {
                 HStack(spacing: 12) {
                     ForEach(imageUrls.indices, id: \.self) { index in // Use indices
                         let url = imageUrls[index]
                         AsyncImage(url: URL(string: url)) { phase in
                             switch phase {
                             case .success(let image):
                                 image
                                     .resizable()
                                     .scaledToFill()
                             case .failure(_):
                                 Rectangle()
                                     .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                                     .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                             case .empty:
                                 Rectangle()
                                     .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                                     .overlay(ProgressView())
                             @unknown default:
                                 EmptyView()
                             }
                         }
                         .frame(width: 200, height: 150)
                         .clipped()
                         .cornerRadius(12)
                         .shadow(color: isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                         .padding(.leading, index == 0 ? 16 : 0)
                         .padding(.trailing, index == imageUrls.count - 1 ? 16 : 0)
                         .onTapGesture {
                             selectedImageIndex = index
                             showingImageViewer = true
                         }
                     }
                 }
                 .padding(.vertical, 8)
             }
         }
     }
    
    private var collapsedSourcesSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation {
                    isSourcesExpanded.toggle()
                    if !isSourcesExpanded {
                        isPapersExpanded = false
                        isArticlesExpanded = false
                    }
                }
            }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "3B82F6"))
                    Text(NSLocalizedString("Sources", comment: "Sources section header"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    Spacer()
                    Text("\(papers.count + articles.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6")))
                    Image(systemName: isSourcesExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isDarkMode ? Color(hex: "333333") : Color(hex: "E5E7EB"), lineWidth: 1))
                .padding(.horizontal, 16)
            }
            .buttonStyle(ScaleButtonStyle()) // Assuming ScaleButtonStyle is globally available or copied
            
            if isSourcesExpanded {
                VStack(spacing: 16) {
                    if !papers.isEmpty { papersSection }
                    if !articles.isEmpty { articlesSection }
                }
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var papersSection: some View {
        VStack(spacing: 8) {
            Button(action: { withAnimation { isPapersExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "3B82F6"))
                    Text(NSLocalizedString("Reference Papers", comment: "Reference papers"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    Spacer()
                    Text("\(papers.count)").font(.system(size: 14, weight: .semibold)).foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                    Image(systemName: isPapersExpanded ? "chevron.up" : "chevron.down").font(.system(size: 14, weight: .semibold)).foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(isDarkMode ? Color(hex: "262626") : Color(hex: "F3F4F6")))
            }
            .buttonStyle(ScaleButtonStyle())
            
            if isPapersExpanded {
                 // Use the existing or copied PapersListView if available
                 // For now, using the simpler Card view from original SavedConversationView
                 VStack(spacing: 8) {
                     ForEach(papers) { paper in
                         SavedPaperCardView(paper: paper, isDarkMode: isDarkMode)
                     }
                 }
                 .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var articlesSection: some View {
        VStack(spacing: 8) {
            Button(action: { withAnimation { isArticlesExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "book")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "3B82F6"))
                    Text(NSLocalizedString("Further Reading", comment: "Further reading"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    Spacer()
                    Text("\(articles.count)").font(.system(size: 14, weight: .semibold)).foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                    Image(systemName: isArticlesExpanded ? "chevron.up" : "chevron.down").font(.system(size: 14, weight: .semibold)).foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(isDarkMode ? Color(hex: "262626") : Color(hex: "F3F4F6")))
            }
            .buttonStyle(ScaleButtonStyle())
            
            if isArticlesExpanded {
                VStack(spacing: 8) {
                    ForEach(articles) { article in
                        // Use the existing or copied ArticleCardView
                        SavedArticleCardView(article: article, isDarkMode: isDarkMode)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var paperAnalysisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: { withAnimation { isPaperAnalysisExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass").font(.system(size: 18)).foregroundColor(Color(hex: "3B82F6"))
                    Text(NSLocalizedString("Paper Analysis", comment: "Paper analysis")).font(.system(size: 18, weight: .semibold)).foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    Spacer()
                    // No typing indicator needed for saved view
                    Image(systemName: isPaperAnalysisExpanded ? "chevron.up" : "chevron.down").font(.system(size: 14, weight: .semibold)).foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                }
                .padding(.horizontal, 24).padding(.top, 24)
            }
            .buttonStyle(ScaleButtonStyle())
            
            if isPaperAnalysisExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    MarkdownView_Native(markdown: paperAnalysisContent)
                        .padding(24)
                        .environment(\.colorScheme, isDarkMode ? .dark : .light)
                }
                .background(RoundedRectangle(cornerRadius: 20).fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isDarkMode ? Color(hex: "333333") : Color(hex: "E5E7EB"), lineWidth: 1))
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var synthesisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "text.bubble.fill").font(.system(size: 18)).foregroundColor(Color(hex: "3B82F6"))
                Text(NSLocalizedString("Research Answer", comment: "Research answer")).font(.system(size: 18, weight: .semibold)).foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = synthesisContent
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc").font(.system(size: 14))
                        Text(NSLocalizedString("Copy", comment: "Copy button")).font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6")))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                }.buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 24).padding(.top, 24)
            
            VStack(alignment: .leading, spacing: 0) {
                MarkdownView_Native(markdown: synthesisContent)
                    .padding(24)
                    .environment(\.colorScheme, isDarkMode ? .dark : .light)
            }
            .background(RoundedRectangle(cornerRadius: 20).fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isDarkMode ? Color(hex: "333333") : Color(hex: "E5E7EB"), lineWidth: 1))
            .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Reusable Components (Keep or Ensure Global Access)

// Keep existing Card views or ensure PapersListView/ArticleCardView are adapted/global
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

// MARK: - Preview Provider
struct SavedConversationView_Previews: PreviewProvider {
    static var previews: some View {
        // Create some sample data
        let samplePaper = Paper(
            id: "sample-123", // Provide a sample ID
            title: "Sample Paper Title about Quantum Stuff", 
            authors: "Doe, J.", // Provide sample authors
            year: "2024", // Provide sample year
            source: "arXiv", // Optional
            abstract: "This is a sample abstract for the paper.", // Optional
            link: "https://example.com/paper" // Provide sample link
        )
        let sampleArticle = ArticleData(id: UUID(), title: "Sample Article Title", url: "https://example.com/article", content: "Article content snippet.")
        let sampleConversation = SavedConversation(
            id: UUID(),
            query: "What is quantum computing?",
            timestamp: Date(),
            answer: "Paper Analysis: Quantum computing is complex. SYNTHESIS: It uses qubits.",
            papers: [samplePaper],
            imageUrls: ["https://via.placeholder.com/200x150.png/0000FF/808080?text=Image+1", "https://via.placeholder.com/200x150.png/FF0000/FFFFFF?text=Image+2"],
            articles: [sampleArticle],
            completedStages: [ProgressStage.paperRetrieval.rawValue, ProgressStage.paperAnalysis.rawValue, ProgressStage.answerGeneration.rawValue]
        )
        
        SavedConversationView(
            conversation: sampleConversation,
            isDarkMode: false,
            onBack: { print("Back tapped") }
        )
        .environmentObject(UserSettings()) // Provide UserSettings for preview
        
        SavedConversationView(
            conversation: sampleConversation,
            isDarkMode: true,
            onBack: { print("Back tapped") }
        )
        .environmentObject(UserSettings()) // Provide UserSettings for preview
    }
} 