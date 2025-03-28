import Foundation

// Main response event model
struct ZhiDaoEvent: Identifiable, Codable {
    var id = UUID()
    let status: String
    var stage: String?
    var message: String?
    var canAnswer: Bool?
    var queryWord: String?
    var token: String?
    var papers: [Paper]?
    var count: Int?
    var selectedPapers: [Paper]?
    var content: String?
    var result: QueryResult?
    var error: String?
    
    enum CodingKeys: String, CodingKey {
        case status, stage, message, canAnswer, queryWord, token, papers, count, selectedPapers, content, result, error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        stage = try container.decodeIfPresent(String.self, forKey: .stage)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        canAnswer = try container.decodeIfPresent(Bool.self, forKey: .canAnswer)
        queryWord = try container.decodeIfPresent(String.self, forKey: .queryWord)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        papers = try container.decodeIfPresent([Paper].self, forKey: .papers)
        count = try container.decodeIfPresent(Int.self, forKey: .count)
        selectedPapers = try container.decodeIfPresent([Paper].self, forKey: .selectedPapers)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        result = try container.decodeIfPresent(QueryResult.self, forKey: .result)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        id = UUID()
    }
    
    init(status: String, message: String? = nil) {
        self.status = status
        self.message = message
    }
}

// Paper model
struct Paper: Identifiable, Codable, Equatable {
    var id: String
    let title: String
    let authors: String
    let year: String
    let source: String?
    let abstract: String?
    let link: String
    var isSelected: Bool = false
    var isCited: Bool = false
    
    // Manual initializer for creating Paper instances directly
    init(id: String, title: String, authors: String, year: String, source: String? = nil, abstract: String? = nil, link: String, isSelected: Bool = false, isCited: Bool = false) {
        self.id = id
        self.title = title
        self.authors = authors
        self.year = year
        self.source = source
        self.abstract = abstract
        self.link = link
        self.isSelected = isSelected
        self.isCited = isCited
    }
    
    static func ==(lhs: Paper, rhs: Paper) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Fallback ID for when papers don't have an ID
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try? container.decode(String.self, forKey: .id) {
            self.id = id
        } else {
            // Generate an ID if none exists
            self.id = UUID().uuidString
        }
        
        title = try container.decode(String.self, forKey: .title)
        
        // Handle authors as String or fallback
        if let authorsString = try? container.decode(String.self, forKey: .authors) {
            authors = authorsString
        } else {
            authors = "Unknown Author"
        }
        
        // Handle year as String or fallback
        if let yearString = try? container.decode(String.self, forKey: .year) {
            year = yearString
        } else {
            year = "Unknown Year"
        }
        
        source = try container.decodeIfPresent(String.self, forKey: .source)
        abstract = try container.decodeIfPresent(String.self, forKey: .abstract)
        
        // Handle link as String or fallback
        if let linkString = try? container.decode(String.self, forKey: .link) {
            link = linkString
        } else {
            link = ""
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, authors, year, source, abstract, link
    }
}

// Citation model
struct Citation: Identifiable, Codable {
    var id: String { key }
    let key: String
    let title: String
    let authors: String
    let year: String
    let link: String
}

// Final query result model
struct QueryResult: Codable {
    let answer: String
    let queryWord: String?
    let citations: [Paper]?
    let paperAnalysis: String?
    let citationMapping: [Citation]?
    let processSteps: [String]?
}

// Progress stage enum
enum ProgressStage: String, CaseIterable {
    case evaluation = "evaluation"
    case paperRetrieval = "paper_retrieval"
    case paperAnalysis = "paper_analysis"
    case answerGeneration = "answer_generation"
    
    var displayText: String {
        switch self {
        case .evaluation:
            return "正在评估问题范围"
        case .paperRetrieval:
            return "正在搜索相关论文"
        case .paperAnalysis:
            return "正在分析论文内容"
        case .answerGeneration:
            return "正在生成最终答案"
        }
    }
}
