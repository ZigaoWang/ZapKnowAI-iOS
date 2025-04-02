import Foundation
import Combine

class ZhiDaoService: ObservableObject {
    private let baseURL = "https://api1.zhidao.zigao.wang"
    private var eventSource: URLSessionDataTask?
    private var urlSession: URLSession
    
    // Publishers
    @Published var statusMessage = ""
    @Published var isConnected = false
    @Published var currentStage: ProgressStage?
    @Published var completedStages: Set<ProgressStage> = []
    @Published var papers: [Paper] = []
    @Published var selectedPapers: [Paper] = []
    @Published var images: [ImageResult] = []
    @Published var accumulatedTokens = ""
    @Published var citationMapping: [String: Citation] = [:]
    @Published var error: String?
    @Published var isStreaming = false
    @Published var canAnswer: Bool?
    @Published var searchTerm: String?
    @Published var isComplete = false
    @Published var hasImages = false
    
    private var buffer = ""
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300 // 5 minutes
        urlSession = URLSession(configuration: config)
    }
    
    func streamQuestion(query: String) {
        guard let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/stream-question?query=\(queryEncoded)") else {
            setError("Invalid query or URL")
            return
        }
        
        // Reset state
        reset()
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 300 // 5 minutes
        
        isStreaming = true
        statusMessage = NSLocalizedString("连接到服务器，正在处理您的问题...", comment: "Status: Connecting to server and processing question")
        
        // We'll use a custom URLSession delegate below instead
        _ = urlSession.dataTask(with: request)
        
        // Set up a proper streaming connection handler
        urlSession.delegateQueue.addOperation {
            let session = URLSession(configuration: .default, delegate: SSEDelegate(service: self), delegateQueue: nil)
            self.eventSource = session.dataTask(with: request)
            self.eventSource?.resume()
        }
    }
    
    // Custom URL Session delegate to handle streaming events properly
    class SSEDelegate: NSObject, URLSessionDataDelegate {
        weak var service: ZhiDaoService?
        private var buffer = ""
        
        init(service: ZhiDaoService) {
            self.service = service
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            guard let service = service else { return }
            guard let stringData = String(data: data, encoding: .utf8) else { return }
            
            // Process the incoming SSE data immediately on the main thread
            DispatchQueue.main.async {
                service.processSSEData(stringData)
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            guard let service = service else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    service.setError(NSLocalizedString("Connection error: ", comment: "Error prefix") + error.localizedDescription)
                } else if !service.isComplete {
                    // Only set error if we're not already complete
                    service.setError(NSLocalizedString("Connection closed unexpectedly", comment: "Connection error message"))
                }
                service.isStreaming = false
            }
        }
    }
    
    func processSSEData(_ text: String) {
        buffer += text
        
        // Split by double newlines which separate SSE events
        let events = buffer.components(separatedBy: "\n\n")
        
        // Keep the last part as it might be incomplete
        if events.count > 0 {
            let lastPart = events.last!
            
            // Process all complete events
            for i in 0..<events.count-1 {
                let eventText = events[i]
                let eventLines = eventText.components(separatedBy: "\n")
                
                for line in eventLines {
                    if line.hasPrefix("data: ") {
                        let data = line.dropFirst(6) // Remove "data: "
                        processEventData(String(data))
                    }
                }
            }
            
            // Only keep the last part if it doesn't end with a newline
            if !text.hasSuffix("\n\n") {
                buffer = lastPart
            } else {
                buffer = ""
                
                // Process the last part too if it ends with a newline
                let lastLines = lastPart.components(separatedBy: "\n")
                for line in lastLines {
                    if line.hasPrefix("data: ") {
                        let data = line.dropFirst(6)
                        processEventData(String(data))
                    }
                }
            }
        }
    }
    
    private func processEventData(_ dataString: String) {
        guard let data = dataString.data(using: .utf8) else { return }
        
        do {
            let event = try JSONDecoder().decode(ZhiDaoEvent.self, from: data)
            handleEvent(event)
        } catch {
            print("Error parsing event: \(error)")
            setError(NSLocalizedString("解析响应数据时出错", comment: "Error parsing response data"))
        }
    }
    
    private func handleEvent(_ event: ZhiDaoEvent) {
        print("Received event: \(event.status)")
        
        switch event.status {
        case "connected":
            isConnected = true
            statusMessage = event.message ?? NSLocalizedString("连接已建立", comment: "Status: Connection established")
            
        case "stage_update":
            guard let stageName = event.stage else { return }
            print("Stage update: \(stageName)")
            if let stage = ProgressStage(rawValue: stageName) {
                // If we're moving to a new stage, mark the previous stage as completed
                if let currentStage = self.currentStage, currentStage != stage {
                    DispatchQueue.main.async {
                        self.completedStages.insert(currentStage)
                    }
                }
                
                // Immediately update the current stage to show progress
                DispatchQueue.main.async {
                    self.currentStage = stage
                }
            }
            statusMessage = event.message ?? NSLocalizedString("Processing", comment: "Status: Processing") + " " + stageName
            
        case "substage_update":
            guard let substage = event.stage else { return }
            print("Substage update: \(substage)")
            statusMessage = event.message ?? NSLocalizedString("Processing substage: ", comment: "Status: Processing substage") + substage
            
            if substage == "evaluation_complete" {
                canAnswer = event.canAnswer
                // Mark evaluation stage as completed
                if let stage = ProgressStage(rawValue: "evaluation") {
                    DispatchQueue.main.async {
                        self.completedStages.insert(stage)
                    }
                }
            } else if substage == "search_term_selected" {
                searchTerm = event.queryWord
            } else if substage == "papers_selected", let selected = event.selectedPapers {
                updateSelectedPapers(selected)
                // Mark paper retrieval stage as completed
                if let stage = ProgressStage(rawValue: "paper_retrieval") {
                    DispatchQueue.main.async {
                        self.completedStages.insert(stage)
                    }
                }
            } else if substage == "paper_analysis_complete" {
                // Mark paper analysis stage as completed
                if let stage = ProgressStage(rawValue: "paper_analysis") {
                    DispatchQueue.main.async {
                        self.completedStages.insert(stage)
                    }
                }
            }
            
        case "papers_finding":
            if let foundPapers = event.papers {
                print("Found \(foundPapers.count) papers")
                updatePapers(foundPapers)
            }
            statusMessage = event.message ?? String(format: NSLocalizedString("找到 %d 篇论文", comment: "Status: Found n papers"), event.count ?? 0)
            
        case "images_found":
            if let foundImages = event.images {
                print("Found \(foundImages.count) images")
                updateImages(foundImages)
                hasImages = true
            }
            statusMessage = event.message ?? String(format: NSLocalizedString("找到 %d 张相关图片", comment: "Status: Found n related images"), event.count ?? 0)
            
        case "streaming":
            // A streaming phase is starting (e.g., paper analysis or answer generation)
            statusMessage = event.message ?? NSLocalizedString("开始流式生成回答", comment: "Status: Starting streaming response")
            print("Streaming starting")
            
        case "token":
            // Individual token from the streaming response
            if let token = event.token {
                // Immediately update the accumulated tokens to show streaming progress
                DispatchQueue.main.async {
                    self.accumulatedTokens += token
                }
            }
            
        case "chunk_complete":
            // A chunk of streaming is complete
            statusMessage = event.message ?? NSLocalizedString("Chunk complete", comment: "Status: Chunk complete")
            
        case "complete":
            // The entire process is complete
            print("Query complete")
            isComplete = true
            isStreaming = false
            
            if let result = event.result {
                // Update citation mapping
                if let citationMappings = result.citationMapping {
                    for citation in citationMappings {
                        citationMapping[citation.key] = citation
                    }
                    
                    // Mark papers as cited
                    for paper in papers {
                        if citationMapping.keys.contains(getCitationKey(for: paper)) {
                            markPaperAsCited(paper)
                        }
                    }
                }
                
                // Update images if available in result
                if let resultImages = result.images, !resultImages.isEmpty {
                    updateImages(resultImages)
                    hasImages = true
                }
            }
            
            statusMessage = NSLocalizedString("响应完成", comment: "Status: Response complete")
            
        case "error":
            setError(event.error ?? "Unknown error")
            isStreaming = false
            
        default:
            print("Unknown event status: \(event.status)")
        }
    }
    
    private func updatePapers(_ newPapers: [Paper]) {
        // For each new paper, add it if it doesn't exist
        for paper in newPapers {
            if !papers.contains(where: { $0.id == paper.id }) {
                papers.append(paper)
            }
        }
    }
    
    private func updateImages(_ newImages: [ImageResult]) {
        // For each new image, add it if it doesn't exist
        for image in newImages {
            if !images.contains(where: { $0.url == image.url }) {
                images.append(image)
            }
        }
    }
    
    private func updateSelectedPapers(_ selected: [Paper]) {
        // Mark papers as selected
        for selectedPaper in selected {
            if let index = papers.firstIndex(where: { $0.title == selectedPaper.title }) {
                var updatedPaper = papers[index]
                updatedPaper.isSelected = true
                papers[index] = updatedPaper
            }
        }
        
        // Set the selected papers array
        selectedPapers = selected
    }
    
    private func markPaperAsCited(_ paper: Paper) {
        if let index = papers.firstIndex(where: { $0.id == paper.id }) {
            var updatedPaper = papers[index]
            updatedPaper.isCited = true
            papers[index] = updatedPaper
        }
    }
    
    func getCitationKey(for paper: Paper) -> String {
        // Extract author's last name
        let authorComponents = paper.authors.split(separator: " ")
        let lastName = authorComponents.last?.description ?? "Unknown"
        
        // Create citation key (e.g., "Smith2023")
        return "\(lastName)\(paper.year)"
    }
    
    private func setError(_ message: String) {
        error = message
        statusMessage = String(format: NSLocalizedString("错误: %@", comment: "Status: Error message"), message)
    }
    
    func reset() {
        // Cancel any ongoing request
        eventSource?.cancel()
        
        // Reset all state
        isConnected = false
        currentStage = nil
        completedStages = []
        papers = []
        selectedPapers = []
        images = []
        accumulatedTokens = ""
        citationMapping = [:]
        error = nil
        statusMessage = ""
        isStreaming = false
        canAnswer = nil
        searchTerm = nil
        isComplete = false
        hasImages = false
        buffer = ""
    }
    
    deinit {
        eventSource?.cancel()
    }
}
