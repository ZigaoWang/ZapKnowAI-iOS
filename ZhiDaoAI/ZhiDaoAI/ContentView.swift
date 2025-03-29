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
    
    // Animation states
    @State private var showPlaceholder = true
    @State private var searchBarOffset: CGFloat = 0
    @State private var animateGradient = false
    
    private let searchBarHeight: CGFloat = 50
    private let placeholderText = "输入您的研究问题..."
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
            
            VStack(spacing: 0) {
                // App header
                appHeader
                
                // Search bar
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Status message
                if !service.statusMessage.isEmpty {
                    statusMessageView(service.statusMessage)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Progress stages
                        if service.isStreaming || !service.completedStages.isEmpty {
                            ProgressStagesView(
                                currentStage: service.currentStage,
                                completedStages: Array(service.completedStages)
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
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
                            .padding(.horizontal, 20)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                        
                        // Answer section
                        if !service.accumulatedTokens.isEmpty || isGeneratingResponse {
                            answerView
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.immediately)
                .animation(.easeInOut(duration: 0.3), value: service.isStreaming)
                .animation(.easeInOut(duration: 0.3), value: service.papers.count)
                .animation(.easeInOut(duration: 0.3), value: service.accumulatedTokens)
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
                    [Color(hex: "121212"), Color(hex: "1E1E1E")] :
                    [Color(hex: "F0F4FF"), Color(hex: "E6F0FF")]
            ),
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
    }
    
    // MARK: - App Header
    private var appHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("知道 AI")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .shadow(color: isDarkMode ? Color.black.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)
                
                Text("AI 研究助手")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color(hex: "6B7280"))
            }
            
            Spacer()
            
            // Theme toggle button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isDarkMode.toggle()
                }
            }) {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDarkMode ? .yellow : Color(hex: "6B7280"))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Settings button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showSettings.toggle()
                }
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
            
            HStack(spacing: 14) {
                // Search icon with animation
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                    .padding(.leading, 20)
                    .scaleEffect(isSearchFocused ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSearchFocused)
                
                // Text field
                ZStack(alignment: .leading) {
                    // Placeholder
                    if query.isEmpty && !isSearchFocused {
                        Text(placeholderText)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                            .padding(.leading, 2)
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
                        .onChange(of: query) { _, newValue in
                            showClearButton = !newValue.isEmpty && isSearchFocused
                        }
                        .onSubmit {
                            if !query.isEmpty {
                                startSearch()
                            }
                        }
                }
                
                // Clear button
                if showClearButton {
                    Button(action: {
                        query = ""
                        showClearButton = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                    }
                    .transition(.opacity)
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Search button
                if !query.isEmpty {
                    Button(action: {
                        startSearch()
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "3B82F6"))
                            .padding(.trailing, 16)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.vertical, 4)
        }
        .frame(height: 56)
    }
    
    // MARK: - Status Message View
    private func statusMessageView(_ status: String) -> some View {
        HStack(spacing: 14) {
            if isTyping {
                // Animated loading indicator
                LoadingDotsView()
                    .frame(width: 40, height: 10)
            } else {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "3B82F6"))
            }
            
            Text(status)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(isDarkMode ? .white : Color(hex: "374151"))
                .lineLimit(2)
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
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
                    LoadingDotsView()
                        .frame(width: 40, height: 10)
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
                        LoadingDotsView()
                            .frame(width: 40, height: 10)
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
        @State private var animateStages: Bool = false
        
        private var isDarkMode: Bool {
            return colorScheme == .dark
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header with simple animation
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "3B82F6"))
                    
                    Text("研究进度")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    Spacer()
                    
                    // Progress counter
                    HStack(spacing: 2) {
                        let completedCount = completedStages.count
                        let total = ProgressStage.allCases.count
                        
                        Text("\(completedCount)/\(total)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isDarkMode ? Color(hex: "1E293B") : Color(hex: "EFF6FF"))
                    )
                }
                .padding(.horizontal, 8)
                .opacity(animateStages ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: animateStages)
                
                // Progress timeline with simplified visualization
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 24)
                        .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                        .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), 
                                radius: 12, x: 0, y: 4)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(ProgressStage.allCases.enumerated()), id: \.element) { index, stage in
                            let isCompleted = completedStages.contains(stage)
                            let isActive = currentStage == stage
                            let isLast = index == ProgressStage.allCases.count - 1
                            
                            HStack(spacing: 16) {
                                // Timeline visualization with connector line
                                ZStack(alignment: .center) {
                                    // Vertical connector line
                                    if !isLast {
                                        Rectangle()
                                            .fill(connectorColor(for: stage, isCompleted: isCompleted, nextStageActive: currentStage == ProgressStage.allCases[safe: index + 1]))
                                            .frame(width: 2)
                                            .frame(height: 40)
                                            .offset(y: 32)
                                    }
                                    
                                    // Status indicator circle
                                    ZStack {
                                        // Main circle
                                        Circle()
                                            .fill(stageColor(stage: stage, isCompleted: isCompleted, isActive: isActive))
                                            .frame(width: 32, height: 32)
                                        
                                        // Status indicators
                                        if isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        } else if isActive {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                                .tint(.white)
                                        } else {
                                            Text("\(stageNumber(stage))")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                                        }
                                    }
                                }
                                .frame(width: 32)
                                
                                // Stage content 
                                VStack(alignment: .leading, spacing: 6) {
                                    // Stage title with badge for active stage
                                    HStack(alignment: .center, spacing: 8) {
                                        Text(stage.displayText)
                                            .font(.system(size: 16, weight: isActive || isCompleted ? .semibold : .medium, design: .rounded))
                                            .foregroundColor(
                                                isActive ? Color(hex: "3B82F6") :
                                                isCompleted ? (isDarkMode ? .white : Color(hex: "111827")) :
                                                (isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                                            )
                                        
                                        if isActive {
                                            Text("进行中")
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(
                                                    Capsule()
                                                        .fill(Color(hex: "3B82F6"))
                                                )
                                        }
                                    }
                                    
                                    // Stage description
                                    Text(stageDescription(stage))
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                                        .opacity(isActive || isCompleted ? 1.0 : 0.7)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Status
                                HStack(spacing: 4) {
                                    if isCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: "10B981"))
                                            .font(.system(size: 14))
                                        
                                        Text("已完成")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(Color(hex: "10B981"))
                                    } else if isActive {
                                        Circle()
                                            .fill(Color(hex: "3B82F6"))
                                            .frame(width: 8, height: 8)
                                        
                                        Text("进行中")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(Color(hex: "3B82F6"))
                                    }
                                }
                                .frame(width: 70, alignment: .trailing)
                            }
                            .padding(.vertical, 18)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        isActive ? 
                                            (isDarkMode ? Color(hex: "1E293B").opacity(0.7) : Color(hex: "EFF6FF").opacity(0.7)) :
                                            Color.clear
                                    )
                            )
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .padding(8)
                .opacity(animateStages ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: animateStages)
            }
            .onAppear {
                // Simple fade in
                withAnimation(.easeIn(duration: 0.3)) {
                    animateStages = true
                }
            }
            .onChange(of: currentStage) { _, _ in
                // Brief reset and fade in when stage changes
                animateStages = false
                withAnimation(.easeIn(duration: 0.3)) {
                    animateStages = true
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
        
        private func stageColor(stage: ProgressStage, isCompleted: Bool, isActive: Bool) -> Color {
            if isCompleted {
                return Color(hex: "10B981") // Green for completed
            } else if isActive {
                return Color(hex: "3B82F6") // Blue for active
            } else {
                return isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F3F4F6") // Gray for inactive
            }
        }
        
        private func connectorColor(for stage: ProgressStage, isCompleted: Bool, nextStageActive: Bool) -> Color {
            if isCompleted {
                // Completed stage connector uses success color
                return Color(hex: "10B981")
            } else if nextStageActive {
                // Active stage incoming connector uses active color
                return Color(hex: "3B82F6")
            } else {
                // Inactive connector uses neutral color
                return isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "E5E7EB")
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
            .cornerRadius(20, corners: [.topLeft, .bottomLeft])
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
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Loading Dots View
struct LoadingDotsView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(hex: "3B82F6"))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .opacity(isAnimating ? 1 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - RoundedCorner Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
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
