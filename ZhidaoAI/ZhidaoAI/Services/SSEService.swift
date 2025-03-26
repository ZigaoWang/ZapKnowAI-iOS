import Foundation

class SSEService: ObservableObject {
    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var buffer: String = ""
    
    // Published properties for UI updates
    @Published var isConnected = false
    @Published var currentStage: StageType?
    @Published var currentStageMessage: String = ""
    @Published var currentSubstage: SubstageType?
    @Published var streamingText: String = ""
    @Published var paperAnalysis: String = ""
    @Published var answerText: String = ""
    @Published var foundPapers: [Paper] = []
    @Published var selectedPapers: [Paper] = []
    @Published var citations: [Citation] = []
    @Published var processSteps: [String] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isComplete = false
    
    private let baseURL = "http://localhost:3000"
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300  // 5 minutes timeout
        session = URLSession(configuration: config)
    }
    
    func connect(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.errorMessage = "Please enter a question"
            return
        }
        
        // Reset state
        resetState()
        isLoading = true
        
        // Create URL with query parameter
        guard var components = URLComponents(string: "\(baseURL)/stream-question") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        components.queryItems = [URLQueryItem(name: "query", value: query)]
        
        guard let url = components.url else {
            self.errorMessage = "Invalid URL with query"
            self.isLoading = false
            return
        }
        
        task = session?.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Connection error: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response"
                    self.isLoading = false
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    self.errorMessage = "Server returned error: \(httpResponse.statusCode)"
                    self.isLoading = false
                    return
                }
                
                // Parse data if received
                if let data = data, !data.isEmpty {
                    self.processSSEData(data)
                }
            }
        }
        
        task?.resume()
    }
    
    func disconnect() {
        task?.cancel()
        task = nil
        isLoading = false
    }
    
    private func resetState() {
        isConnected = false
        currentStage = nil
        currentStageMessage = ""
        currentSubstage = nil
        streamingText = ""
        paperAnalysis = ""
        answerText = ""
        foundPapers = []
        selectedPapers = []
        citations = []
        processSteps = []
        errorMessage = nil
        isComplete = false
        buffer = ""
    }
    
    private func processSSEData(_ data: Data) {
        guard let string = String(data: data, encoding: .utf8) else {
            self.errorMessage = "Invalid data encoding"
            return
        }
        
        // Append new data to buffer
        buffer += string
        
        // Process each complete line
        while let lineEnd = buffer.range(of: "\n\n") {
            let line = buffer[..<lineEnd.lowerBound]
            buffer = String(buffer[lineEnd.upperBound...])
            
            if line.hasPrefix("data: ") {
                let dataString = line.dropFirst(6) // Remove "data: " prefix
                processEventData(String(dataString))
            }
        }
    }
    
    private func processEventData(_ dataString: String) {
        guard let data = dataString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? String else {
            return
        }
        
        let eventType = EventType(rawValue: status) ?? .error
        
        switch eventType {
        case .connected:
            handleConnectedEvent(json)
        case .stageUpdate:
            handleStageUpdateEvent(json)
        case .substageUpdate:
            handleSubstageUpdateEvent(json)
        case .papersFinding:
            handlePapersFindingEvent(json)
        case .streaming:
            handleStreamingEvent(json)
        case .token:
            handleTokenEvent(json)
        case .chunkComplete:
            handleChunkCompleteEvent(json)
        case .complete:
            handleCompleteEvent(json)
        case .error:
            handleErrorEvent(json)
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleConnectedEvent(_ json: [String: Any]) {
        isConnected = true
        if let message = json["message"] as? String {
            print("Connected: \(message)")
        }
    }
    
    private func handleStageUpdateEvent(_ json: [String: Any]) {
        guard let stageString = json["stage"] as? String,
              let stage = StageType(rawValue: stageString) else {
            return
        }
        
        currentStage = stage
        if let message = json["message"] as? String {
            currentStageMessage = message
        }
    }
    
    private func handleSubstageUpdateEvent(_ json: [String: Any]) {
        guard let substageString = json["stage"] as? String,
              let substage = SubstageType(rawValue: substageString) else {
            return
        }
        
        currentSubstage = substage
        
        if let message = json["message"] as? String {
            currentStageMessage = message
        }
        
        if substage == .papersSelected,
           let selectedPapersData = try? JSONSerialization.data(withJSONObject: json["selectedPapers"] ?? [], options: []),
           let papers = try? JSONDecoder().decode([Paper].self, from: selectedPapersData) {
            selectedPapers = papers
        }
    }
    
    private func handlePapersFindingEvent(_ json: [String: Any]) {
        guard let papersData = try? JSONSerialization.data(withJSONObject: json["papers"] ?? [], options: []),
              let papers = try? JSONDecoder().decode([Paper].self, from: papersData) else {
            return
        }
        
        foundPapers = papers
        
        if let message = json["message"] as? String {
            currentStageMessage = message
        }
    }
    
    private func handleStreamingEvent(_ json: [String: Any]) {
        guard let stageString = json["stage"] as? String,
              let stage = StageType(rawValue: stageString) else {
            return
        }
        
        if stage == .analyzingPapers {
            paperAnalysis = ""
        } else if stage == .generatingAnswer {
            answerText = ""
        }
    }
    
    private func handleTokenEvent(_ json: [String: Any]) {
        guard let stageString = json["stage"] as? String,
              let stage = StageType(rawValue: stageString),
              let token = json["token"] as? String else {
            return
        }
        
        if stage == .analyzingPapers {
            paperAnalysis += token
        } else if stage == .generatingAnswer {
            answerText += token
        }
    }
    
    private func handleChunkCompleteEvent(_ json: [String: Any]) {
        guard let stageString = json["stage"] as? String,
              let stage = StageType(rawValue: stageString) else {
            return
        }
        
        if stage == .analyzingPapers, let content = json["content"] as? String {
            paperAnalysis = content
        } else if stage == .generatingAnswer, let content = json["content"] as? String {
            answerText = content
        }
    }
    
    private func handleCompleteEvent(_ json: [String: Any]) {
        guard let resultData = try? JSONSerialization.data(withJSONObject: json["result"] ?? [:], options: []),
              let result = try? JSONDecoder().decode(QueryResult.self, from: resultData) else {
            return
        }
        
        answerText = result.answer
        
        if let citationMapping = result.citationMapping {
            citations = citationMapping
        }
        
        if let steps = result.processSteps {
            processSteps = steps
        }
        
        isComplete = true
        isLoading = false
    }
    
    private func handleErrorEvent(_ json: [String: Any]) {
        if let error = json["error"] as? String {
            errorMessage = error
            isLoading = false
        }
    }
}