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
    @State private var userName = ""
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

                // User name input
                userNamePage
                    .tag(1)

                // Final welcome
                finalPage
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicator
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<3) { page in
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
                    if !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        userSettings.userName = userName
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
                .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
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
