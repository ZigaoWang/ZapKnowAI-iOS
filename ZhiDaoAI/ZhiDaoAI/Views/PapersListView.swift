import SwiftUI
import Foundation

struct PapersListView: View {
    var papers: [Paper]
    var onPaperTap: (Paper) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "3B82F6"))
                
                Text("研究论文")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : .black)
                
                Spacer()
                
                Text("\(papers.count) 篇")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "3B82F6").opacity(0.1))
                    )
                    .foregroundColor(Color(hex: "3B82F6"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            if papers.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(.bottom, 8)
                    
                    Text("正在查找相关论文...")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    Text("我们正在搜索最相关的学术资源")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Papers list
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(papers.enumerated()), id: \.element.id) { index, paper in
                            PaperItemView(paper: paper, index: index)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        onPaperTap(paper)
                                    }
                                }
                                // Staggered animation for loading papers
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : .white)
                .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct PaperItemView: View {
    var paper: Paper
    var index: Int
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Animation delay based on index
    private var animationDelay: Double {
        return min(Double(index) * 0.1, 0.5)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Paper header
            HStack(alignment: .top, spacing: 12) {
                // Paper icon with status indicator
                ZStack {
                    Circle()
                        .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F5F7FA"))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "3B82F6"))
                    
                    // Status indicator
                    if paper.isSelected || paper.isCited {
                        Circle()
                            .fill(paper.isSelected ? Color(hex: "3B82F6") : Color.green)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(isDarkMode ? Color(hex: "2A2A2A") : .white, lineWidth: 2)
                            )
                            .offset(x: 14, y: -14)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Paper title
                    Text(paper.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : .black)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    // Paper metadata
                    HStack {
                        // Source badge
                        SourceBadge(source: paper.source ?? "Unknown")
                        
                        // Year
                        Text(paper.year)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F0F0F0"))
                            )
                        
                        Spacer()
                        
                        // Status tag
                        StatusTag(isSelected: paper.isSelected, isCited: paper.isCited)
                    }
                }
                
                // Expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F5F7FA"))
                        )
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
            
            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Authors
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("作者")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text(paper.authors)
                                .font(.system(size: 14))
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                    }
                    
                    // Abstract
                    if let abstract = paper.abstract, !abstract.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("摘要")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Text(abstract)
                                    .font(.system(size: 14))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.9) : .black.opacity(0.8))
                                    .lineLimit(6)
                            }
                        }
                    }
                    
                    // Link
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "link")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("链接")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Link("查看论文", destination: URL(string: paper.link) ?? URL(string: "https://example.com")!)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "3B82F6"))
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Spacer()
                        
                        // View paper button
                        Button(action: {}) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 14))
                                
                                Text("查看论文")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "3B82F6"))
                            )
                            .foregroundColor(.white)
                        }
                        
                        // Copy citation button
                        Button(action: {
                            let citation = "\(paper.authors) (\(paper.year)). \(paper.title)."
                            UIPasteboard.general.string = citation
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 14))
                                
                                Text("复制引用")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F0F0F0"))
                            )
                            .foregroundColor(isDarkMode ? .white : .black)
                        }
                    }
                }
                .padding(16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : .white)
                .shadow(color: Color.black.opacity(isDarkMode ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    paper.isSelected ? Color(hex: "3B82F6").opacity(0.5) : 
                        (paper.isCited ? Color.green.opacity(0.5) : Color.clear),
                    lineWidth: paper.isSelected || paper.isCited ? 2 : 0
                )
        )
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
    }
}

struct SourceBadge: View {
    var source: String
    
    var body: some View {
        Text(source)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColorForSource)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var backgroundColorForSource: Color {
        switch source.lowercased() {
        case "arxiv":
            return Color(hex: "E53E3E")
        case "semantic scholar":
            return Color(hex: "3182CE")
        case "pubmed":
            return Color(hex: "38A169")
        case "ieee xplore":
            return Color(hex: "DD6B20")
        case "core":
            return Color(hex: "805AD5")
        default:
            return Color(hex: "718096")
        }
    }
}

struct StatusTag: View {
    var isSelected: Bool
    var isCited: Bool
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        if isSelected || isCited {
            HStack(spacing: 4) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "quote.opening")
                    .font(.system(size: 10))
                
                Text(isSelected ? "选中" : (isCited ? "引用" : ""))
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "3B82F6").opacity(0.15) : Color.green.opacity(0.15))
            )
            .foregroundColor(isSelected ? Color(hex: "3B82F6") : Color.green)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "circle")
                    .font(.system(size: 10))
                
                Text("未引用")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F0F0F0"))
            )
            .foregroundColor(.gray)
        }
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
