//
//  OnboardingView.swift
//  ZapKnowAI
//
//  Created by Zigao Wang on 4/2/25.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var userSettings: UserSettings
    @State private var currentPage = 0
    @State private var agreedToTerms = false
    @State private var userName = ""
    @State private var cellularAllowed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var onCompleteOnboarding: () -> Void
    
    var body: some View {
        ZStack {
            // Background color
            Color(hex: colorScheme == .dark ? "121212" : "F9F9F9")
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // Welcome Page
                welcomePage
                    .tag(0)
                
                // Terms and Privacy Policy
                termsPage
                    .tag(1)
                
                // User name input
                userNamePage
                    .tag(2)
                
                // Network permissions
                permissionsPage
                    .tag(3)
                
                // Final welcome
                finalPage
                    .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Page indicator
            VStack {
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(0..<5) { page in
                        Circle()
                            .fill(currentPage == page ? 
                                  Color(hex: "3B82F6") : 
                                  Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Pages
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "3B82F6"))
                .padding(.bottom, 16)
            
            Text("欢迎使用知道 AI")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("你的科研伙伴，帮助你探索知识的海洋")
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage = 1
                }
            }) {
                Text("开始")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .padding(24)
    }
    
    private var termsPage: some View {
        VStack(spacing: 20) {
            Text("服务条款和隐私政策")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 40)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("服务条款")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.top, 8)
                        
                        Text("欢迎使用知道 AI 服务。请仔细阅读以下条款和条件，它们规定了您使用我们的应用程序的条款。使用我们的应用程序即表示您同意受这些条款的约束。" +
                             "\n\n1. 服务说明\n知道 AI 是一款研究助手应用，可帮助用户查找和综合科学文献。" +
                             "\n\n2. 用户责任\n用户应负责其查询内容并遵守相关法律法规。" +
                             "\n\n3. 知识产权\n本应用程序的所有内容、设计和功能均受版权和其他知识产权法律保护。")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text("隐私政策")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.top, 16)
                        
                        Text("知道 AI 重视您的隐私。我们的隐私政策解释了我们如何收集、使用和保护您的个人信息。" +
                             "\n\n1. 信息收集\n我们可能会收集您的查询内容以改进服务质量。" +
                             "\n\n2. 信息使用\n我们使用收集的信息来提供、维护和改进我们的服务。" +
                             "\n\n3. 数据安全\n我们实施适当的安全措施来保护您的信息免受未经授权的访问或披露。")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: .infinity)
            
            VStack(spacing: 24) {
                Button(action: {
                    agreedToTerms.toggle()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20))
                            .foregroundColor(agreedToTerms ? Color(hex: "3B82F6") : .gray)
                        
                        Text("我已阅读并同意服务条款和隐私政策")
                            .font(.system(size: 16))
                    }
                    .padding(.vertical, 8)
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            currentPage = 0
                        }
                    }) {
                        Text("上一步")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "3B82F6"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "3B82F6"), lineWidth: 1.5)
                            )
                    }
                    
                    Button(action: {
                        if agreedToTerms {
                            userSettings.hasAgreedToTerms = true
                            withAnimation {
                                currentPage = 2
                            }
                        }
                    }) {
                        Text("下一步")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
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
                    }
                    .disabled(!agreedToTerms)
                    .opacity(agreedToTerms ? 1.0 : 0.5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }
    
    private var userNamePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "3B82F6"))
                .padding(.bottom, 16)
            
            Text("你的名字是？")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("请输入你的名字，我们将在应用中显示它")
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
            
            TextField("输入你的名字", text: $userName)
                .font(.system(size: 18))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                )
                .padding(.horizontal, 24)
                .padding(.top, 16)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        currentPage = 1
                    }
                }) {
                    Text("上一步")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "3B82F6"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "3B82F6"), lineWidth: 1.5)
                        )
                }
                
                Button(action: {
                    if !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        userSettings.userName = userName
                        withAnimation {
                            currentPage = 3
                        }
                    }
                }) {
                    Text("下一步")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
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
                }
                .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }
    
    private var permissionsPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "3B82F6"))
                .padding(.bottom, 16)
            
            Text("网络权限")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("知道 AI 需要网络连接来进行研究和提供答案。您是否允许应用使用移动数据进行连接？")
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
            
            Button(action: {
                cellularAllowed.toggle()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: cellularAllowed ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundColor(cellularAllowed ? Color(hex: "3B82F6") : .gray)
                    
                    Text("允许使用移动数据")
                        .font(.system(size: 16))
                }
                .padding(.vertical, 8)
            }
            .padding(.top, 16)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        currentPage = 2
                    }
                }) {
                    Text("上一步")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "3B82F6"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "3B82F6"), lineWidth: 1.5)
                        )
                }
                
                Button(action: {
                    // Save the preference (could be used later with a network configuration)
                    withAnimation {
                        currentPage = 4
                    }
                }) {
                    Text("下一步")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
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
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }
    
    private var finalPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "3B82F6"))
                .padding(.bottom, 16)
            
            Text("全部完成！")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("感谢你，\(userName)！\n准备好开始你的研究旅程了吗？")
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                userSettings.hasCompletedOnboarding = true
                onCompleteOnboarding()
            }) {
                Text("开始使用")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }
}
