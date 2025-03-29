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
    @State private var showSearchTips = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isDirectAnswer = false
    
    // Animation states
    @State private var showPlaceholder = true
    @State private var searchBarOffset: CGFloat = 0
    @State private var searchTipsHeight: CGFloat = 0
    
    private let searchBarHeight: CGFloat = 50
    private let placeholderText = "输入您的研究问题..."
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // App header
                appHeader
                
                // Search bar
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                // Search tips
                if showSearchTips {
                    searchTipsView
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Status message
                if !service.statusMessage.isEmpty {
                    statusMessageView(service.statusMessage)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.opacity)
                }
                
                // Decision banner - removed since service.decision doesn't exist
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Progress stages
                        if service.isStreaming || !service.completedStages.isEmpty {
                            ProgressStagesView(
                                currentStage: service.currentStage,
                                completedStages: service.completedStages
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                            .transition(.opacity)
                        }
                        
                        // Papers list
                        if !service.papers.isEmpty || service.isStreaming {
                            PapersListView(
                                papers: service.papers,
                                onPaperTap: { paper in
                                    // Handle paper tap
                                }
                            )
                            .padding(.horizontal, 16)
                            .transition(.opacity)
                        }
                        
                        // Answer section
                        if !service.accumulatedTokens.isEmpty || service.isStreaming {
                            answerView
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                                .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.immediately)
                .animation(.easeInOut(duration: 0.3), value: service.isStreaming)
                .animation(.easeInOut(duration: 0.3), value: service.papers.count)
                .animation(.easeInOut(duration: 0.3), value: service.accumulatedTokens)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showSearchTips = true
                }
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
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(
                colors: isDarkMode ? 
                    [Color(hex: "1A1A1A"), Color(hex: "2A2A2A")] : 
                    [Color(hex: "F5F7FA"), Color(hex: "FFFFFF")]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - App Header
    private var appHeader: some View {
        HStack {
            // App logo and name
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "3B82F6"))
                
                Text("知道")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : .black)
                
                Text("AI")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "3B82F6"))
            }
            
            Spacer()
            
            // Version number
            Text("v1.0")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F0F0F0"))
                )
            
            // Theme toggle
            Button(action: {
                withAnimation {
                    isDarkMode.toggle()
                }
            }) {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isDarkMode ? .yellow : .purple)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F0F0F0"))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            isDarkMode ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF")
        )
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "3B82F6"))
            
            // Text field with animated placeholder
            ZStack(alignment: .leading) {
                if query.isEmpty && showPlaceholder {
                    Text(placeholderText)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.leading, 2)
                        .allowsHitTesting(false)
                }
                
                TextField("", text: $query, onEditingChanged: { editing in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearchFocused = editing
                        showSearchTips = editing
                        showPlaceholder = !editing
                    }
                })
                .foregroundColor(isDarkMode ? .white : .black)
                .disableAutocorrection(true)
                .onSubmit {
                    submitQuery()
                }
            }
            
            // Clear button
            if !query.isEmpty {
                Button(action: {
                    query = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .transition(.opacity)
            }
            
            // Submit button
            Button(action: submitQuery) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "3B82F6"))
            }
            .disabled(query.isEmpty || service.isStreaming)
            .opacity(query.isEmpty || service.isStreaming ? 0.5 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : .white)
                .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSearchFocused ? Color(hex: "3B82F6").opacity(0.5) : Color.clear,
                    lineWidth: 2
                )
        )
    }
    
    // MARK: - Search Tips View
    private var searchTipsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("搜索提示")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isDarkMode ? .white : .black)
            
            VStack(alignment: .leading, spacing: 8) {
                searchTipRow(icon: "text.magnifyingglass", text: "输入具体的研究问题以获得更准确的结果")
                searchTipRow(icon: "quote.bubble", text: "可以使用引号来搜索精确短语，例如 \"量子计算\"")
                searchTipRow(icon: "calendar", text: "添加年份可以限制结果范围，例如 \"机器学习 2023\"")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : .white)
                .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func searchTipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "3B82F6"))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isDarkMode ? .white.opacity(0.9) : .black.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Status Message View
    private func statusMessageView(_ status: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "3B82F6"))
            
            Text(status)
                .font(.system(size: 14))
                .foregroundColor(isDarkMode ? .white.opacity(0.9) : .black.opacity(0.8))
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : .white)
                .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Decision Banner View
    private func decisionBannerView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18))
                .foregroundColor(.yellow)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(isDarkMode ? .white : .black)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isDirectAnswer ? 
                        (isDarkMode ? Color.green.opacity(0.15) : Color.green.opacity(0.1)) : 
                        (isDarkMode ? Color(hex: "3B82F6").opacity(0.15) : Color(hex: "3B82F6").opacity(0.1))
                )
                .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
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
                
                Text("回答")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : .black)
                
                Spacer()
                
                // Copy button
                Button(action: {
                    UIPasteboard.general.string = service.accumulatedTokens
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                        
                        Text("复制")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F0F0F0"))
                    )
                    .foregroundColor(isDarkMode ? .white : .black)
                }
                .opacity(service.accumulatedTokens.isEmpty ? 0 : 1)
                .disabled(service.accumulatedTokens.isEmpty)
            }
            
            // Answer content
            VStack(alignment: .leading, spacing: 0) {
                // Markdown content
                MarkdownView_Native(markdown: service.accumulatedTokens)
                    .padding(16)
                
                // Typing indicator
                if isTyping {
                    HStack {
                        Spacer()
                        FloatingTypingIndicator(isVisible: $isTyping)
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    .transition(.opacity)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDarkMode ? Color(hex: "2A2A2A") : .white)
                    .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Actions
    private func submitQuery() {
        guard !query.isEmpty && !service.isStreaming else { return }
        
        withAnimation {
            showSearchTips = false
            isSearchFocused = false
        }
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        service.streamQuestion(query: query)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
