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
                            }
                        }
                    
                    // Drawer content with fixed animation
                    HStack(spacing: 0) {
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 0) {
                                // Header area with improved design
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("知道 AI")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                    
                                    Text("你的研究伙伴")
                                        .font(.system(size: 16, design: .rounded))
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
                                        
                                        Text("新对话")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
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
                                    
                                    Text("搜索对话")
                                        .font(.system(size: 15, design: .rounded))
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
                                Text("今天")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color(hex: "6B7280"))
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
                                        
                                        Text("暂无历史对话")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(isDarkMode ? Color.white.opacity(0.8) : Color(hex: "6B7280"))
                                            .multilineTextAlignment(.center)
                                        
                                        Text("开始一个新对话来探索知识")
                                            .font(.system(size: 14, design: .rounded))
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
                                                            .font(.system(size: 14, weight: selectedConversationId == conversation.id ? .semibold : .medium, design: .rounded))
                                                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                                            .lineLimit(1)
                                                        
                                                        Text(dateFormatter.string(from: conversation.timestamp))
                                                            .font(.system(size: 12, design: .rounded))
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
                                    
                                    // User name and role
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Zigao Wang")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                                        
                                        Text("研究员")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundColor(isDarkMode ? .white.opacity(0.5) : Color(hex: "6B7280"))
                                    }
                                    
                                    Spacer()
                                    
                                    // Settings
                                    Button(action: {
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
    
    // Enhanced welcome screen for empty state with better UI/UX
    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero section with animated gradient background
                ZStack {
                    // Animated gradient background
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "3B82F6"),
                                    Color(hex: "6366F1"),
                                    Color(hex: "8B5CF6")
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
                    
                    VStack(spacing: 24) {
                        // App logo with glow effect
                        Group {
                            if let _ = UIImage(named: "AppLogo") {
                                Image("AppLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(24)
                                    .shadow(color: Color(hex: "3B82F6").opacity(0.5), radius: 20, x: 0, y: 0)
                            } else {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .frame(width: 100, height: 100)
                                    .background(
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: "3B82F6"))
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        }
                                    )
                                    .shadow(color: Color(hex: "3B82F6").opacity(0.5), radius: 20, x: 0, y: 0)
                            }
                        }
                        .padding(.top, 40)
                        
                        Text("知道 AI")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("你的智能研究助手")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.bottom, 20)
                        
                        // Quick start button
                        Button {
                            query = "Tell me about the latest research in AI"
                            submitQuery()
                        } label: {
                            HStack {
                                Text("快速开始")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.25))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.bottom, 40)
                    }
                    .padding(20)
                }
                .frame(height: 380)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Example questions section
                VStack(alignment: .leading, spacing: 20) {
                    Text("试试以下问题")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                    
                    // Example questions with enhanced styling
                    ForEach(exampleQuestions, id: \.self) { question in
                        Button {
                            query = question
                            submitQuery()
                        } label: {
                            HStack(spacing: 16) {
                                // Category icon
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "3B82F6").opacity(0.1))
                                        .frame(width: 42, height: 42)
                                    
                                    Image(systemName: categoryIcon(for: question))
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "3B82F6"))
                                }
                                
                                Text(question)
                                    .font(.system(size: 16, design: .rounded))
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(isDarkMode ? .white : Color(hex: "374151"))
                                    .lineLimit(2)
                                
                                Spacer()
                                
                                Circle()
                                    .fill(Color(hex: "3B82F6"))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                                    .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // Features section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("主要功能")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            .padding(.top, 40)
                        
                        featureRow(
                            icon: "magnifyingglass",
                            title: "智能搜索",
                            description: "基于最新研究论文快速获取高质量回答"
                        )
                        
                        featureRow(
                            icon: "doc.text.magnifyingglass",
                            title: "论文分析",
                            description: "综合分析多篇相关学术论文提供全面视角"
                        )
                        
                        featureRow(
                            icon: "chart.bar.xaxis",
                            title: "可视化数据",
                            description: "展示研究数据图表及相关图片资料"
                        )
                        
                        featureRow(
                            icon: "bookmark.fill",
                            title: "保存对话",
                            description: "保存重要对话以便日后参考和分享"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                }
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
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Text(description)
                    .font(.system(size: 14, design: .rounded))
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
    
    // Update query input bar to match the new design
    private var queryInputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
            
            HStack(alignment: .center, spacing: 10) {
                // Text field with improved styling
                TextField(placeholderText, text: $query)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(isDarkMode ? Color(hex: "1E1E1E") : Color.white)
                            .shadow(color: isDarkMode ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                    )
                    .onTapGesture {
                        isSearchFocused = true
                    }
                
                // Submit button with improved styling
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
            .background(Color(hex: isDarkMode ? "121212" : "F9F9F9"))
        }
    }
    
    // Enhanced chat results view with modern design
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
                
                // Papers list with improved spacing and shadows
                if (!service.papers.isEmpty && isPaperRelevantStage) || 
                   (service.isStreaming && isPaperSearching) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "3B82F6"))
                                
                            Text("相关论文")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                        }
                        .padding(.horizontal, 16)
                        
                        PapersListView(
                            papers: service.papers,
                            onPaperTap: { paper in
                                // Handle paper tap
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .transition(.opacity)
                }
                
                // Image results with visual enhancements
                if !imageUrls.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "3B82F6"))
                                
                            Text("相关图片")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
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
                
                // Articles section with card enhancements
                if !articles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "book.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "3B82F6"))
                                
                            Text("延伸阅读")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                        }
                        .padding(.horizontal, 16)
                        
                        ForEach(articles) { article in
                            ArticleCardView(article: article, isDarkMode: isDarkMode)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Answer section with improved visuals
                if !service.accumulatedTokens.isEmpty || isGeneratingResponse {
                    answerView
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.opacity)
                }
                
                Spacer().frame(height: 80) // Bottom padding for input field
            }
            .animation(.easeInOut(duration: 0.3), value: service.isStreaming)
            .animation(.easeInOut(duration: 0.3), value: service.papers.count)
            .animation(.easeInOut(duration: 0.3), value: service.accumulatedTokens)
            .animation(.easeInOut(duration: 0.3), value: imageUrls.count)
            .animation(.easeInOut(duration: 0.3), value: articles.count)
        }
        .scrollDismissesKeyboard(.immediately)
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
                .font(.system(size: 15, design: .rounded))
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
                
                Text("研究回答")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
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
                                .font(.system(size: 14, weight: .medium, design: .rounded))
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

