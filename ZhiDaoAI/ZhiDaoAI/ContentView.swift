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
                
                // Status message
                if !service.statusMessage.isEmpty {
                    statusMessageView(service.statusMessage)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.opacity)
                }
                
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
                        
                        // Papers list - only show when in paper retrieval or analysis stage
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
                        
                        // Answer section
                        if !service.accumulatedTokens.isEmpty || isGeneratingResponse {
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
        return service.currentStage == .answerGeneration || service.isStreaming
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(
                colors: [
                    Color(hex: "F9FAFB"),
                    Color(hex: "F3F4F6")
                ]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - App Header
    private var appHeader: some View {
        HStack {
            Text("知道 AI")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "111827"))
            
            Spacer()
            
            // Info button
            Button(action: {
                if let url = URL(string: "https://github.com/zigaowang") {
                    UIApplication.shared.open(url)
                }
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "111827"))
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color(hex: "F3F4F6"))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            HStack(spacing: 12) {
                // Search icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "9CA3AF"))
                    .padding(.leading, 16)
                
                // Text field
                ZStack(alignment: .leading) {
                    // Placeholder
                    if query.isEmpty && !isSearchFocused {
                        Text(placeholderText)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "9CA3AF"))
                            .padding(.leading, 2)
                    }
                    
                    TextField("", text: $query)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "374151"))
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
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "9CA3AF"))
                    }
                    .padding(.trailing, 16)
                    .transition(.opacity)
                }
                
                // Search button
                if !query.isEmpty {
                    Button(action: {
                        startSearch()
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                    .padding(.trailing, 16)
                    .transition(.opacity)
                }
            }
        }
        .frame(height: searchBarHeight)
    }
    
    // MARK: - Status Message View
    private func statusMessageView(_ status: String) -> some View {
        HStack(spacing: 12) {
            if isTyping {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "3B82F6"))
            }
            
            Text(status)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "374151"))
                .lineLimit(2)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Answer View
    private var answerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Answer header
            HStack(spacing: 12) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "3B82F6"))
                
                Text("回答")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "111827"))
                
                Spacer()
                
                // Show generating status when generating answer
                if isGeneratingResponse && service.accumulatedTokens.isEmpty {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                // Copy button
                if !service.accumulatedTokens.isEmpty {
                    Button(action: {
                        UIPasteboard.general.string = service.accumulatedTokens
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "111827"))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // Answer content
            VStack(alignment: .leading, spacing: 0) {
                // Markdown content
                MarkdownView_Native(markdown: service.accumulatedTokens)
                    .padding(12)
                
                // Typing indicator
                if isTyping {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Actions
    private func startSearch() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        withAnimation {
            isSearchFocused = false
            showClearButton = false
            isTyping = true
        }
        
        service.streamQuestion(query: query)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
