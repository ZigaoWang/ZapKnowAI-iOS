import Foundation

// Model for a saved conversation
struct SavedConversation: Identifiable, Codable {
    let id: UUID
    let query: String
    let timestamp: Date
    let answer: String
    let papers: [Paper]
    let imageUrls: [String]
    let articles: [ArticleData]
    let completedStages: [String]
    
    init(id: UUID = UUID(), 
         query: String, 
         timestamp: Date = Date(), 
         answer: String, 
         papers: [Paper], 
         imageUrls: [String], 
         articles: [ArticleData],
         completedStages: [String]) {
        self.id = id
        self.query = query
        self.timestamp = timestamp
        self.answer = answer
        self.papers = papers
        self.imageUrls = imageUrls
        self.articles = articles
        self.completedStages = completedStages
    }
}

// Article data to be saved (simplified version of Article)
struct ArticleData: Codable, Identifiable {
    let id: UUID
    let title: String
    let url: String
    let content: String
    
    init(from article: Article) {
        self.id = article.id
        self.title = article.title
        self.url = article.url
        self.content = article.content
    }
    
    init(id: UUID = UUID(), title: String, url: String, content: String) {
        self.id = id
        self.title = title
        self.url = url
        self.content = content
    }
} 