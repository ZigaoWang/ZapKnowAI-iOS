//
//  MarkdownView.swift
//  ZhiDaoAI
//
//  Created by Zigao Wang on 3/27/25.
//

@preconcurrency import SwiftUI
@preconcurrency import WebKit

struct MarkdownView: UIViewRepresentable {
    var markdown: String
    var onLinkTap: ((URL) -> Void)?
    
    // Track content changes to force updates
    private var contentHash: Int {
        return markdown.hashValue
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // Set up a simpler configuration
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        // Add message handler for citations
        contentController.add(context.coordinator, name: "citation")
        config.userContentController = contentController
        
        // Configure preferences for better performance
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        config.preferences = preferences
        
        // Create webview with enhanced config
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.backgroundColor = UIColor.systemBackground
        webView.isOpaque = false
        webView.scrollView.bouncesZoom = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only do a full reload on initial load or major content changes
        // Otherwise use JavaScript to update content without flickering
        let currentHash = contentHash
        
        // Check if this is the first load or if the WebView needs to be reset
        let isInitialLoad = context.coordinator.lastContentHash == 0
        let webViewNeedsReset = context.coordinator.needsReset
        
        if isInitialLoad || webViewNeedsReset {
            // Do a full reload for initial content or after error
            let htmlContent = generateHTML(from: markdown)
            webView.loadHTMLString(htmlContent, baseURL: nil)
            context.coordinator.needsReset = false
            print("MarkdownView: Full reload")
        } else if context.coordinator.lastContentHash != currentHash {
            // For incremental updates, just update the content via JS
            let escapedContent = escapeJavaScript(markdown)
            let updateScript = "updateContent('\(escapedContent)'); true;"
            
            webView.evaluateJavaScript(updateScript) { _, error in 
                if let error = error {
                    print("MarkdownView JS error: \(error)")
                    // Mark for reset on next update if we encounter an error
                    context.coordinator.needsReset = true
                }
            }
            print("MarkdownView: Incremental update")
        }
        
        // Always update the hash to track changes
        context.coordinator.lastContentHash = currentHash
    }
    
    // Helper function to escape content for JavaScript
    private func escapeJavaScript(_ string: String) -> String {
        // Use a simpler approach with a dictionary of replacements
        var escaped = string
        
        // Replace backslashes first
        escaped = escaped.replacingOccurrences(of: "\\", with: "\\\\")
        
        // Replace quotes
        escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
        escaped = escaped.replacingOccurrences(of: "'", with: "\\'")
        
        // Replace newlines
        escaped = escaped.replacingOccurrences(of: "\n", with: "\\n")
        escaped = escaped.replacingOccurrences(of: "\r", with: "\\r")
        
        // Replace script tags (for security)
        escaped = escaped.replacingOccurrences(of: "</script>", with: "</scr" + "ipt>")
        
        return escaped
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MarkdownView
        var lastContentHash: Int = 0
        var needsReset: Bool = false
        
        init(_ parent: MarkdownView) {
            self.parent = parent
            self.lastContentHash = parent.contentHash
        }
        
        // Handle messages from JavaScript
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Handle citation clicks
            if message.name == "citation", let key = message.body as? String {
                print("Citation clicked: \(key)")
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Handle link clicks
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                parent.onLinkTap?(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
    
    private func generateHTML(from markdown: String) -> String {
        // Create a much simpler HTML template with immediate display fallbacks
        let baseHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body {
                    font-family: -apple-system, system-ui, sans-serif;
                    line-height: 1.5;
                    color: #333;
                    padding: 8px;
                    margin: 0;
                    background-color: transparent;
                    font-size: 16px;
                    word-wrap: break-word;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #eee; }
                    a { color: #4af; }
                    code { background-color: rgba(255, 255, 255, 0.1); }
                }
                pre, code {
                    background-color: rgba(0, 0, 0, 0.05);
                    border-radius: 3px;
                    font-family: monospace;
                    padding: 2px 4px;
                }
                pre { padding: 8px; overflow-x: auto; }
                pre code { background: none; padding: 0; }
                blockquote {
                    border-left: 4px solid #ccc;
                    margin-left: 0;
                    padding-left: 16px;
                    color: #666;
                }
                h1, h2, h3, h4 { margin-top: 16px; margin-bottom: 8px; }
                p { margin-bottom: 12px; white-space: pre-wrap; }
                .citation { color: #007AFF; font-weight: bold; cursor: pointer; }
                
                /* Critical: ensure all content is visible, even when streaming */
                #content { white-space: pre-wrap; word-break: break-word; }
                #raw-content { white-space: pre-wrap; word-break: break-word; display: block; }
            </style>
        </head>
        <body>
            <!-- Raw content displayed immediately to guarantee something shows -->
            <pre id="raw-content"></pre>
            
            <!-- Formatted content shown after processing -->
            <div id="content" style="display:none;"></div>
            
            <script>
                // Immediately display raw content
                const markdownText = "%@";
                document.getElementById("raw-content").textContent = markdownText;
                
                // Attempt to format the content
                function displayFormattedContent() {
                    if (!markdownText) return;
                    
                    try {
                        // Simple formatting
                        let html = markdownText
                            // Basic formatting (headers, bold, italic)
                            .replace(/^### (.*$)/gm, '<h3>$1</h3>')
                            .replace(/^## (.*$)/gm, '<h2>$1</h2>')
                            .replace(/^# (.*$)/gm, '<h1>$1</h1>')
                            .replace(/\\*\\*(.*?)\\*\\*/g, '<strong>$1</strong>')
                            .replace(/\\*(.*?)\\*/g, '<em>$1</em>')
                            
                            // Code blocks and inline code
                            .replace(/```([\\s\\S]+?)```/g, '<pre><code>$1</code></pre>')
                            .replace(/`([^`]+)`/g, '<code>$1</code>')
                            
                            // Citation handling
                            .replace(/\\[(\\w+\\d{4})\\]/g, function(match, key) {
                                return '<span class="citation" onclick="handleCitation(\\'' + key + '\\')">'+match+'</span>';
                            })
                            
                            // Links
                            .replace(/\\[([^\\]]+)\\]\\(([^\\)]+)\\)/g, '<a href="$2">$1</a>')
                            
                            // Lists
                            .replace(/^\\s*- (.*$)/gm, '<li>$1</li>')
                            .replace(/(<li>.*<\\/li>)\\s*\\n/g, '$1');
                        
                        // Basic paragraph handling
                        html = html.split(/\\n\\n+/).map(function(para) {
                            if (!para.trim()) return '';
                            if (para.indexOf('<h') === 0) return para;
                            if (para.indexOf('<pre') === 0) return para;
                            if (para.indexOf('<li') === 0) return '<ul>' + para + '</ul>';
                            return '<p>' + para + '</p>';
                        }).join('');
                        
                        // Only switch to formatted view if we have enough content
                        if (html.length > 10) {
                            document.getElementById("content").innerHTML = html;
                            document.getElementById("content").style.display = "block";
                            document.getElementById("raw-content").style.display = "none";
                        }
                    } catch (e) {
                        console.error("Error formatting markdown:", e);
                        // Keep showing the raw content
                    }
                }
                
                // Handle citation clicks
                function handleCitation(key) {
                    try {
                        window.webkit.messageHandlers.citation.postMessage(key);
                    } catch (e) {
                        console.error("Error handling citation:", e);
                    }
                }
                
                // Try to format immediately
                displayFormattedContent();
                
                // Also try when the DOM is loaded
                document.addEventListener("DOMContentLoaded", displayFormattedContent);
            </script>
        </body>
        </html>
        """
        
        // Escape the markdown content for the JavaScript template
        let escaped = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "</script>", with: "<\\/script>")
        
        return baseHTML.replacingOccurrences(of: "%@", with: escaped)
    }
}
