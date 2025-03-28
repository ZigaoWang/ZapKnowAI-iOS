//
//  ContentView.swift
//  ZhiDaoAI
//
//  Created by Zigao Wang on 3/26/25.
//

import SwiftUI
import SafariServices

// Importing both views to avoid breaking changes during transition
import WebKit

struct ContentView: View {
    @StateObject private var zhiDaoService = ZhiDaoService()
    @State private var question = ""
    @State private var showingPaperDetail: Paper? = nil
    @State private var focusedCitationKey: String? = nil
    @State private var scrollToEnd = false
    @State private var isKeyboardVisible = false
    @State private var lastTokensCount = 0
    @FocusState private var isInputFocused: Bool
    
    private var placeholders = [
        "例如: 量子计算在密码学中的应用是什么?",
        "例如: 深度学习如何改变自然语言处理?",
        "例如: 气候变化对全球粮食安全有什么影响?",
        "例如: 最新的癌症免疫疗法研究进展是什么?",
        "例如: 区块链技术如何应用于供应链管理?"
    ]
    @State private var currentPlaceholder = 0
    
    // Derived values from service state
    private var completedStages: Set<ProgressStage> {
        var completed = Set<ProgressStage>()
        
        // Add stages that should be considered "completed"
        if zhiDaoService.currentStage == .paperRetrieval {
            completed.insert(.evaluation)
        } else if zhiDaoService.currentStage == .paperAnalysis {
            completed.insert(.evaluation)
            completed.insert(.paperRetrieval)
        } else if zhiDaoService.currentStage == .answerGeneration {
            completed.insert(.evaluation)
            completed.insert(.paperRetrieval)
            completed.insert(.paperAnalysis)
        } else if zhiDaoService.isComplete {
            completed.insert(.evaluation)
            completed.insert(.paperRetrieval)
            completed.insert(.paperAnalysis)
            completed.insert(.answerGeneration)
        }
        
        return completed
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // Title
                        HStack {
                            Text("知道引擎 v1.5")
                                .font(.title)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        // Search input
                        HStack {
                            TextField(placeholders[currentPlaceholder], text: $question)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .focused($isInputFocused)
                                .submitLabel(.search)
                                .onSubmit {
                                    if !question.isEmpty {
                                        askQuestion()
                                    }
                                }
                            
                            Button(action: askQuestion) {
                                Text("提问")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(question.isEmpty || zhiDaoService.isStreaming)
                        }
                        
                        // Status message (if any)
                        if !zhiDaoService.statusMessage.isEmpty {
                            HStack {
                                Text(zhiDaoService.statusMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                
                                if zhiDaoService.isStreaming {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        // Progress stages (if streaming)
                        if zhiDaoService.isStreaming || zhiDaoService.isComplete {
                            ProgressStagesView(
                                currentStage: zhiDaoService.currentStage,
                                completedStages: completedStages
                            )
                        }
                        
                        // Decision banner (can answer directly or research needed)
                        if let canAnswer = zhiDaoService.canAnswer {
                            HStack {
                                Image(systemName: canAnswer ? "checkmark.circle.fill" : "magnifyingglass")
                                    .foregroundColor(canAnswer ? .green : .blue)
                                Text(canAnswer ? "这个问题可以直接从我的知识中回答" : "需要研究：正在搜索外部来源获取信息")
                                    .font(.subheadline)
                                    .foregroundColor(canAnswer ? .green : .blue)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(canAnswer ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                            )
                            
                            // Show search term if available
                            if let searchTerm = zhiDaoService.searchTerm {
                                HStack {
                                    Text("搜索关键词：")
                                        .font(.subheadline)
                                    Text(searchTerm)
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        // Papers list
                        if !zhiDaoService.papers.isEmpty {
                            PapersListView(
                                papers: zhiDaoService.papers,
                                onPaperTap: { paper in
                                    showingPaperDetail = paper
                                }
                            )
                        }
                        
                        // Markdown answer content (when tokens are being received)
                        if !zhiDaoService.accumulatedTokens.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("回答")
                                        .font(.headline)
                                    
                                    if zhiDaoService.isStreaming && zhiDaoService.currentStage == .answerGeneration {
                                        // Show a typing indicator when streaming the answer
                                        TypingIndicator()
                                            .frame(width: 40, height: 20)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                MarkdownView_Native(markdown: zhiDaoService.accumulatedTokens)
                                    .frame(minHeight: 200)
                                    .padding(.horizontal, 4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                            }
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .animation(.easeInOut(duration: 0.2), value: zhiDaoService.accumulatedTokens.count)
                            // The ID is critical for forcing refresh with each token update
                            .id("answerContent-\(zhiDaoService.accumulatedTokens.count)")
                        }
                        
                        // Bottom spacer for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottomSpace")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .onChange(of: scrollToEnd) { _, scrollNow in
                    if scrollNow {
                        withAnimation {
                            scrollViewProxy.scrollTo("bottomSpace", anchor: .bottom)
                        }
                        scrollToEnd = false
                    }
                }
                .onChange(of: zhiDaoService.accumulatedTokens) { _, newTokens in
                    // Only trigger a scroll if the number of tokens has changed significantly
                    // This makes the streaming look more natural
                    let newCount = newTokens.count
                    if newCount - lastTokensCount > 10 || newTokens.contains("\n") {
                        lastTokensCount = newCount
                        if !isKeyboardVisible {
                            scrollToEnd = true
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Reset everything
                            zhiDaoService.reset()
                            question = ""
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .onTapGesture {
                // Dismiss keyboard
                isInputFocused = false
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
            .onAppear {
                // Cycle placeholder every 3 seconds
                Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                    withAnimation {
                        currentPlaceholder = (currentPlaceholder + 1) % placeholders.count
                    }
                }
            }
            .sheet(item: $showingPaperDetail) { paper in
                // Improved paper URL handling and added presentationDetents
                SafariView(url: URL(string: paper.link) ?? URL(string: "https://example.com")!)
                    .edgesIgnoringSafeArea(.all)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func askQuestion() {
        // Dismiss keyboard
        isInputFocused = false
        
        // Start streaming
        zhiDaoService.streamQuestion(query: question)
    }
}

// Safari view for displaying papers
// Typing indicator animation to show streaming is in progress
struct TypingIndicator: View {
    @State private var showFirstDot = false
    @State private var showSecondDot = false
    @State private var showThirdDot = false
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .frame(width: 6, height: 6)
                .opacity(showFirstDot ? 1 : 0.3)
            Circle()
                .frame(width: 6, height: 6)
                .opacity(showSecondDot ? 1 : 0.3)
            Circle()
                .frame(width: 6, height: 6)
                .opacity(showThirdDot ? 1 : 0.3)
        }
        .foregroundColor(.blue)
        .onAppear {
            let animation = Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)
            withAnimation(animation) {
                self.showFirstDot = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(animation) {
                    self.showSecondDot = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(animation) {
                    self.showThirdDot = true
                }
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        // Add configuration options to improve stability
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        
        let safariViewController = SFSafariViewController(url: url, configuration: config)
        safariViewController.preferredControlTintColor = UIColor.systemBlue
        safariViewController.dismissButtonStyle = .close
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    ContentView()
}
