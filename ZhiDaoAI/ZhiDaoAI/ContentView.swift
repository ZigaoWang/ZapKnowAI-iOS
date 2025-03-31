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
    @State private var query = ""
    @State private var isSearchFocused = false
    @State private var showClearButton = false
    @State private var isTyping = false
    @State private var isDirectAnswer = false
    @State private var isDarkMode = false
    @State private var showSettings = false
    @State private var imageUrls: [String] = []
    
    // Animation states
    @State private var searchBarOffset: CGFloat = 0
    @State private var animateGradient = false
    
    private let searchBarHeight: CGFloat = 50
    private let placeholderText = "输入您的研究问题..."
    private let contentPadding: CGFloat = 16
    
    var body: some View {
        ZStack {
            // Background gradient - simplified and more subtle
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // App header
                appHeader
                
                // Search bar
                searchBar
                    .padding(.horizontal, contentPadding)
                    .padding(.bottom, 16)
                
                // Status message
                if !service.statusMessage.isEmpty {
                    statusMessageView(service.statusMessage)
                        .padding(.horizontal, contentPadding)
                        .padding(.bottom, 12)
                        .transition(.opacity)
                }

                // Image results
                if !imageUrls.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(imageUrls, id: \ .self) { url in
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
                        .padding(.horizontal, contentPadding)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Progress stages
                        if service.isStreaming || !service.completedStages.isEmpty {
                            ProgressStagesView(
                                currentStage: service.currentStage,
                                completedStages: Array(service.completedStages)
                            )
                            .padding(.horizontal, contentPadding)
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                            .transition(.opacity)
                        }
                        
                        // Papers list - only show when in paper retrieval or analysis stage
                        if (!service.papers.isEmpty && isPaperRelevantStage) || 
                           (service.isStreaming && isPaperSearching) {
                            PapersListView(
                                papers: service.papers,
                                onPaperTap: { paper in
                                    // Handle paper tap
                                }
                            )
                            .padding(.horizontal, contentPadding)
                            .transition(.opacity)
                        }
                        
                        // Answer section
                        if !service.accumulatedTokens.isEmpty || isGeneratingResponse {
                            answerView
                                .padding(.horizontal, contentPadding)
                                .padding(.bottom, 12)
                                .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.immediately)
                .animation(.easeInOut(duration: 0.2), value: service.isStreaming)
                .animation(.easeInOut(duration: 0.2), value: service.papers.count)
                .animation(.easeInOut(duration: 0.2), value: service.accumulatedTokens)
            }
            
            // Settings panel
            if showSettings {
                settingsPanel
                    .transition(.move(edge: .trailing))
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            withAnimation {
                animateGradient = true
            }
        }
        .onChange(of: service.isStreaming) { _, isStreaming in
            if !isStreaming {
                // When streaming completes, update UI
                withAnimation {
                    isTyping = false
                }
            }
        }
    }
    
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
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(
                colors: isDarkMode ? 
                    [Color(hex: "121212"), Color(hex: "1C1C1E")] :
                    [Color(hex: "F8FAFF"), Color(hex: "F0F4FF")]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - App Header
    private var appHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("知道 AI")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Text("AI 研究助手")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color(hex: "6B7280"))
            }
            
            Spacer()
            
            // Theme toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isDarkMode.toggle()
                }
            }) {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDarkMode ? .yellow : Color(hex: "6B7280"))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Settings button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSettings.toggle()
                }
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, contentPadding)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            
            HStack(spacing: 12) {
                // Search icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                    .padding(.leading, 16)
                
                // Text field
                ZStack(alignment: .leading) {
                    // Placeholder
                    if query.isEmpty && !isSearchFocused {
                        Text(placeholderText)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                    }
                    
                    TextField("", text: $query)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "374151"))
                        .frame(height: searchBarHeight)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSearchFocused = true
                                showClearButton = !query.isEmpty
                            }
                        }
                }
                
                Spacer()
                
                // Clear button
                if showClearButton && !query.isEmpty {
                    Button(action: {
                        withAnimation {
                            query = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                    }
                    .padding(.trailing, 8)
                    .transition(.opacity)
                }
                
                // Search button
                Button(action: {
                    if !query.isEmpty {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        service.streamQuestion(query: query)
                        performImageSearch()
                        
                        withAnimation {
                            isSearchFocused = false
                            isTyping = true
                        }
                    }
                }) {
                    Circle()
                        .fill(Color(hex: "3B82F6"))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                .disabled(query.isEmpty)
                .padding(.trailing, 8)
            }
            .frame(height: searchBarHeight)
        }
        .frame(height: searchBarHeight)
        .padding(.vertical, 8)
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
            .background(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
            .cornerRadius(20)
            .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
        }
    }
    
    // MARK: - Progress Stages View
    struct ProgressStagesView: View {
        var currentStage: ProgressStage?
        var completedStages: [ProgressStage]
        @Environment(\.colorScheme) private var colorScheme
        
        private var isDarkMode: Bool {
            colorScheme == .dark
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header with progress indicator
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 16))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "4B5563"))
                    
                    Text("研究进度")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    Spacer()
                    
                    // Current progress
                    Text("\(completedStages.count + (currentStage != nil ? 1 : 0))/\(ProgressStage.allCases.count)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color(hex: "6B7280"))
                }
                .padding(.horizontal, 4)
                
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                        .shadow(color: isDarkMode ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(ProgressStage.allCases.enumerated()), id: \.element) { index, stage in
                            let isCompleted = completedStages.contains(stage)
                            let isActive = currentStage == stage
                            let isLast = index == ProgressStage.allCases.count - 1
                            
                            HStack(spacing: 12) {
                                // Timeline visualization with connector line
                                ZStack(alignment: .center) {
                                    // Vertical connector line
                                    if !isLast {
                                        Rectangle()
                                            .fill(isCompleted ? Color(hex: "10B981") : Color(hex: "D1D5DB"))
                                            .frame(width: 2)
                                            .offset(y: 10)
                                    }
                                    
                                    // Stage number indicator
                                    ZStack {
                                        Circle()
                                            .fill(isCompleted ? Color(hex: "10B981") : 
                                                  isActive ? Color(hex: "3B82F6") : 
                                                  Color(hex: "D1D5DB"))
                                            .frame(width: 24, height: 24)
                                        
                                        if isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("\(stageNumber(stage))")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .frame(width: 24)
                                
                                // Stage information
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stageName(stage))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                    
                                    Text(stageDescription(stage))
                                        .font(.system(size: 12))
                                        .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color(hex: "6B7280"))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                // Status indicator
                                HStack(spacing: 4) {
                                    if isCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: "10B981"))
                                            .font(.system(size: 12))
                                        
                                        Text("已完成")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color(hex: "10B981"))
                                    } else if isActive {
                                        Text("进行中")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color(hex: "3B82F6"))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color(hex: "3B82F6").opacity(0.15))
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(Color.clear)
                            )
                            
                            if !isLast {
                                Divider()
                                    .padding(.leading, 36)
                                    .opacity(0.5)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        
        // Helper functions
        private func stageNumber(_ stage: ProgressStage) -> Int {
            switch stage {
            case .evaluation:
                return 1
            case .paperRetrieval:
                return 2
            case .paperAnalysis:
                return 3
            case .answerGeneration:
                return 4
            }
        }
        
        private func stageName(_ stage: ProgressStage) -> String {
            switch stage {
            case .evaluation:
                return "评估问题"
            case .paperRetrieval:
                return "检索论文"
            case .paperAnalysis:
                return "分析论文"
            case .answerGeneration:
                return "生成答案"
            }
        }
        
        private func stageDescription(_ stage: ProgressStage) -> String {
            switch stage {
            case .evaluation:
                return "分析您的问题并确定研究方向"
            case .paperRetrieval:
                return "搜索和筛选相关学术论文"
            case .paperAnalysis:
                return "深入分析论文内容和关键发现"
            case .answerGeneration:
                return "综合研究结果生成全面答案"
            }
        }
    }
    
    // MARK: - Settings Panel
    private var settingsPanel: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 20) {
                Text("关于")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("知道 AI")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    Text("由 Zigao Wang 开发")
                        .font(.system(size: 14))
                        .foregroundColor(isDarkMode ? Color(hex: "D1D5DB") : Color(hex: "6B7280"))
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com/zigaowang") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "link")
                                .font(.system(size: 14))
                            Text("GitHub")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(Color(hex: "3B82F6"))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 4)
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(24)
            .frame(width: UIScreen.main.bounds.width * 0.8)
            .background(
                isDarkMode ? Color(hex: "1A1A1A") : Color.white
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            // Close button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showSettings = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .padding(12)
                    .background(
                        Circle()
                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(20)
        }
        .edgesIgnoringSafeArea(.all)
        .background(
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSettings = false
                    }
                }
        )
    }
    
    // MARK: - Actions
    private func startSearch() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Animate search button press
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isSearchFocused = false
            showClearButton = false
            isTyping = true
        }
        
        // Start streaming the question
        service.streamQuestion(query: query)
    }
    
    private func performImageSearch() {
        let imageSearchService = ImageSearchService()
        imageSearchService.searchImages(query: query) { result in
            switch result {
            case .success(let urls):
                DispatchQueue.main.async {
                    self.imageUrls = urls
                }
            case .failure(let error):
                print("Error fetching images: \(error)")
            }
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
