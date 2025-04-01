import SwiftUI
import Foundation

struct ProgressStagesView: View {
    var currentStage: ProgressStage?
    var completedStages: Set<ProgressStage> = []
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(ProgressStage.allCases, id: \.self) { stage in
                StageRow(
                    stage: stage,
                    isActive: currentStage == stage,
                    isCompleted: completedStages.contains(stage)
                )
                
                if stage != ProgressStage.allCases.last {
                    // Connecting line between stages
                    ZStack {
                        // Background line
                        Rectangle()
                            .frame(width: 2, height: 24)
                            .foregroundColor(Color.gray.opacity(0.2))
                        
                        // Progress line (colored if the next stage is active or completed)
                        let nextStage = ProgressStage.allCases[ProgressStage.allCases.firstIndex(of: stage)! + 1]
                        let shouldShowProgress = completedStages.contains(stage) || currentStage == stage && completedStages.contains(nextStage)
                        
                        Rectangle()
                            .frame(width: 2, height: 24)
                            .foregroundColor(shouldShowProgress ? Color(hex: "3B82F6") : Color.clear)
                    }
                    .padding(.leading, 40)
                }
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : .white)
                .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct StageRow: View {
    let stage: ProgressStage
    let isActive: Bool
    let isCompleted: Bool
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Stage indicator
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 32, height: 32)
                    .shadow(color: isActive ? Color(hex: "3B82F6").opacity(0.5) : Color.clear, radius: 4, x: 0, y: 0)
                
                if isCompleted {
                    // Checkmark for completed stages
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else if isActive {
                    // Animated progress indicator for active stage
                    ProgressCircle()
                        .frame(width: 20, height: 20)
                } else {
                    // Number for upcoming stages
                    let stageNumber = ProgressStage.allCases.firstIndex(of: stage)! + 1
                    Text("\(stageNumber)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDarkMode ? Color.gray : Color.gray.opacity(0.8))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Stage title
                Text(stage.displayText)
                    .font(.system(size: 15, weight: isActive || isCompleted ? .semibold : .regular))
                    .foregroundColor(textColor)
                
                // Stage description
                Text(stageDescription)
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Stage status indicator
            if isCompleted {
                HStack(spacing: 4) {
                    Text("完成")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.1))
                )
            } else if isActive {
                HStack(spacing: 4) {
                    Text("进行中")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "3B82F6"))
                    
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "3B82F6"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(hex: "3B82F6").opacity(0.1))
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? 
                      (isDarkMode ? Color(hex: "3B82F6").opacity(0.15) : Color(hex: "3B82F6").opacity(0.08)) : 
                      Color.clear)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return Color.green
        } else if isActive {
            return Color(hex: "3B82F6")
        } else {
            return isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F0F0F0")
        }
    }
    
    private var textColor: Color {
        if isActive {
            return Color(hex: "3B82F6")
        } else if isCompleted {
            return isDarkMode ? .white : .primary
        } else {
            return isDarkMode ? Color.gray : Color.gray.opacity(0.8)
        }
    }
    
    private var stageDescription: String {
        switch stage {
        case .evaluation:
            return "分析问题并确定研究方向"
        case .paperRetrieval:
            return "搜索和筛选相关学术论文"
        case .paperAnalysis:
            return "深入分析论文内容和关键发现"
        case .answerGeneration:
            return "综合研究结果生成全面答案"
        }
    }
}

// Animated progress indicator
struct ProgressCircle: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color(hex: "3B82F6").opacity(0.3), lineWidth: 3)
                .frame(width: 24, height: 24)
            
            // Animated progress indicator
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "3B82F6"), Color(hex: "60A5FA")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 24, height: 24)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
        }
    }
}

struct ProgressStagesView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ProgressStagesView(
                currentStage: .paperRetrieval,
                completedStages: [.evaluation]
            )
            .padding()
            
            ProgressStagesView(
                currentStage: .answerGeneration,
                completedStages: [.evaluation, .paperRetrieval, .paperAnalysis]
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
