import SwiftUI
import Foundation

struct PapersListView: View {
    var papers: [Paper]
    var onPaperTap: ((Paper) -> Void)?
    @State private var expandedPaperIndex: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "3B82F6"))
                
                Text("相关论文")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "111827"))
                
                Spacer()
                
                Text("\(papers.count)篇")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6B7280"))
            }
            .padding(.horizontal, 12)
            
            // Papers list
            LazyVStack(spacing: 8) {
                ForEach(Array(papers.enumerated()), id: \.element.id) { index, paper in
                    PaperItemView(
                        paper: paper,
                        index: index,
                        isExpanded: expandedPaperIndex == index
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
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
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct PaperItemView: View {
    var paper: Paper
    var index: Int
    var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Paper header
            HStack(alignment: .top, spacing: 10) {
                // Paper index
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color(hex: "3B82F6")))
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(paper.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "111827"))
                        .lineLimit(isExpanded ? nil : 2)
                    
                    // Authors and year
                    HStack(spacing: 6) {
                        Text(paper.authors)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "6B7280"))
                            .lineLimit(1)
                        
                        Text("·")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "9CA3AF"))
                        
                        Text(paper.year)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "6B7280"))
                    }
                    
                    // Source badge if available
                    if let source = paper.source, !source.isEmpty {
                        SourceBadge(source: source)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "9CA3AF"))
            }
            .padding(12)
            
            // Paper details (when expanded)
            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Abstract
                    if let abstract = paper.abstract, !abstract.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("摘要")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "6B7280"))
                            
                            Text(abstract)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "111827"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 12)
                    }
                    
                    // URL
                    if !paper.link.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("链接")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "6B7280"))
                            
                            if let validURL = URL(string: paper.link) {
                                Link(paper.link, destination: validURL)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "3B82F6"))
                            } else {
                                Text(paper.link)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "3B82F6"))
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

struct SourceBadge: View {
    var source: String
    
    var body: some View {
        Text(source)
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "3B82F6"))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "3B82F6").opacity(0.1))
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
