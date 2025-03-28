import SwiftUI

struct ProgressStagesView: View {
    var currentStage: ProgressStage?
    var completedStages: Set<ProgressStage> = []
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(ProgressStage.allCases, id: \.self) { stage in
                StageRow(
                    stage: stage,
                    isActive: currentStage == stage,
                    isCompleted: completedStages.contains(stage)
                )
                
                if stage != ProgressStage.allCases.last {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2))
                        .padding(.leading, 40)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct StageRow: View {
    let stage: ProgressStage
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            } else if isActive {
                ProgressCircle()
                    .frame(width: 20, height: 20)
            } else {
                Circle()
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
            }
            
            Text(stage.displayText)
                .font(.system(size: 15, weight: isActive ? .semibold : .regular))
                .foregroundColor(textColor)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(isActive ? Color.blue.opacity(0.1) : Color.clear)
    }
    
    private var textColor: Color {
        if isActive {
            return .blue
        } else if isCompleted {
            return .primary
        } else {
            return .gray
        }
    }
}

// Animated progress indicator
struct ProgressCircle: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                .frame(width: 20, height: 20)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 20, height: 20)
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
        ProgressStagesView(
            currentStage: .paperRetrieval,
            completedStages: [.evaluation]
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
