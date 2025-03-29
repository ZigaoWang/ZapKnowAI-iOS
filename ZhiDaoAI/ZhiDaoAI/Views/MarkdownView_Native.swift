import SwiftUI

/// A native SwiftUI implementation of a markdown renderer optimized for streaming content.
/// This view renders markdown text without using WebKit, providing a smoother experience
/// for displaying streaming content with real-time updates.
struct MarkdownView_Native: View {
    /// The markdown text to display
    var markdown: String
    
    /// Optional callback for handling citation or link taps
    var onLinkTap: ((URL) -> Void)?
    
    /// Extracts citations in the format [^1], [^2], etc. or [Author2022] from the given text.
    /// - Parameter text: The text to parse for citations
    /// - Returns: An array of tuples containing the range of the citation in the original text and the citation key
    private func extractCitations(_ text: String) -> [(Range<String.Index>, String)] {
        var citations: [(Range<String.Index>, String)] = []
        
        // Find all citation matches - pattern like [^1] or [Author2022]
        let pattern = "\\[(\\^\\d+|\\w+\\d{4})\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)
        
        for match in matches {
            // Extract the range and key
            if let citationRange = Range(match.range, in: text),
               let keyRange = Range(match.range(at: 1), in: text) {
                let key = String(text[keyRange])
                citations.append((citationRange, key))
            }
        }
        
        return citations
    }
    
    /// Processes the markdown content and formats it into appropriate SwiftUI views
    /// - Returns: A formatted view representing the markdown content
    @ViewBuilder
    private func formattedContent() -> some View {
        if markdown.isEmpty {
            // Display a space to ensure proper layout even when empty
            Text(" ")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                // Split text by paragraphs for efficient rendering
                let paragraphs = markdown.components(separatedBy: "\n\n").filter { !$0.isEmpty }
                ForEach(paragraphs, id: \.self) { paragraph in
                    if paragraph.hasPrefix("# ") {
                        // Heading 1
                        Text(paragraph.dropFirst(2))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 8)
                    } else if paragraph.hasPrefix("## ") {
                        // Heading 2
                        Text(paragraph.dropFirst(3))
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 6)
                    } else if paragraph.hasPrefix("### ") {
                        // Heading 3
                        Text(paragraph.dropFirst(4))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 4)
                    } else if paragraph.hasPrefix("```") && paragraph.hasSuffix("```") {
                        // Code block
                        Text(paragraph.dropFirst(3).dropLast(3))
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                    } else if paragraph.hasPrefix("- ") {
                        // List
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(paragraph.components(separatedBy: "\n").filter { $0.hasPrefix("- ") }, id: \.self) { item in
                                HStack(alignment: .top) {
                                    Text("•")
                                        .font(.body)
                                    
                                    // Process the list item (without the dash)
                                    formattedText(String(item.dropFirst(2)))
                                }
                            }
                        }
                    } else {
                        // Regular paragraph
                        formattedText(paragraph)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
    
    /// Process individual text blocks with inline formatting (bold, italic, citations)
    /// - Parameter text: The text to format
    /// - Returns: A formatted SwiftUI Text view
    @ViewBuilder
    private func formattedText(_ text: String) -> some View {
        // First extract any citations in the text
        let citations = extractCitations(text)
        
        if citations.isEmpty {
            // If no citations, just apply basic formatting to the whole text
            Text(processInlineFormatting(text))
                .fixedSize(horizontal: false, vertical: true)
        } else {
            // Handle text with citations by splitting it into parts
            let parts = splitTextWithCitations(text, citations: citations)
            buildTextWithParts(parts)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    /// Process text for inline formatting like bold, italic, and code
    /// - Parameter text: The input text to process
    /// - Returns: The processed text with formatting applied
    private func processInlineFormatting(_ text: String) -> String {
        var processedText = text
        
        // Process inline code
        if let regex = try? NSRegularExpression(pattern: "`([^`]+)`", options: []) {
            processedText = regex.stringByReplacingMatches(
                in: processedText,
                options: [],
                range: NSRange(processedText.startIndex..<processedText.endIndex, in: processedText),
                withTemplate: "$1"
            )
        }
        
        // Process bold text
        if let regex = try? NSRegularExpression(pattern: "\\*\\*([^\\*]+)\\*\\*", options: []) {
            processedText = regex.stringByReplacingMatches(
                in: processedText,
                options: [],
                range: NSRange(processedText.startIndex..<processedText.endIndex, in: processedText),
                withTemplate: "$1"
            )
        }
        
        // Process italic text
        if let regex = try? NSRegularExpression(pattern: "\\*([^\\*]+)\\*", options: []) {
            processedText = regex.stringByReplacingMatches(
                in: processedText,
                options: [],
                range: NSRange(processedText.startIndex..<processedText.endIndex, in: processedText),
                withTemplate: "$1"
            )
        }
        
        return processedText
    }
    
    /// Split text into parts at citation boundaries for proper formatting
    /// - Parameters:
    ///   - text: The original text containing citations
    ///   - citations: Array of tuples containing citation ranges and keys
    /// - Returns: Array of tuples with (text, isCitation, citationKey) for each part
    private func splitTextWithCitations(_ text: String, citations: [(Range<String.Index>, String)]) -> [(String, Bool, String?)] {
        var result: [(String, Bool, String?)] = []
        var currentIndex = text.startIndex
        
        // Sort citations by their position in the text to ensure correct order
        for (range, key) in citations.sorted(by: { $0.0.lowerBound < $1.0.lowerBound }) {
            // Add the text before this citation
            if currentIndex < range.lowerBound {
                let beforeText = String(text[currentIndex..<range.lowerBound])
                result.append((beforeText, false, nil))
            }
            
            // Add the citation - we'll only add the key, not the brackets
            result.append((key, true, key))
            
            // Move current index to after this citation
            currentIndex = range.upperBound
        }
        
        // Add any remaining text after the last citation
        if currentIndex < text.endIndex {
            let afterText = String(text[currentIndex..<text.endIndex])
            result.append((afterText, false, nil))
        }
        
        return result
    }
    
    // Build Text view from parts
    /// Builds a single Text view by concatenating all parts with appropriate styling
    /// - Parameter parts: Array of text parts with metadata about citations
    /// - Returns: A single SwiftUI Text view with all parts concatenated
    private func buildTextWithParts(_ parts: [(String, Bool, String?)]) -> some View {
        // Start with an empty Text view
        var result = Text("")
        
        // Combine all parts into a single Text view
        for (text, isCitation, _) in parts {
            if isCitation {
                // For citations, apply superscript styling
                let citationPart = Text(text)
                    .font(.system(size: 10))
                    .baselineOffset(5)
                    .foregroundColor(Color(hex: "3B82F6"))
                
                // Concatenate with existing text
                result = result + citationPart
            } else {
                // For regular text, just add it normally
                let textPart = Text(processInlineFormatting(text))
                result = result + textPart
            }
        }
        
        return result
    }
    
    var body: some View {
        ScrollView {
            formattedContent()
                .padding(.vertical, 4)
        }
        // Use the length as ID to ensure updates when content changes during streaming
        .id("markdown-\(markdown.count)")
        .animation(.easeInOut(duration: 0.1), value: markdown.count)
    }
}

// MARK: - Preview Provider

/// Preview provider for MarkdownView_Native
struct MarkdownView_Native_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard preview
            MarkdownView_Native(markdown: "# Test Heading\n\nThis is some test markdown with **bold** and *italic* text.\n\nAnd a citation [^1] or [Smith2022].\n\n- List item 1\n- List item 2 with [^2] citation")
                .padding()
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Standard Content")
            
            // Empty state preview
            MarkdownView_Native(markdown: "")
                .padding()
                .frame(height: 100)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Empty State")
            
            // Dark mode preview
            MarkdownView_Native(markdown: "# Dark Mode Test\n\nCitations like [Smith2022] and [^1] should be visible in dark mode too.")
                .padding()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
