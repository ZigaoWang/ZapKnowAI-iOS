import SwiftUI
import Foundation

struct PapersListView: View {
    var papers: [Paper]
    var onPaperTap: ((Paper) -> Void)?
    @State private var expandedPaperIndex: Int? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        return colorScheme == .dark
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "3B82F6"))
                
                Text("相关论文")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Spacer()
                
                Text("\(papers.count)篇")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F3F4F6"))
                    )
            }
            .padding(.horizontal, 20)
            
            // Papers list
            if papers.isEmpty {
                emptyStateView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(papers.enumerated()), id: \.element.id) { index, paper in
                            PaperItemView(
                                paper: paper,
                                index: index,
                                isExpanded: expandedPaperIndex == index,
                                isDarkMode: isDarkMode
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if expandedPaperIndex == index {
                                        expandedPaperIndex = nil
                                    } else {
                                        expandedPaperIndex = index
                                    }
                                }
                                
                                if let onPaperTap = onPaperTap {
                                    onPaperTap(paper)
                                }
                            }
                            .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .padding(.bottom, 8)
            
            Text("正在查找相关论文...")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(isDarkMode ? .white : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct PaperItemView: View {
    var paper: Paper
    var index: Int
    var isExpanded: Bool
    var isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Paper header
            VStack(alignment: .leading, spacing: 12) {
                // Paper index and title
                HStack(alignment: .top, spacing: 12) {
                    // Paper index
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color(hex: "3B82F6")))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Title
                        Text(paper.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            .lineLimit(isExpanded ? nil : 2)
                        
                        // Authors and year
                        HStack(spacing: 6) {
                            Text(paper.authors)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                                .lineLimit(1)
                            
                            Text("·")
                                .font(.system(size: 13))
                                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                            
                            Text(paper.year)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                        }
                        
                        // Source badge if available
                        if let source = paper.source, !source.isEmpty {
                            SourceBadge(source: source, isDarkMode: isDarkMode)
                        }
                    }
                }
                
                // Expand/collapse indicator
                HStack {
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F3F4F6"))
                        )
                }
            }
            .padding(16)
            
            // Paper details (when expanded)
            if isExpanded {
                Divider()
                    .background(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "E5E7EB"))
                
                VStack(alignment: .leading, spacing: 16) {
                    // Abstract
                    if let abstract = paper.abstract, !abstract.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("摘要")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                            
                            Text(abstract)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // URL
                    if !paper.link.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("链接")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                            
                            if let validURL = URL(string: paper.link) {
                                Link(paper.link, destination: validURL)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(Color(hex: "3B82F6"))
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
        .background(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
        .cornerRadius(16)
        .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct SourceBadge: View {
    var source: String
    var isDarkMode: Bool
    
    var body: some View {
        Text(source)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(Color(hex: "3B82F6"))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isDarkMode ? Color(hex: "3B82F6").opacity(0.2) : Color(hex: "3B82F6").opacity(0.1))
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
