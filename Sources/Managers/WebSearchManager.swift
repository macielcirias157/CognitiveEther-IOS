import Foundation

enum WebSearchError: LocalizedError {
    case noResults
    case networkError(Error)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No search results found."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError:
            return "Failed to parse search results."
        }
    }
}

struct WebSearchResult {
    let title: String
    let url: String
    let snippet: String
}

final class WebSearchManager {
    static let shared = WebSearchManager()
    
    private let config = ConfigManager.shared
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.httpMaximumConnectionsPerHost = 4
        self.session = URLSession(configuration: configuration)
    }
    
    func isAvailable() -> Bool {
        config.isWebBrowsingEnabled && !config.searxngEndpoint.isEmpty
    }
    
    func search(query: String, maxResults: Int = 5) async throws -> [WebSearchResult] {
        guard isAvailable() else {
            throw WebSearchError.networkError(NSError(domain: "WebSearch", code: -1, userInfo: [NSLocalizedDescriptionKey: "Web search is not configured"]))
        }
        
        let endpoint = config.searxngEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: endpoint) else {
            throw WebSearchError.networkError(NSError(domain: "WebSearch", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint URL"]))
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        components.queryItems = [
            URLQueryItem(name: "q", value: encodedQuery),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "engines", value: "google,bing,duckduckgo"),
            URLQueryItem(name: "results_count", value: "\(maxResults)")
        ]
        
        guard let url = components.url else {
            throw WebSearchError.networkError(NSError(domain: "WebSearch", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not construct URL"]))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("CognitiveEther-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WebSearchError.parsingError
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw WebSearchError.networkError(NSError(domain: "WebSearch", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]))
            }
            
            let searchResponse = try JSONDecoder().decode(SearxngResponse.self, from: data)
            
            let results = searchResponse.results.prefix(maxResults).map { item in
                WebSearchResult(
                    title: item.title ?? "Untitled",
                    url: item.url ?? "",
                    snippet: item.content ?? ""
                )
            }
            
            if results.isEmpty {
                throw WebSearchError.noResults
            }
            
            return results
        } catch let error as WebSearchError {
            throw error
        } catch {
            throw WebSearchError.networkError(error)
        }
    }
    
    func searchAndFormat(query: String) async -> String {
        do {
            let results = try await search(query: query)
            
            var output = "## Web Search Results for: \"\(query)\"\n\n"
            
            for (index, result) in results.enumerated() {
                output += "**\(index + 1). \(result.title)**\n"
                output += "URL: \(result.url)\n"
                output += "\(result.snippet)\n\n"
            }
            
            output += "---\n*Use these results to provide an informed response.*"
            
            return output
        } catch {
            return "Web search failed: \(error.localizedDescription)"
        }
    }
    
    func detectSearchIntent(_ message: String) -> (shouldSearch: Bool, query: String?) {
        let lowercased = message.lowercased()
        
        let searchPatterns = [
            "search for",
            "look up",
            "find",
            "what is",
            "who is",
            "when was",
            "where is",
            "how to",
            "news about",
            "latest",
            "current",
            "recent"
        ]
        
        for pattern in searchPatterns {
            if lowercased.hasPrefix(pattern) {
                let query = message
                    .replacingOccurrences(of: pattern, with: "", options: [.caseInsensitive, .anchored])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "?", with: "")
                
                if !query.isEmpty {
                    return (true, query)
                }
            }
        }
        
        let questionPatterns = ["what", "who", "when", "where", "how", "why"]
        let startsWithQuestion = questionPatterns.contains { lowercased.hasPrefix($0) }
        
        if startsWithQuestion && config.isWebBrowsingEnabled {
            return (true, message.trimmingCharacters(in: .punctuation))
        }
        
        return (false, nil)
    }
}

private struct SearxngResponse: Codable {
    let results: [SearxngResult]
}

private struct SearxngResult: Codable {
    let title: String?
    let url: String?
    let content: String?
}