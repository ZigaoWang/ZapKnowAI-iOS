//
//  ContentView.swift
//  ZhiDaoAI
//
//  Created by Zigao Wang on 3/26/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var service = ZhiDaoService()
    @StateObject private var storageService = ConversationStorageService()
    @State private var query = ""
    @State private var isSearchFocused = false
    @State private var showClearButton = false
    @State private var isTyping = false
    @State private var isDarkMode = false
    @State private var showSettings = false
    @State private var imageUrls: [String] = []
    @State private var articles: [Article] = []
    
    // Sidebar and conversation states
    @State private var showSidebar = false
    @State private var selectedConversationId: UUID? = nil
    
    // Animation states
    @State private var animateGradient = false
    
    private let searchBarHeight: CGFloat = 50
    private let placeholderText = "Ask a question..."
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ZStack {
            // Main background
            Color(hex: isDarkMode ? "121212" : "F9F9F9")
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Top navigation area
                topBar
                
                // Main content
                ZStack {
                    VStack(spacing: 0) {
                        if let selectedId = selectedConversationId,
                           let conversation = storageService.savedConversations.first(where: { $0.id == selectedId }) {
                            // Show saved conversation
                            SavedConversationView(
                                conversation: conversation,
                                isDarkMode: isDarkMode,
                                onBack: {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        selectedConversationId = nil
                                    }
                                }
                            )
                        } else {
                            if service.accumulatedTokens.isEmpty && imageUrls.isEmpty && articles.isEmpty && service.papers.isEmpty && !service.isStreaming {
                                // Empty state / welcome screen
                                welcomeView
                            } else {
                                // Active chat with results
                                chatResultsView
                            }
                        }
                        
                        // Input area always shown at bottom
                        queryInputBar
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: isDarkMode ? "1A1A1A" : "FFFFFF"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Overlay elements with proper z-index
            ZStack {
                // Sidebar drawer overlay
                if showSidebar {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showSidebar = false
                            }
                        }
                    
                    // Drawer content with fixed animation
                    HStack(spacing: 0) {
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 0) {
                                // Header area
                                HStack {
                                    Text("知道 AI")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                    
                                    Spacer()
                                }
                                .padding(.top, 16)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                                
                                // New Chat button
                                Button(action: {
                                    onNewChat()
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        showSidebar = false
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                        
                                        Text("新对话")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "3B82F6"))
                                    )
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                                
                                // Search box
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 14))
                                        .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                                    
                                    Text("搜索对话")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                                    
                                    Spacer()
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                                )
                                .padding(.horizontal, 16)
                                
                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                
                                Text("今天")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color(hex: "6B7280"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                
                                // Conversations list
                                if storageService.savedConversations.isEmpty {
                                    // Empty state
                                    VStack(spacing: 16) {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                            .font(.system(size: 36))
                                            .foregroundColor(isDarkMode ? Color.white.opacity(0.3) : Color(hex: "D1D5DB"))
                                        
                                        Text("暂无历史对话")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color(hex: "6B7280"))
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.top, 60)
                                    .frame(maxWidth: .infinity)
                                } else {
                                    // List of conversations
                                    ScrollView {
                                        LazyVStack(spacing: 0) {
                                            ForEach(storageService.savedConversations.sorted(by: { $0.timestamp > $1.timestamp })) { conversation in
                                                ConversationRowItem(
                                                    conversation: conversation,
                                                    isSelected: selectedConversationId == conversation.id,
                                                    dateFormatter: dateFormatter,
                                                    isDarkMode: isDarkMode
                                                )
                                                .onTapGesture {
                                                    selectedConversationId = conversation.id
                                                    withAnimation(.easeOut(duration: 0.25)) {
                                                        showSidebar = false
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                // User profile
                                HStack(spacing: 12) {
                                    // User avatar
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "6366F1"))
                                            .frame(width: 36, height: 36)
                                        
                                        Text("ZW")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    
                                    // User name
                                    Text("Zigao Wang")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                    
                                    Spacer()
                                    
                                    // Settings
                                    Button(action: {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            showSettings = true
                                            showSidebar = false
                                        }
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(hex: "6B7280"))
                                            .frame(width: 32, height: 32)
                                            .background(
                                                Circle()
                                                    .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                                            )
                                    }
                                }
                                .padding(16)
                                .background(isDarkMode ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF"))
                            }
                            
                            // Close button
                            Button {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showSidebar = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                                    )
                            }
                            .padding(16)
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.85)
                        .background(Color(hex: isDarkMode ? "1A1A1A" : "FFFFFF"))
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.move(edge: .leading))
                }
                
                // Settings panel overlay with proper positioning
                if showSettings {
                    settingsPanel
                        .transition(.move(edge: .trailing))
                        .zIndex(3) // Ensure it's above everything
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.easeOut(duration: 0.25), value: showSidebar)
        .animation(.easeOut(duration: 0.25), value: showSettings)
        .onChange(of: service.isStreaming) { _, isStreaming in
            if !isStreaming && !service.accumulatedTokens.isEmpty {
                // When streaming completes, update UI and save conversation
                withAnimation {
                    isTyping = false
                }
                
                // Save the completed conversation
                saveCurrentConversation()
            }
        }
    }
    
    // Welcome screen for empty state
    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 60)
                
                // App logo with fallback
                Group {
                    if let _ = UIImage(named: "AppLogo") {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .cornerRadius(20)
                    } else {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "3B82F6"))
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                            )
                    }
                }
                .padding(.bottom, 16)
                
                Text("知道 AI")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Text("AI 研究助手")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color(hex: "6B7280"))
                    .padding(.bottom, 16)
                
                // Example questions
                VStack(spacing: 12) {
                    Text("试试以下问题")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color(hex: "6B7280"))
                        .padding(.bottom, 8)
                    
                    ForEach(exampleQuestions, id: \.self) { question in
                        Button {
                            query = question
                            submitQuery()
                        } label: {
                            HStack {
                                Text(question)
                                    .font(.system(size: 15, design: .rounded))
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(isDarkMode ? .white : Color(hex: "374151"))
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "3B82F6"))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                            )
                        }
                    }
                }
                .frame(maxWidth: 600)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    // Chat results view
    private var chatResultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status message
                if !service.statusMessage.isEmpty {
                    statusMessageView(service.statusMessage)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        .transition(.opacity)
                }
                
                // Progress stages
                if service.isStreaming || !service.completedStages.isEmpty {
                    ProgressStagesView(
                        currentStage: service.currentStage,
                        completedStages: service.completedStages
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .transition(.opacity)
                }
                
                // Papers list
                if (!service.papers.isEmpty && isPaperRelevantStage) || 
                   (service.isStreaming && isPaperSearching) {
                    PapersListView(
                        papers: service.papers,
                        onPaperTap: { paper in
                            // Handle paper tap
                        }
                    )
                    .padding(.horizontal, 16)
                    .transition(.opacity)
                }
                
                // Image results
                if !imageUrls.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("相关图片")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            .padding(.horizontal, 16)
                        
                        ScrollView(.horizontal) {
                            HStack(spacing: 10) {
                                ForEach(imageUrls, id: \.self) { url in
                                    AsyncImage(url: URL(string: url)) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 200)
                                            .cornerRadius(10)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 16)
                }
                
                // Articles section
                if !articles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("延伸阅读")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            .padding(.horizontal, 16)
                        
                        ForEach(articles) { article in
                            ArticleCardView(article: article, isDarkMode: isDarkMode)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                    .padding(.bottom, 16)
                }
                
                // Answer section
                if !service.accumulatedTokens.isEmpty || isGeneratingResponse {
                    answerView
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(.opacity)
                }
                
                Spacer().frame(height: 80) // Bottom padding for input field
            }
            .animation(.easeInOut(duration: 0.2), value: service.isStreaming)
            .animation(.easeInOut(duration: 0.2), value: service.papers.count)
            .animation(.easeInOut(duration: 0.2), value: service.accumulatedTokens)
        }
        .scrollDismissesKeyboard(.immediately)
    }
    
    // Top navigation bar
    private var topBar: some View {
        HStack(spacing: 16) {
            // Menu button
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    showSidebar.toggle()
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: isDarkMode ? "FFFFFF" : "232323"))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(hex: isDarkMode ? "2A2A2A" : "F1F5F9").opacity(0.8))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            // App title (shown when no conversation is selected)
            if selectedConversationId == nil {
                HStack(spacing: 8) {
                    Text("知道 AI")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: isDarkMode ? "FFFFFF" : "232323"))
                }
            }
            
            Spacer()
            
            // Settings button
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                withAnimation(.easeOut(duration: 0.25)) {
                    showSettings.toggle()
                }
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: isDarkMode ? "FFFFFF" : "232323"))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(hex: isDarkMode ? "2A2A2A" : "F1F5F9").opacity(0.8))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(hex: isDarkMode ? "1A1A1A" : "FFFFFF")
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        )
    }
    
    // Input field
    private var queryInputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
            
            HStack(alignment: .center, spacing: 10) {
                // Text field - replace TextEditor with TextField for better behavior
                TextField(placeholderText, text: $query)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                    )
                    .onTapGesture {
                        isSearchFocused = true
                    }
                
                // Submit button
                Button(action: submitQuery) {
                    ZStack {
                        Circle()
                            .fill(
                                service.isStreaming ? 
                                Color.red : 
                                Color(hex: query.isEmpty ? "D1D5DB" : "3B82F6")
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: query.isEmpty ? Color.clear : Color(hex: "3B82F6").opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        if service.isStreaming {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .opacity(query.isEmpty ? 0.5 : 1.0)
                        }
                    }
                    .scaleEffect(service.isStreaming ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: service.isStreaming)
                }
                .disabled(query.isEmpty && !service.isStreaming)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: isDarkMode ? "1A1A1A" : "FFFFFF"))
        }
    }
    
    // MARK: - Status Message View
    private func statusMessageView(_ message: String) -> some View {
        HStack(spacing: 12) {
            if isTyping {
                // Typing indicator
                TypingIndicator()
                    .frame(width: 40, height: 20)
            } else {
                Image(systemName: "ellipsis.bubble")
                    .font(.system(size: 16))
                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(hex: "6B7280"))
            }
            
            Text(message)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(isDarkMode ? .white.opacity(0.8) : Color(hex: "4B5563"))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
    }
    
    // MARK: - Answer View
    private var answerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Answer header
            HStack(spacing: 12) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "3B82F6"))
                
                Text("研究回答")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Spacer()
                
                // Show generating status when generating answer
                if isGeneratingResponse && service.accumulatedTokens.isEmpty {
                    TypingIndicator()
                        .frame(width: 40, height: 20)
                }
                
                // Copy button
                if !service.accumulatedTokens.isEmpty {
                    Button(action: {
                        UIPasteboard.general.string = service.accumulatedTokens
                        // Add haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                            
                            Text("复制")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F3F4F6"))
                        )
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Answer content
            VStack(alignment: .leading, spacing: 0) {
                // Markdown content with improved styling
                MarkdownView_Native(markdown: service.accumulatedTokens)
                    .padding(20)
                    .environment(\.colorScheme, isDarkMode ? .dark : .light)
                
                // Typing indicator - only show when actively generating the answer
                if isTyping && isGeneratingResponse {
                    HStack {
                        TypingIndicator()
                            .frame(width: 40, height: 20)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .background(isDarkMode ? Color(hex: "222222") : Color.white)
            .cornerRadius(16)
            .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), radius: 12, x: 0, y: 2)
        }
    }
    
    // MARK: - Helper Functions
    
    // Submit a new query
    private func submitQuery() {
        guard !query.isEmpty else { return }
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        service.streamQuestion(query: query)
        performImageSearch()
        
        withAnimation {
            isSearchFocused = false
            isTyping = true
            selectedConversationId = nil
        }
    }
    
    // Start a brand new chat, clearing everything
    private func onNewChat() {
        withAnimation(.easeOut(duration: 0.25)) {
            // Clear all data
            query = ""
            service.reset()
            imageUrls = []
            articles = []
            selectedConversationId = nil
        }
    }
    
    // Save the current conversation when complete
    private func saveCurrentConversation() {
        // Only save if we have an answer
        guard !service.accumulatedTokens.isEmpty, !query.isEmpty else { return }
        
        storageService.saveConversation(
            query: query,
            answer: service.accumulatedTokens,
            papers: service.papers,
            imageUrls: imageUrls,
            articles: articles,
            completedStages: service.completedStages
        )
    }
    
    // Image search function
    private func performImageSearch() {
        let imageSearchService = ImageSearchService()
        imageSearchService.searchImagesAndArticles(query: query) { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self.imageUrls = response.imageUrls
                    self.articles = response.articles
                }
            case .failure(let error):
                print("Error fetching search results: \(error)")
            }
        }
    }
    
    // Reset all function
    private func resetAll() {
        // Clear all data
        query = ""
        service.reset()
        imageUrls = []
        articles = []
        selectedConversationId = nil
        
        // Clear saved conversations
        storageService.deleteAllConversations()
        
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // Example questions to display on the welcome screen
    private var exampleQuestions: [String] = [
        "癌症治疗的最新研究进展是什么？",
        "量子计算如何应用于密码学？",
        "机器学习在医疗诊断中的应用有哪些？",
        "全球变暖对海洋生态系统有什么影响？"
    ]
    
    // Helper computed properties for improved stage tracking
    private var isPaperSearching: Bool {
        return service.currentStage == .paperRetrieval
    }
    
    private var isPaperRelevantStage: Bool {
        return service.currentStage == .paperRetrieval || 
               service.currentStage == .paperAnalysis ||
               service.completedStages.contains(.paperRetrieval)
    }
    
    private var isGeneratingResponse: Bool {
        return service.currentStage == .answerGeneration
    }
    
    // MARK: - Settings Panel
    private var settingsPanel: some View {
        ZStack(alignment: .trailing) {
            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showSettings = false
                    }
                }
            
            // Settings panel content
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("设置")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(isDarkMode ? .white : .black)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showSettings = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isDarkMode ? .white.opacity(0.8) : .black.opacity(0.7))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(isDarkMode ? Color.white.opacity(0.15) : Color.black.opacity(0.05))
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                Divider()
                    .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                
                ScrollView {
                    VStack(spacing: 8) {
                        // Theme toggle
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isDarkMode.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(isDarkMode ? .yellow : .indigo)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(isDarkMode ? Color.white.opacity(0.15) : Color.indigo.opacity(0.1))
                                    )
                                
                                Text(isDarkMode ? "切换为亮色模式" : "切换为深色模式")
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(isDarkMode ? .white : .black)
                                
                                Spacer()
                                
                                Toggle("", isOn: $isDarkMode)
                                    .labelsHidden()
                                    .tint(Color(hex: "3B82F6"))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Divider()
                            .padding(.horizontal, 20)
                            .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                        
                        // Reset button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            // Show confirmation alert
                            let alert = UIAlertController(
                                title: "重置所有对话",
                                message: "此操作将删除所有保存的对话历史，且不可恢复。确定要继续吗？",
                                preferredStyle: .alert
                            )
                            
                            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                            alert.addAction(UIAlertAction(title: "确定", style: .destructive) { _ in
                                resetAll()
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showSettings = false
                                }
                            })
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                rootViewController.present(alert, animated: true)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(Color.red.opacity(0.1))
                                    )
                                
                                Text("重置所有对话")
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(isDarkMode ? .white : .black)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.4) : .black.opacity(0.3))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Divider()
                            .padding(.horizontal, 20)
                            .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                        
                        // About section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("关于")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : .black)
                                .padding(.horizontal, 20)
                            
                            // App info
                            HStack(spacing: 16) {
                                // App logo
                                Group {
                                    if let _ = UIImage(named: "AppLogo") {
                                        Image("AppLogo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(12)
                                    } else {
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(Color(hex: "3B82F6"))
                                            .frame(width: 60, height: 60)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                                            )
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("知道 AI")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                    
                                    Text("版本 1.0.0")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Copyright
                            Text("© 2025 Zigao Wang. All rights reserved.")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(isDarkMode ? .white.opacity(0.5) : Color(hex: "6B7280"))
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        }
                        .padding(.top, 12)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 320)
        .background(Color(hex: isDarkMode ? "1A1A1A" : "FFFFFF"))
        .cornerRadius(isDarkMode ? 0 : 16, corners: [.topLeft, .bottomLeft])
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: -5, y: 0)
        .frame(maxHeight: .infinity, alignment: .trailing)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 50 {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showSettings = false
                        }
                    }
                }
        )
    }
}

// MARK: - Redesigned Conversation List View
struct ConversationListView: View {
    @ObservedObject var storageService: ConversationStorageService
    @Binding var selectedConversationId: UUID?
    let isDarkMode: Bool
    let onNewChat: () -> Void
    let onDismiss: () -> Void
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header area
            HStack {
                Text("知道 AI")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Spacer()
                
                // Close sidebar button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                        )
                }
            }
            .padding(16)
            
            // New Chat button
            Button(action: onNewChat) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    
                    Text("新对话")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "3B82F6"))
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Search box
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                
                Text("搜索对话")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                
                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
            )
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.vertical, 8)
                .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
            
            Text("今天")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color(hex: "6B7280"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            // Conversations list
            if storageService.savedConversations.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 36))
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.3) : Color(hex: "D1D5DB"))
                    
                    Text("暂无历史对话")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color(hex: "6B7280"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .frame(maxWidth: .infinity)
            } else {
                // List of conversations
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(storageService.savedConversations.sorted(by: { $0.timestamp > $1.timestamp })) { conversation in
                            ConversationRowItem(
                                conversation: conversation,
                                isSelected: selectedConversationId == conversation.id,
                                dateFormatter: dateFormatter,
                                isDarkMode: isDarkMode
                            )
                            .onTapGesture {
                                withAnimation {
                                    selectedConversationId = conversation.id
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // User profile
            HStack(spacing: 12) {
                // User avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "6366F1"))
                        .frame(width: 36, height: 36)
                    
                    Text("ZW")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // User name
                Text("Zigao Wang")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Spacer()
                
                // Settings
                Button(action: {
                    // Settings action
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(hex: "6B7280"))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                        )
                }
            }
            .padding(16)
            .background(isDarkMode ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF"))
            .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 4, y: -2)
        }
    }
}

// Conversation row item in the sidebar
struct ConversationRowItem: View {
    let conversation: SavedConversation
    let isSelected: Bool
    let dateFormatter: DateFormatter
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "3B82F6"))
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(shortenedQuery)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .lineLimit(1)
                
                Text(dateFormatter.string(from: conversation.timestamp))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.5) : Color(hex: "6B7280"))
            }
            
            Spacer()
            
            if isSelected {
                Circle()
                    .fill(Color(hex: "3B82F6"))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? (isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6")) : Color.clear)
        )
        .padding(.horizontal, 8)
    }
    
    // Limit query length for display
    private var shortenedQuery: String {
        let maxLength = 30
        if conversation.query.count <= maxLength {
            return conversation.query
        } else {
            let endIndex = conversation.query.index(conversation.query.startIndex, offsetBy: maxLength)
            return String(conversation.query[..<endIndex]) + "..."
        }
    }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var firstDotOpacity: Double = 0.4
    @State private var secondDotOpacity: Double = 0.4
    @State private var thirdDotOpacity: Double = 0.4
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .frame(width: 6, height: 6)
                .opacity(firstDotOpacity)
            Circle()
                .frame(width: 6, height: 6)
                .opacity(secondDotOpacity)
            Circle()
                .frame(width: 6, height: 6)
                .opacity(thirdDotOpacity)
        }
        .foregroundColor(Color(hex: "3B82F6"))
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        let duration = 0.4
        let baseDelay = 0.2
        
        withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            firstDotOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay) {
            withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                secondDotOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay * 2) {
            withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                thirdDotOpacity = 1.0
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - Helper Extensions
extension Array {
    // Safe array access that prevents index out of bounds errors
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
