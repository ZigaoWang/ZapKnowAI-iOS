import SwiftUI
import Foundation

struct PapersListView: View {
    var papers: [Paper]
    var onPaperTap: ((Paper) -> Void)?
    @State private var expandedPaperIndex: Int? = nil
    @State private var animatePapers: Bool = false
    @State private var selectedPaper: Paper? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        return colorScheme == .dark
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header bar
            HStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "3B82F6"))
                
                Text(NSLocalizedString("相关论文", comment: "Related papers section title"))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Spacer()
                
                // Paper count badge
                Text(String(format: NSLocalizedString("%d篇论文", comment: "Paper count label"), papers.count))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "4B5563"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isDarkMode ? Color(hex: "1E293B") : Color(hex: "EFF6FF"))
                    )
            }
            .padding(.horizontal, 20)
            .opacity(animatePapers ? 1 : 0)
            
            // Paper list
            if papers.isEmpty {
                emptyStateView
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Horizontal scrolling view
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(papers.enumerated()), id: \.element.id) { index, paper in
                                PaperCardView(
                                    paper: paper,
                                    index: index,
                                    isExpanded: expandedPaperIndex == index,
                                    isDarkMode: isDarkMode,
                                    isSelected: selectedPaper?.id == paper.id
                                )
                                .onTapGesture {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if expandedPaperIndex == index {
                                            expandedPaperIndex = nil
                                        } else {
                                            expandedPaperIndex = index
                                        }
                                        selectedPaper = paper
                                    }
                                    
                                    if let onPaperTap = onPaperTap {
                                        onPaperTap(paper)
                                    }
                                }
                                .frame(width: 280)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                    
                    // Hint text
                    if papers.count > 1 {
                        Text(NSLocalizedString("← 滑动查看更多论文", comment: "Swipe to view more papers hint"))
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                            .padding(.leading, 20)
                            .padding(.bottom, 8)
                            .opacity(0.7)
                    }
                }
                .opacity(animatePapers ? 1 : 0)
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), 
                        radius: 12, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                animatePapers = true
            }
        }
        .onChange(of: papers.count) { _, _ in
            // Reset and start animation
            animatePapers = false
            withAnimation(.easeIn(duration: 0.3)) {
                animatePapers = true
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            // Loading indicator
            ProgressView()
                .scaleEffect(1.2)
            
            Text(NSLocalizedString("正在查找相关论文...", comment: "Loading state for paper search"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(isDarkMode ? .white : Color(hex: "4B5563"))
            
            Text(NSLocalizedString("我们正在搜索与您的问题相关的论文", comment: "Loading message for paper search"))
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .opacity(animatePapers ? 1 : 0)
    }
}

// Paper card view
struct PaperCardView: View {
    var paper: Paper
    var index: Int
    var isExpanded: Bool
    var isDarkMode: Bool
    var isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Paper header
            VStack(alignment: .leading, spacing: 12) {
                // Paper index and title
                HStack(alignment: .top, spacing: 12) {
                    // Paper index
                    Text("\(index + 1)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color(hex: "3B82F6")))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Title
                        Text(paper.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            .lineLimit(isExpanded ? 4 : 2)
                        
                        // Authors and year
                        HStack(spacing: 6) {
                            Text(paper.authors)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                                .lineLimit(1)
                            
                            Text("·")
                                .font(.system(size: 14))
                                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                            
                            Text(paper.year)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                        }
                        
                        // Source label
                        if let source = paper.source, !source.isEmpty {
                            EnhancedSourceBadge(source: source, isDarkMode: isDarkMode)
                        }
                    }
                }
                
                // Expand/collapse indicator
                HStack {
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F3F4F6"))
                        )
                }
            }
            .padding(16)
            
            // Paper details when expanded
            if isExpanded {
                Divider()
                    .background(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "E5E7EB"))
                
                VStack(alignment: .leading, spacing: 16) {
                    // Abstract
                    if let abstract = paper.abstract, !abstract.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 12))
                                    .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                                
                                Text(NSLocalizedString("摘要", comment: "Abstract section title"))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                            }
                            
                            Text(abstract)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isDarkMode ? Color(hex: "1A1A1A") : Color(hex: "F9FAFB"))
                                )
                        }
                    }
                    
                    // URL
                    if !paper.link.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                    .font(.system(size: 12))
                                    .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                                
                                Text(NSLocalizedString("原文链接", comment: "Original link section title"))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                            }
                            
                            if let validURL = URL(string: paper.link) {
                                Button {
                                    UIApplication.shared.open(validURL)
                                } label: {
                                    HStack {
                                        Text(NSLocalizedString("在浏览器中打开", comment: "Open in browser button"))
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(Color(hex: "3B82F6"))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isDarkMode ? Color(hex: "1E293B") : Color(hex: "EFF6FF"))
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            } else {
                                Text(paper.link)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(Color(hex: "3B82F6"))
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isSelected ? Color(hex: "3B82F6").opacity(0.4) : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), 
                        radius: 8, x: 0, y: 2)
        )
        // Simple selected indicator for selected paper
        .overlay(
            isSelected ?
                Circle()
                    .fill(Color(hex: "3B82F6"))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .offset(x: 10, y: -10)
                : nil
        )
    }
}

// Enhanced source label
struct EnhancedSourceBadge: View {
    var source: String
    var isDarkMode: Bool
    
    private var sourceInfo: (name: String, color: Color, icon: String) {
        switch source.lowercased() {
        case "arxiv":
            return ("arXiv", Color(hex: "B7791F"), "doc.richtext")
        case "pubmed":
            return ("PubMed", Color(hex: "0369A1"), "heart.text.square")
        case "acm":
            return ("ACM", Color(hex: "4338CA"), "server.rack")
        case "ieee":
            return ("IEEE", Color(hex: "0C4A6E"), "network")
        case "sciencedirect":
            return ("Science Direct", Color(hex: "B91C1C"), "book.closed")
        case "springer":
            return ("Springer", Color(hex: "A16207"), "books.vertical")
        default:
            return (source, Color(hex: "525252"), "doc")
        }
    }
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: sourceInfo.icon)
                .font(.system(size: 10))
            
            Text(sourceInfo.name)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(sourceInfo.color)
        )
    }
}

struct PapersListView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PapersListView(
                papers: [
                    Paper(id: "1", title: "Quantum Computing Applications in Cryptography", authors: "Smith, J., Johnson, A.", year: "2023", source: "arXiv", abstract: "This paper explores the applications of quantum computing in modern cryptography, focusing on the implications for security systems.", link: "https://example.com", isSelected: true),
                    Paper(id: "2", title: "Deep Learning Approaches for Natural Language Processing", authors: "Wang, L., Chen, H.", year: "2022", source: "IEEE Xplore", abstract: "A comprehensive survey of deep learning techniques applied to natural language processing tasks.", link: "https://example.com", isCited: true)
                ],
                onPaperTap: { _ in }
            )
            .padding()
            
            PapersListView(
                papers: [],
                onPaperTap: { _ in }
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
