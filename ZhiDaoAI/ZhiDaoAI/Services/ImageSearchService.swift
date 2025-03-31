import Foundation

// Add a struct to hold the search response data
struct SearchResponse {
    let imageUrls: [String]
    let articles: [Article]
}

class ImageSearchService {
    private let baseURL = "http://localhost:3001/api/search"
    
    // Keep the original function for backward compatibility
    func searchImages(query: String, completion: @escaping (Result<[String], Error>) -> Void) {
        searchImagesAndArticles(query: query) { result in
            switch result {
            case .success(let response):
                completion(.success(response.imageUrls))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // New function to fetch both images and articles
    func searchImagesAndArticles(query: String, completion: @escaping (Result<SearchResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Extract image URLs
                    var imageUrls: [String] = []
                    if let images = json["images"] as? [[String: Any]] {
                        imageUrls = images.compactMap { $0["url"] as? String }
                    }
                    
                    // Extract articles
                    var articles: [Article] = []
                    if let results = json["results"] as? [[String: Any]] {
                        articles = results.compactMap { result in
                            guard 
                                let title = result["title"] as? String,
                                let url = result["url"] as? String,
                                let content = result["content"] as? String
                            else {
                                return nil
                            }
                            
                            return Article(title: title, url: url, content: content)
                        }
                    }
                    
                    let response = SearchResponse(imageUrls: imageUrls, articles: articles)
                    completion(.success(response))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
