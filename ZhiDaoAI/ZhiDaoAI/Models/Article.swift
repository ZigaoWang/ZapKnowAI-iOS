import Foundation

// Article model to store article data from search results
struct Article: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let url: String
    let content: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.id == rhs.id
    }
} 