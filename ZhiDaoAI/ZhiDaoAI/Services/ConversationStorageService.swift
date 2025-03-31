import Foundation
import Combine

class ConversationStorageService: ObservableObject {
    @Published var savedConversations: [SavedConversation] = []
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let conversationsFileName = "saved_conversations.json"
    
    init() {
        // Get the app's documents directory
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Load saved conversations on init
        loadConversations()
    }
    
    // Save a new conversation
    func saveConversation(query: String, answer: String, papers: [Paper], imageUrls: [String], articles: [Article], completedStages: Set<ProgressStage>) {
        // Convert articles to ArticleData
        let articleDataArray = articles.map { ArticleData(from: $0) }
        
        // Convert completedStages to strings
        let completedStageStrings = completedStages.map { $0.rawValue }
        
        // Create new conversation
        let newConversation = SavedConversation(
            query: query,
            answer: answer,
            papers: papers,
            imageUrls: imageUrls,
            articles: articleDataArray,
            completedStages: completedStageStrings
        )
        
        // Add to array
        savedConversations.append(newConversation)
        
        // Save to file
        writeConversationsToFile()
    }
    
    // Load all conversations
    func loadConversations() {
        let fileURL = documentsDirectory.appendingPathComponent(conversationsFileName)
        
        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("No saved conversations file exists yet")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            savedConversations = try JSONDecoder().decode([SavedConversation].self, from: data)
        } catch {
            print("Error loading conversations: \(error)")
        }
    }
    
    // Delete a conversation by ID
    func deleteConversation(id: UUID) {
        savedConversations.removeAll { $0.id == id }
        writeConversationsToFile()
    }
    
    // Delete all conversations
    func deleteAllConversations() {
        savedConversations.removeAll()
        writeConversationsToFile()
    }
    
    // Private helper method to write conversations to file
    private func writeConversationsToFile() {
        let fileURL = documentsDirectory.appendingPathComponent(conversationsFileName)
        
        do {
            let data = try JSONEncoder().encode(savedConversations)
            try data.write(to: fileURL)
        } catch {
            print("Error saving conversations: \(error)")
        }
    }
} 