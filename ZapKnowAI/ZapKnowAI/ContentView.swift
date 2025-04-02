//
//  ContentView.swift
//  ZhiDaoAI
//
//  Created by Zigao Wang on 3/26/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var userSettings: UserSettings
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
    
    // Focus state for the text field
    @FocusState private var isTextFieldFocused: Bool
    
    // Sidebar and conversation states
    @State private var showSidebar = false
    @State private var selectedConversationId: UUID? = nil
    
    // Animation states
    @State private var animateGradient = false
    
    // Collapse/expand states
    @State private var isSourcesExpanded = false
    @State private var isPapersExpanded = false
    @State private var isImagesExpanded = false
    @State private var isArticlesExpanded = false
    
    // Response content separation states
    @State private var paperAnalysisContent = ""
    @State private var synthesisContent = ""
    @State private var isPaperAnalysisComplete = false
    @State private var isPaperAnalysisExpanded = true
    
    private let searchBarHeight: CGFloat = 50
    private let placeholderText = NSLocalizedString("Ask a question...", comment: "Search bar placeholder text")
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Example questions
    private let exampleQuestions = [
        NSLocalizedString("癌症治疗的最新研究进展是什么?", comment: "Example question about cancer research"),
        NSLocalizedString("量子计算如何应用于密码学?", comment: "Example question about quantum computing"),
        NSLocalizedString("机器学习在医疗诊断中的应用有哪些?", comment: "Example question about machine learning"),
        NSLocalizedString("全球变暖对海洋生态系统有什么影响?", comment: "Example question about global warming")
    ]
    
    var body: some View {
        ZStack {
            // Main background - using same color for entire background
            Color(hex: isDarkMode ? "121212" : "F9F9F9")
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Top navigation area
                topBar
                
                // Main content
                ZStack {
                    // Use the same background color for content area
                    Color(hex: isDarkMode ? "121212" : "F9F9F9")
                        .ignoresSafeArea()
                    
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
                                // Enhanced empty state / welcome screen
                                welcomeView
                            } else {
                                // Active chat with results
                                chatResultsView
                            }
                        }
                        
                        // Input area always shown at bottom
                        queryInputBar
                    }
                    .background(Color(hex: isDarkMode ? "121212" : "F9F9F9"))
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
                                
                                // Dismiss keyboard
                                isTextFieldFocused = false
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                    
                    // Drawer content with fixed animation
                    HStack(spacing: 0) {
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 0) {
                                // Header area with improved design
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(NSLocalizedString("知道 AI", comment: "App name"))
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                    
                                    Text(NSLocalizedString("你的研究伙伴", comment: "App subtitle"))
                                        .font(.system(size: 16))
                                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(hex: "6B7280"))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 24)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                
                                // New Chat button with enhanced design
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
                                        
                                        Text(NSLocalizedString("新对话", comment: "New chat button text"))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "3B82F6"),
                                                Color(hex: "6366F1")
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                                
                                // Search box with improved design
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 16))
                                        .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                                    
                                    Text(NSLocalizedString("搜索对话", comment: "Search conversations placeholder"))
                                        .font(.system(size: 15))
                                        .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isDarkMode ? Color(hex: "1E1E1E") : Color(hex: "F3F4F6"))
                                )
                                .padding(.horizontal, 20)
                                
                                Divider()
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                
                                // Section title with improved styling
                                Text(NSLocalizedString("今天", comment: "Today section header"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.8) : Color(hex: "6B7280"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 8)
                                
                                // Conversations list with improved styling
                                if storageService.savedConversations.isEmpty {
                                    // Empty state with improved visual
                                    VStack(spacing: 20) {
                                        ZStack {
                                            Circle()
                                                .fill(isDarkMode ? Color(hex: "1E1E1E") : Color(hex: "F3F4F6"))
                                                .frame(width: 80, height: 80)
                                            
                                            Image(systemName: "bubble.left.and.bubble.right")
                                                .font(.system(size: 32))
                                                .foregroundColor(isDarkMode ? Color.white.opacity(0.5) : Color(hex: "9CA3AF"))
                                        }
                                        
                                        Text(NSLocalizedString("暂无历史对话", comment: "No history message"))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color(hex: "6B7280"))
                                            .multilineTextAlignment(.center)
                                        
                                        Text(NSLocalizedString("开始一个新对话来探索知识", comment: "Start new chat message"))
                                            .font(.system(size: 14))
                                            .foregroundColor(isDarkMode ? Color.white.opacity(0.5) : Color(hex: "9CA3AF"))
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.top, 60)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity)
                                } else {
                                    // List of conversations
                                    ScrollView {
                                        LazyVStack(spacing: 8) {
                                            ForEach(storageService.savedConversations.sorted(by: { $0.timestamp > $1.timestamp })) { conversation in
                                                HStack(spacing: 12) {
                                                    // Icon with enhanced design
                                                    ZStack {
                                                        Circle()
                                                            .fill(selectedConversationId == conversation.id ? Color(hex: "3B82F6").opacity(0.2) : (isDarkMode ? Color(hex: "1E1E1E") : Color(hex: "F3F4F6")))
                                                            .frame(width: 36, height: 36)
                                                        
                                                        Image(systemName: "text.bubble.fill")
                                                            .font(.system(size: 16))
                                                            .foregroundColor(selectedConversationId == conversation.id ? Color(hex: "3B82F6") : (isDarkMode ? Color.white.opacity(0.6) : Color(hex: "6B7280")))
                                                    }
                                                    
                                                    // Text content with enhanced typography
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(shortenConversationQuery(conversation.query))
                                                            .font(.system(size: 14, weight: selectedConversationId == conversation.id ? .semibold : .medium))
                                                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                                            .lineLimit(1)
                                                        
                                                        Text(dateFormatter.string(from: conversation.timestamp))
                                                            .font(.system(size: 12))
                                                            .foregroundColor(isDarkMode ? Color.white.opacity(0.5) : Color(hex: "6B7280"))
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    if selectedConversationId == conversation.id {
                                                        Circle()
                                                            .fill(Color(hex: "3B82F6"))
                                                            .frame(width: 8, height: 8)
                                                    }
                                                }
                                                .padding(12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedConversationId == conversation.id ? (isDarkMode ? Color(hex: "1E1E1E") : Color(hex: "F3F4F6")) : Color.clear)
                                                )
                                                .padding(.horizontal, 12)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    selectedConversationId = conversation.id
                                                    withAnimation(.easeOut(duration: 0.25)) {
                                                        showSidebar = false
                                                        
                                                        // Dismiss keyboard
                                                        isTextFieldFocused = false
                                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                }
                                
                                Spacer()
                                
                                // User profile with improved design
                                HStack(spacing: 12) {
                                    // User avatar with gradient
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(hex: "6366F1"),
                                                        Color(hex: "8B5CF6")
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 48, height: 48)
                                        
                                        Text(userSettings.userName.isEmpty ? "?" : String(userSettings.userName.prefix(1).uppercased()))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    // User name and role
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(userSettings.userName.isEmpty ? NSLocalizedString("游客", comment: "Guest user") : userSettings.userName)
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                        
                                        Text(NSLocalizedString("研究员", comment: "Researcher role"))
                                            .font(.system(size: 14))
                                            .foregroundColor(isDarkMode ? .white.opacity(0.5) : Color(hex: "6B7280"))
                                    }
                                    
                                    Spacer()
                                    
                                    // Settings
                                    Button(action: {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        
                                        // Dismiss keyboard when opening settings
                                        isTextFieldFocused = false
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            showSettings = true
                                            showSidebar = false
                                        }
                                    }) {
                                        Image(systemName: "gear")
                                            .font(.system(size: 16))
                                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(hex: "6B7280"))
                                            .frame(width: 36, height: 36)
                                            .background(
                                                Circle()
                                                    .fill(isDarkMode ? Color(hex: "1E1E1E") : Color(hex: "F3F4F6"))
                                            )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                                .padding(20)
                                .background(isDarkMode ? Color(hex: "121212") : Color(hex: "FFFFFF"))
                            }
                            
                            // Close button with improved design
                            Button {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showSidebar = false
                                    
                                    // Dismiss keyboard
                                    isTextFieldFocused = false
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(isDarkMode ? Color(hex: "1E1E1E") : Color(hex: "F3F4F6"))
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(20)
                        }
                        .frame(width: min(UIScreen.main.bounds.width * 0.85, 320))
                        .background(Color(hex: isDarkMode ? "121212" : "FFFFFF"))
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.move(edge: .leading))
                }
                
                // Settings as a full screen page instead of an overlay
                if showSettings {
                    SettingsView(
                        isDarkMode: $isDarkMode,
                        isShowing: $showSettings,
                        onReset: resetAll
                    )
                    .transition(.move(edge: .bottom))
                    .zIndex(3)
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.easeOut(duration: 0.25), value: showSidebar)
        .animation(.easeOut(duration: 0.25), value: showSettings)
        .onAppear {
            // Auto focus the text field when the app opens but only on the main screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !showSettings && !showSidebar && selectedConversationId == nil {
                    self.isTextFieldFocused = true
                }
            }
        }
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
    
    // Enhanced welcome screen but simpler and cooler
    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Clean, modern hero section with subtle gradient
                ZStack {
                    // Subtle animated gradient background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "3B82F6"),
                                    Color(hex: "6366F1")
                                ]),
                                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                                endPoint: animateGradient ? .bottomTrailing : .topLeading
                            )
                        )
                        .onAppear {
                            withAnimation(.linear(duration: 5).repeatForever(autoreverses: true)) {
                                animateGradient.toggle()
                            }
                        }
                    
                    VStack(spacing: 20) {
                        // App logo with subtle glow
                        Group {
                            if let _ = UIImage(named: "AppLogo") {
                                Image("AppLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(16)
                                    .shadow(color: Color.white.opacity(0.3), radius: 10, x: 0, y: 0)
                            } else {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 80)
                                    .background(
                                        Circle()
                                            .fill(Color(hex: "3B82F6").opacity(0.8))
                                            .shadow(color: Color.white.opacity(0.3), radius: 10, x: 0, y: 0)
                                    )
                            }
                        }
                        
                        Text(NSLocalizedString("知道 AI", comment: "App name"))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(NSLocalizedString("智能研究助手", comment: "App description"))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.vertical, 40)
                }
                .frame(height: 280)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Example questions in a cleaner design
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString("试试以下问题", comment: "Try these questions"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                        .padding(.horizontal, 20)
                    
                    ForEach(exampleQuestions, id: \.self) { question in
                        Button {
                            query = question
                            submitQuery()
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: "3B82F6").opacity(0.1))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: categoryIcon(for: question))
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "3B82F6"))
                                    )
                                
                                Text(question)
                                    .font(.system(size: 15))
                                    .foregroundColor(isDarkMode ? .white : Color(hex: "374151"))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "3B82F6"))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                                    .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }
    
    // Helper function for welcome page feature rows
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "3B82F6").opacity(0.1))
                    .frame(width: 42, height: 42)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "3B82F6"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(hex: "6B7280"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // Helper function to determine icon for example questions
    private func categoryIcon(for question: String) -> String {
        if question.contains("癌症") {
            return "heart.text.square.fill"
        } else if question.contains("量子") {
            return "atom"
        } else if question.contains("机器学习") {
            return "cpu.fill"
        } else if question.contains("变暖") {
            return "leaf.fill"
        } else {
            return "questionmark.circle.fill"
        }
    }
    
    // Updated top navigation bar to fix color inconsistency
    private var topBar: some View {
        HStack(spacing: 16) {
            // Menu button
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    showSidebar.toggle()
                    
                    // Dismiss keyboard when opening sidebar
                    isTextFieldFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: isDarkMode ? "FFFFFF" : "232323"))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(hex: isDarkMode ? "1E1E1E" : "FFFFFF").opacity(0.8))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            // App title (shown when no conversation is selected)
            if selectedConversationId == nil {
                HStack(spacing: 8) {
                    Text(NSLocalizedString("知道 AI", comment: "App name"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: isDarkMode ? "FFFFFF" : "232323"))
                }
            }
            
            Spacer()
            
            // Settings button
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Dismiss keyboard when opening settings
                isTextFieldFocused = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
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
                            .fill(Color(hex: isDarkMode ? "1E1E1E" : "FFFFFF").opacity(0.8))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            // Use a clear background with no shadow for the top bar
            Color(hex: isDarkMode ? "121212" : "F9F9F9")
        )
    }
    
    // Update query input bar to use the focus state
    private var queryInputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
            
            HStack(alignment: .center, spacing: 10) {
                // Text field with improved styling and focus
                TextField(placeholderText, text: $query)
                    .font(.system(size: 16))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                            .shadow(color: isDarkMode ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    )
                    .focused($isTextFieldFocused)
                    .onTapGesture {
                        isSearchFocused = true
                    }
                
                // Send/stop button with matching height
                Button(action: submitQuery) {
                    HStack {
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
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(service.isStreaming ? Color.red : Color(hex: query.isEmpty ? "D1D5DB" : "3B82F6"))
                    )
                }
                .disabled(query.isEmpty && !service.isStreaming)
                .scaleEffect(service.isStreaming ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: service.isStreaming)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: isDarkMode ? "121212" : "F9F9F9"))
        }
    }
    
    // Modify the chat results view to handle paper analysis and synthesis separately
    private var chatResultsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status message with improved visual design
                if !service.statusMessage.isEmpty {
                    statusMessageView(service.statusMessage)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 4)
                        .transition(.opacity)
                }

                // Progress stages with enhanced visual feedback
                if service.isStreaming || !service.completedStages.isEmpty {
                    ProgressStagesView(
                        currentStage: service.currentStage,
                        completedStages: service.completedStages
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .transition(.opacity)
                }
                
                // Images display at the top (always visible)
                if !imageUrls.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "3B82F6"))
                                
                            Text(NSLocalizedString("相关图片", comment: "Related images"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                        }
                        .padding(.horizontal, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(imageUrls, id: \.self) { url in
                                    AsyncImage(url: URL(string: url)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 150)
                                            .clipped()
                                            .cornerRadius(12)
                                            .shadow(color: isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                                            .frame(width: 200, height: 150)
                                            .cornerRadius(12)
                                            .overlay(
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                            )
                                    }
                                    .padding(.leading, imageUrls.firstIndex(of: url) == 0 ? 16 : 0)
                                    .padding(.trailing, imageUrls.lastIndex(of: url) == imageUrls.count - 1 ? 16 : 0)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Sources section with papers and articles (collapsed by default)
                if (!service.papers.isEmpty || !articles.isEmpty) && 
                   (!service.isStreaming || service.accumulatedTokens.isNotEmpty) {
                    collapsedSourcesSection
                }
                
                // Paper Analysis section (collapsible, auto-collapses when complete)
                if !paperAnalysisContent.isEmpty {
                    paperAnalysisView
                }
                
                // Synthesis (final answer) section
                if !synthesisContent.isEmpty || (isGeneratingResponse && isPaperAnalysisComplete) {
                    synthesisView
                }
                
                Spacer().frame(height: 80) // Bottom padding for input field
            }
            .animation(.easeInOut(duration: 0.3), value: service.isStreaming)
            .animation(.easeInOut(duration: 0.3), value: service.papers.count)
            .animation(.easeInOut(duration: 0.3), value: service.accumulatedTokens)
            .animation(.easeInOut(duration: 0.3), value: imageUrls.count)
            .animation(.easeInOut(duration: 0.3), value: articles.count)
            .animation(.easeInOut(duration: 0.3), value: isSourcesExpanded)
            .animation(.easeInOut(duration: 0.3), value: isPapersExpanded)
            .animation(.easeInOut(duration: 0.3), value: isArticlesExpanded)
            .animation(.easeInOut(duration: 0.3), value: isPaperAnalysisExpanded)
            .animation(.easeInOut(duration: 0.3), value: isPaperAnalysisComplete)
        }
        .scrollDismissesKeyboard(.immediately)
        .onChange(of: service.accumulatedTokens) { _, newText in
            processAccumulatedTokens(newText)
        }
    }
    
    // Collapsed sources section (papers and articles)
    private var collapsedSourcesSection: some View {
        VStack(spacing: 12) {
            // Sources Header
            Button(action: {
                withAnimation {
                    isSourcesExpanded.toggle()
                    // If sources is collapsed, collapse all subsections
                    if !isSourcesExpanded {
                        isPapersExpanded = false
                        isArticlesExpanded = false
                    }
                }
            }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "3B82F6"))
                        
                    Text("查看论文和延伸阅读")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    Spacer()
                    
                    // Show count of papers and articles
                    Text("\(service.papers.count + articles.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                        )
                    
                    Image(systemName: isSourcesExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                        .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Expanded Sources Content
            if isSourcesExpanded {
                VStack(spacing: 16) {
                    // Papers section
                    if !service.papers.isEmpty && isPaperRelevantStage {
                        papersSection
                    }
                    
                    // Articles section
                    if !articles.isEmpty {
                        articlesSection
                    }
                }
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // Papers section (collapsible)
    private var papersSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                withAnimation {
                    isPapersExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "3B82F6"))
                        
                    Text(NSLocalizedString("参考论文", comment: "Reference papers"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    Spacer()
                    
                    Text("\(service.papers.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                    
                    Image(systemName: isPapersExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                        .padding(.leading, 4)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDarkMode ? Color(hex: "262626") : Color(hex: "F3F4F6"))
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            if isPapersExpanded {
                PapersListView(
                    papers: service.papers,
                    onPaperTap: { paper in
                        // Handle paper tap
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // Articles section (collapsible)
    private var articlesSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                withAnimation {
                    isArticlesExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "book")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "3B82F6"))
                        
                    Text(NSLocalizedString("延伸阅读", comment: "Further reading"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    Spacer()
                    
                    Text("\(articles.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                    
                    Image(systemName: isArticlesExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                        .padding(.leading, 4)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDarkMode ? Color(hex: "262626") : Color(hex: "F3F4F6"))
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            if isArticlesExpanded {
                VStack(spacing: 8) {
                    ForEach(articles) { article in
                        ArticleCardView(article: article, isDarkMode: isDarkMode)
                            .padding(.bottom, 8)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Status Message View
    private func statusMessageView(_ message: String) -> some View {
        HStack(spacing: 12) {
            if isTyping {
                // Typing indicator with improved animation
                TypingIndicator()
                    .frame(width: 40, height: 20)
            } else {
                ZStack {
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "ellipsis.bubble")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "3B82F6"))
                }
            }
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(isDarkMode ? .white.opacity(0.9) : Color(hex: "4B5563"))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Answer View
    private var answerView: some View {
        // If we have separated content, use synthesisView
        if !synthesisContent.isEmpty {
            return AnyView(synthesisView)
        }
        
        // Otherwise use the combined view
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // Answer header with enhanced design
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "3B82F6").opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                    
                    Text(NSLocalizedString("原始问题", comment: "Original question"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    Spacer()
                    
                    // Show generating status when generating answer
                    if isGeneratingResponse && service.accumulatedTokens.isEmpty {
                        TypingIndicator()
                            .frame(width: 40, height: 20)
                    }
                    
                    // Copy button with enhanced design
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
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                            )
                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Answer content with enhanced markdown styling
                VStack(alignment: .leading, spacing: 0) {
                    // Markdown content with improved styling
                    MarkdownView_Native(markdown: service.accumulatedTokens)
                        .padding(24)
                        .environment(\.colorScheme, isDarkMode ? .dark : .light)
                    
                    // Typing indicator - only show when actively generating the answer
                    if isTyping && isGeneratingResponse {
                        HStack {
                            TypingIndicator()
                                .frame(width: 40, height: 20)
                                .padding(.vertical, 8)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                }
                .background(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                .cornerRadius(20)
                .shadow(color: isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
            }
        )
    }
    
    // MARK: - Helper Functions
    
    // Submit a new query
    private func submitQuery() {
        guard !query.isEmpty else { return }
        
        // Reset split content
        paperAnalysisContent = ""
        synthesisContent = ""
        isPaperAnalysisComplete = false
        isPaperAnalysisExpanded = true
        
        // Hide keyboard when submitting
        isTextFieldFocused = false
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
            
            // Reset split content
            paperAnalysisContent = ""
            synthesisContent = ""
            isPaperAnalysisComplete = false
            isPaperAnalysisExpanded = true
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
        
        // Reset split content
        paperAnalysisContent = ""
        synthesisContent = ""
        isPaperAnalysisComplete = false
        isPaperAnalysisExpanded = true
        
        // Clear saved conversations
        storageService.deleteAllConversations()
        
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
    
    // Helper function to shorten conversation query
    private func shortenConversationQuery(_ query: String) -> String {
        let maxLength = 30
        if query.count <= maxLength {
            return query
        } else {
            let endIndex = query.index(query.startIndex, offsetBy: maxLength)
            return String(query[..<endIndex]) + "..."
        }
    }
    
    // Process the accumulated tokens to separate paper analysis from synthesis
    private func processAccumulatedTokens(_ text: String) {
        // Check if the text contains a synthesis marker
        if let synthesisRange = text.range(of: "SYNTHESIS:", options: .caseInsensitive) {
            // Extract paper analysis (everything before SYNTHESIS)
            let paperAnalysisEnd = synthesisRange.lowerBound
            paperAnalysisContent = String(text[..<paperAnalysisEnd])
            
            // Extract synthesis (everything after SYNTHESIS)
            let synthesisStart = text.index(after: synthesisRange.upperBound)
            if synthesisStart < text.endIndex {
                synthesisContent = String(text[synthesisStart...])
            }
            
            // Mark paper analysis as complete
            if !isPaperAnalysisComplete {
                isPaperAnalysisComplete = true
                // Auto-collapse paper analysis once complete
                withAnimation {
                    isPaperAnalysisExpanded = false
                }
            }
        } else {
            // No synthesis marker yet, all content is paper analysis
            paperAnalysisContent = text
        }
    }
    
    // Paper Analysis View (collapsible)
    private var paperAnalysisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with collapse/expand button
            Button(action: {
                withAnimation {
                    isPaperAnalysisExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "3B82F6").opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                    
                    Text(NSLocalizedString("论文分析", comment: "Paper analysis"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    
                    Spacer()
                    
                    if isGeneratingResponse && !isPaperAnalysisComplete {
                        TypingIndicator()
                            .frame(width: 40, height: 20)
                    }
                    
                    Image(systemName: isPaperAnalysisExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .buttonStyle(ScaleButtonStyle())
            
            if isPaperAnalysisExpanded {
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    MarkdownView_Native(markdown: paperAnalysisContent)
                        .padding(24)
                        .environment(\.colorScheme, isDarkMode ? .dark : .light)
                    
                    // Typing indicator - only show when actively generating paper analysis
                    if isTyping && isGeneratingResponse && !isPaperAnalysisComplete {
                        HStack {
                            TypingIndicator()
                                .frame(width: 40, height: 20)
                                .padding(.vertical, 8)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                }
                .background(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                .cornerRadius(20)
                .shadow(color: isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // Synthesis View (final answer)
    private var synthesisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Answer header with enhanced design
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "3B82F6"))
                }
                
                Text(NSLocalizedString("研究答案", comment: "Research answer"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Spacer()
                
                // Show generating status when generating answer
                if isGeneratingResponse && isPaperAnalysisComplete && synthesisContent.isEmpty {
                    TypingIndicator()
                        .frame(width: 40, height: 20)
                }
                
                // Copy button with enhanced design
                if !synthesisContent.isEmpty {
                    Button(action: {
                        UIPasteboard.general.string = synthesisContent
                        // Add haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                            
                            Text("复制")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                        )
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Answer content with enhanced markdown styling
            VStack(alignment: .leading, spacing: 0) {
                // Markdown content with improved styling
                MarkdownView_Native(markdown: synthesisContent)
                    .padding(24)
                    .environment(\.colorScheme, isDarkMode ? .dark : .light)
                
                // Typing indicator - only show when actively generating synthesis
                if isTyping && isGeneratingResponse && isPaperAnalysisComplete && synthesisContent.isEmpty {
                    HStack {
                        TypingIndicator()
                            .frame(width: 40, height: 20)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
            .background(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
            .cornerRadius(20)
            .shadow(color: isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .transition(.opacity)
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
        ContentView(userSettings: UserSettings())
    }
}

// MARK: - Helper Extensions
extension Array {
    // Safe array access that prevents index out of bounds errors
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var isDarkMode: Bool
    @Binding var isShowing: Bool
    var onReset: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background that matches the app's theme
                Color(hex: isDarkMode ? "121212" : "F9F9F9")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Theme section
                        settingsSection(title: NSLocalizedString("显示设置", comment: "Display settings")) {
                            VStack(spacing: 0) {
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
                                            .frame(width: 36, height: 36)
                                            .background(
                                                Circle()
                                                    .fill(isDarkMode ? Color.white.opacity(0.15) : Color.indigo.opacity(0.1))
                                            )
                                        
                                        Text(NSLocalizedString(isDarkMode ? "亮色模式" : "深色模式", comment: "Theme mode"))
                                            .font(.system(size: 16))
                                            .foregroundColor(isDarkMode ? .white : .black)
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: $isDarkMode)
                                            .labelsHidden()
                                            .tint(Color(hex: "3B82F6"))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isDarkMode ? Color(hex: "1E1E1E") : .white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: isDarkMode ? "333333" : "EEEEEE"), lineWidth: 1)
                            )
                        }
                        
                        // Data management section
                        settingsSection(title: NSLocalizedString("数据管理", comment: "Data management")) {
                            VStack(spacing: 0) {
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
                                        onReset()
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            isShowing = false
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
                                            .frame(width: 36, height: 36)
                                            .background(
                                                Circle()
                                                    .fill(Color.red.opacity(0.1))
                                            )
                                        
                                        Text(NSLocalizedString("重置所有对话", comment: "Reset all conversations"))
                                            .font(.system(size: 16))
                                            .foregroundColor(isDarkMode ? .white : .black)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(isDarkMode ? .white.opacity(0.4) : .black.opacity(0.3))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isDarkMode ? Color(hex: "1E1E1E") : .white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: isDarkMode ? "333333" : "EEEEEE"), lineWidth: 1)
                            )
                        }
                        
                        // About section with app info
                        settingsSection(title: NSLocalizedString("关于 知道AI", comment: "About ZapKnowAI")) {
                            VStack(spacing: 24) {
                                // App logo and basic info
                                HStack(spacing: 20) {
                                    // App logo
                                    Group {
                                        if let _ = UIImage(named: "AppLogo") {
                                            Image("AppLogo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 72, height: 72)
                                                .cornerRadius(14)
                                        } else {
                                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                                .font(.system(size: 36))
                                                .foregroundColor(Color(hex: "3B82F6"))
                                                .frame(width: 72, height: 72)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                                                )
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(NSLocalizedString("知道 AI", comment: "App name"))
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                        
                                        Text(NSLocalizedString("版本 1.0.0", comment: "App version"))
                                            .font(.system(size: 16))
                                            .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                
                                // App description
                                Text(NSLocalizedString("知道AI是一款智能研究助手，帮助用户获取学术论文分析、研究数据和相关图片资料，提供深入的科研问题解答。", comment: "App description"))
                                    .font(.system(size: 15))
                                    .lineSpacing(4)
                                    .foregroundColor(isDarkMode ? .white.opacity(0.8) : Color(hex: "4B5563"))
                                    .padding(.horizontal, 16)
                                
                                // Features list
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(NSLocalizedString("主要功能", comment: "Main features"))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                    
                                    featureRow(iconName: "magnifyingglass", text: NSLocalizedString("智能搜索和分析学术论文", comment: "Feature: Smart paper search and analysis"))
                                    featureRow(iconName: "doc.text", text: NSLocalizedString("提供多语言研究内容解答", comment: "Feature: Multilingual research answers"))
                                    featureRow(iconName: "photo.on.rectangle", text: NSLocalizedString("相关图片和文献推荐", comment: "Feature: Related images and literature"))
                                    featureRow(iconName: "archivebox", text: NSLocalizedString("对话历史保存和管理", comment: "Feature: Conversation history"))
                                }
                                .padding(.horizontal, 16)
                                
                                Divider()
                                    .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                                    .padding(.horizontal, 16)
                                
                                // Developer info
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(NSLocalizedString("开发者", comment: "Developer section"))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                    
                                    HStack(spacing: 16) {
                                        // Developer profile image
                                        ZStack {
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(hex: "6366F1"),
                                                    Color(hex: "8B5CF6")
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            .clipShape(Circle())
                                            .frame(width: 42, height: 42)
                                            
                                            Text("ZW")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(NSLocalizedString("Zigao Wang", comment: "Developer name"))
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                            
                                            Text(NSLocalizedString("研究员 & 开发者", comment: "Developer role"))
                                                .font(.system(size: 14))
                                                .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(hex: "6B7280"))
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                // Copyright
                                Text(" 2025 Zigao Wang. All rights reserved.")
                                    .font(.system(size: 14))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.5) : Color(hex: "6B7280"))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 8)
                                    .padding(.bottom, 16)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isDarkMode ? Color(hex: "1E1E1E") : .white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: isDarkMode ? "333333" : "EEEEEE"), lineWidth: 1)
                            )
                        }
                        
                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("设置", comment: "Settings"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isShowing = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(isDarkMode ? .white : .black)
                    }
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    // Helper function for creating settings sections
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isDarkMode ? .white.opacity(0.9) : Color(hex: "374151"))
            
            content()
        }
    }
    
    // Helper function for feature rows in about section
    private func featureRow(iconName: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "3B82F6"))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.1))
                )
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isDarkMode ? .white.opacity(0.8) : Color(hex: "4B5563"))
            
            Spacer()
        }
    }
}

// Add a helper extension to check if a string is empty
extension String {
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
}
