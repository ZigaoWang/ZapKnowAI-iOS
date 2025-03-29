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
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                // Status message
                if !service.statusMessage.isEmpty {
                    statusMessageView(service.statusMessage)
                        .padding(.horizontal, 16)
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
                                completedStages: service.completedStages
                            )
                            .padding(.horizontal, 16)
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
                            .padding(.horizontal, 16)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                        
                        // Answer section
                        if !service.accumulatedTokens.isEmpty || isGeneratingResponse {
                            answerView
                                .padding(.horizontal, 16)
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
        return service.currentStage == .answerGeneration || service.isStreaming
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
            Text("知道 AI")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                .shadow(color: isDarkMode ? Color.black.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)
            
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
                    .padding(10)
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
                    .padding(10)
                    .background(
                        Circle()
                            .fill(isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F3F4F6"))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            
            HStack(spacing: 12) {
                // Search icon with animation
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                    .padding(.leading, 16)
                    .scaleEffect(isSearchFocused ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSearchFocused)
                
                // Text field
                ZStack(alignment: .leading) {
                    // Placeholder
                    if query.isEmpty && !isSearchFocused {
                        Text(placeholderText)
                            .font(.system(size: 16))
                            .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                            .padding(.leading, 2)
                    }
                    
                    TextField("", text: $query)
                        .font(.system(size: 16))
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
                            .font(.system(size: 16))
                            .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "9CA3AF"))
                    }
                    .padding(.trailing, 16)
                    .transition(.opacity)
                    .buttonStyle(ScaleButtonStyle())
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
                    .transition(.scale.combined(with: .opacity))
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .frame(height: searchBarHeight)
    }
    
    // MARK: - Status Message View
    private func statusMessageView(_ status: String) -> some View {
        HStack(spacing: 12) {
            if isTyping {
                // Animated loading indicator
                LoadingDotsView()
                    .frame(width: 40, height: 10)
            } else {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "3B82F6"))
            }
            
            Text(status)
                .font(.system(size: 14))
                .foregroundColor(isDarkMode ? .white : Color(hex: "374151"))
                .lineLimit(2)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Answer View
    private var answerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Answer header
            HStack(spacing: 12) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "3B82F6"))
                
                Text("回答")
                    .font(.system(size: 16, weight: .bold))
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
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F3F4F6"))
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Answer content
            VStack(alignment: .leading, spacing: 0) {
                // Markdown content
                MarkdownView_Native(markdown: service.accumulatedTokens)
                    .padding(16)
                    .environment(\.colorScheme, isDarkMode ? .dark : .light)
                
                // Typing indicator
                if isTyping {
                    HStack {
                        LoadingDotsView()
                            .frame(width: 40, height: 10)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .background(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
            .cornerRadius(16)
            .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
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
        
        withAnimation {
            isSearchFocused = false
            showClearButton = false
            isTyping = true
        }
        
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
