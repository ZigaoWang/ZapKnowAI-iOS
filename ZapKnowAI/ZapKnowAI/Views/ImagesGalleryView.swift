import SwiftUI
import Foundation

struct ImagesGalleryView: View {
    var images: [ResearchImage]
    @State private var selectedImageID: String? = nil
    @State private var animateImages: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        return colorScheme == .dark
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "3B82F6"))
                
                Text("研究图像")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                
                Spacer()
                
                // Image count badge
                Text("\(images.count)张图片")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "4B5563"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isDarkMode ? Color(hex: "1E293B") : Color(hex: "EFF6FF"))
                    )
            }
            .padding(.horizontal, 20)
            .opacity(animateImages ? 1 : 0)
            
            // Images content
            if images.isEmpty {
                emptyStateView
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Horizontal scroll view for images
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(images) { image in
                                ImageCardView(
                                    image: image,
                                    isSelected: selectedImageID == image.id,
                                    isDarkMode: isDarkMode
                                )
                                .onTapGesture {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if selectedImageID == image.id {
                                            selectedImageID = nil
                                        } else {
                                            selectedImageID = image.id
                                        }
                                    }
                                }
                                .frame(width: 280, height: 220)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                    
                    // Hint text
                    if images.count > 1 {
                        Text("← 滑动查看更多图片")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                            .padding(.leading, 20)
                            .padding(.bottom, 8)
                            .opacity(0.7)
                    }
                    
                    // Selected image details
                    if let selectedID = selectedImageID, let selectedImage = images.first(where: { $0.id == selectedID }) {
                        selectedImageDetailView(selectedImage)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .transition(.opacity)
                    }
                }
                .opacity(animateImages ? 1 : 0)
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.08), 
                        radius: 12, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                animateImages = true
            }
        }
        .onChange(of: images.count) { _, _ in
            // Reset and start animation
            animateImages = false
            withAnimation(.easeIn(duration: 0.3)) {
                animateImages = true
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(NSLocalizedString("正在查找相关图片...", comment: "Loading state for image search"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(isDarkMode ? .white : Color(hex: "4B5563"))
            
            Text(NSLocalizedString("我们正在搜索与您的问题相关的图片", comment: "Loading message for image search"))
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .opacity(animateImages ? 1 : 0)
    }
    
    // Selected image detail view
    private func selectedImageDetailView(_ image: ResearchImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(image.caption)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                .lineLimit(3)
            
            HStack(spacing: 8) {
                // Source information
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 12))
                        .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                    
                    Text(image.source)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // AI generated badge if applicable
                if image.isGenerated {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8B5CF6"))
                        
                        Text(NSLocalizedString("AI 生成", comment: "AI Generated badge"))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "8B5CF6").opacity(0.15))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color(hex: "1F2937") : Color(hex: "F9FAFB"))
        )
    }
}

// Image card view
struct ImageCardView: View {
    var image: ResearchImage
    var isSelected: Bool
    var isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            AsyncImage(url: URL(string: image.url)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: 160)
                        .background(Color(hex: isDarkMode ? "1F2937" : "F3F4F6"))
                case .success(let loadedImage):
                    loadedImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: isDarkMode ? "6B7280" : "9CA3AF"))
                        .frame(maxWidth: .infinity, maxHeight: 160)
                        .background(Color(hex: isDarkMode ? "1F2937" : "F3F4F6"))
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Caption (truncated)
            Text(image.caption)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                .lineLimit(2)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color(hex: "1E293B") : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(hex: "3B82F6") : Color.clear, lineWidth: 2)
        )
        .shadow(color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.1), 
                radius: 4, x: 0, y: 2)
    }
}

// Helper extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Preview
struct ImagesGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ImagesGalleryView(images: [
            ResearchImage(
                id: "1",
                url: "https://example.com/image1.jpg",
                caption: "A diagram showing the architecture of a neural network",
                source: "AI Research Journal",
                isGenerated: false
            ),
            ResearchImage(
                id: "2", 
                url: "https://example.com/image2.jpg",
                caption: "Visual representation of the experiment results",
                source: "Generated by AI",
                isGenerated: true
            )
        ])
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 