import SwiftUI

struct PapersListView: View {
    var papers: [Paper]
    var onPaperTap: (Paper) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("研究论文")
                .font(.headline)
                .padding(.horizontal)
            
            if papers.isEmpty {
                Text("正在查找相关论文...")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(papers) { paper in
                            PaperItemView(paper: paper)
                                .onTapGesture {
                                    onPaperTap(paper)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct PaperItemView: View {
    var paper: Paper
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(paper.title)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(isExpanded ? nil : 2)
                    
                    HStack {
                        SourceBadge(source: paper.source ?? "Unknown")
                        Spacer()
                        StatusTag(isSelected: paper.isSelected, isCited: paper.isCited)
                    }
                }
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                Divider()
                    .padding(.horizontal, 14)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Authors and year
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading) {
                            Text("作者")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(paper.authors)
                                .font(.subheadline)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading) {
                            Text("年份")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(paper.year)
                                .font(.subheadline)
                        }
                    }
                    
                    if let abstract = paper.abstract, !abstract.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "doc.text")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading) {
                                Text("摘要")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(abstract)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading) {
                            Text("链接")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Link("查看论文", destination: URL(string: paper.link) ?? URL(string: "https://example.com")!)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(14)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    paper.isSelected ? Color.blue.opacity(0.5) : 
                        (paper.isCited ? Color.green.opacity(0.5) : Color.gray.opacity(0.1)),
                    lineWidth: paper.isSelected || paper.isCited ? 2 : 1
                )
        )
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
            return Color.red.opacity(0.8)
        case "semantic scholar":
            return Color.blue.opacity(0.8)
        case "pubmed":
            return Color.green.opacity(0.8)
        case "ieee xplore":
            return Color.orange.opacity(0.8)
        case "core":
            return Color.purple.opacity(0.8)
        default:
            return Color.gray.opacity(0.8)
        }
    }
}

struct StatusTag: View {
    var isSelected: Bool
    var isCited: Bool
    
    var body: some View {
        if isSelected || isCited {
            Text(isSelected ? "选中" : (isCited ? "引用" : ""))
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                .foregroundColor(isSelected ? Color.blue : Color.green)
                .cornerRadius(4)
        } else {
            Text("未引用")
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(Color.gray)
                .cornerRadius(4)
        }
    }
}

struct PapersListView_Previews: PreviewProvider {
    static var previews: some View {
        PapersListView(
            papers: [
                Paper(
                    id: "1", 
                    title: "Advances in Artificial Intelligence and its Applications in Modern Research",
                    authors: "John Smith, Jane Doe",
                    year: "2023",
                    source: "arXiv",
                    abstract: "This paper explores recent advances in artificial intelligence and how they are being applied to address complex research problems across multiple disciplines.",
                    link: "https://example.com/paper1",
                    isSelected: true
                ),
                Paper(
                    id: "2", 
                    title: "Neural Networks in Healthcare: A Systematic Review",
                    authors: "Robert Johnson, Maria Garcia",
                    year: "2022",
                    source: "PubMed",
                    abstract: "A comprehensive review of how neural networks are being used in healthcare applications, from diagnosis to treatment planning.",
                    link: "https://example.com/paper2",
                    isCited: true
                ),
                Paper(
                    id: "3", 
                    title: "Machine Learning Approaches for Climate Prediction",
                    authors: "David Chen, Sarah Miller",
                    year: "2021",
                    source: "IEEE Xplore",
                    abstract: "This study compares various machine learning techniques for predicting climate patterns and their effectiveness in forecasting extreme weather events.",
                    link: "https://example.com/paper3"
                )
            ],
            onPaperTap: { _ in }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
