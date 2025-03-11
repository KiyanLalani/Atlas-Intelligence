import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Content] = []
    @Published var parsedQuery: ParsedQuery?
    @Published var isLoading = false
    @Published var error: String?
    @Published var tokensUsed: Int = 0
    @Published var tokensRemaining: Int = 0
    @Published var questions: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Search Methods
    
    func search(query: String, topics: [String], difficulty: String, format: String) {
        isLoading = true
        error = nil
        
        let url = URL(string: "\(APIConfig.baseURL)/queries/search")!
        var request = APIConfig.configureRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "query": query,
            "topics": topics,
            "difficulty": difficulty,
            "format": format
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: SearchResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    self?.searchResults = response.results
                    self?.parsedQuery = response.parsedQuery
                    self?.tokensUsed = response.tokensUsed
                    self?.tokensRemaining = response.tokensRemaining
                } else {
                    self?.error = response.message ?? "Search failed"
                }
            }
            .store(in: &cancellables)
    }
    
    func generateQuestions(contentId: String) {
        isLoading = true
        error = nil
        
        let url = URL(string: "\(APIConfig.baseURL)/queries/generate-questions")!
        var request = APIConfig.configureRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "contentId": contentId
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: QuestionsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    // Create a Content object with the generated questions
                    let content = Content(
                        id: UUID().uuidString,
                        title: "Generated Practice Questions",
                        description: "Practice questions based on your query: \(self?.searchQuery ?? "")",
                        contentType: "practiceQuestions",
                        examBoard: response.parsedQuery?.examBoard ?? "General",
                        examType: response.parsedQuery?.examType ?? "General",
                        subject: response.parsedQuery?.subject ?? "General",
                        topics: [response.parsedQuery?.topic ?? "General"],
                        difficulty: "intermediate",
                        tokenCost: 3,
                        content: ContentData(
                            text: nil,
                            fileUrl: nil,
                            videoUrl: nil,
                            questions: response.questions
                        ),
                        metadata: Metadata(
                            year: nil,
                            season: nil,
                            paperNumber: nil,
                            duration: nil,
                            totalMarks: nil
                        ),
                        tags: [],
                        popularity: Popularity(views: 0, downloads: 0, bookmarks: 0),
                        createdBy: nil,
                        isVerified: true,
                        createdAt: ISO8601DateFormatter().string(from: Date()),
                        updatedAt: ISO8601DateFormatter().string(from: Date())
                    )
                    
                    self?.searchResults = [content]
                    self?.parsedQuery = response.parsedQuery
                    self?.tokensUsed = response.tokensUsed
                    self?.tokensRemaining = response.tokensRemaining
                } else {
                    self?.error = response.message ?? "Failed to generate questions"
                }
            }
            .store(in: &cancellables)
    }
    
    func toggleBookmark(contentId: String, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "\(APIConfig.baseURL)/content/\(contentId)/bookmark")!
        var request = APIConfig.configureRequest(url: url, method: "POST")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: BookmarkResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                if !response.success {
                    self?.error = response.message ?? "Failed to bookmark content"
                }
                completion(!response.success)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    func clearResults() {
        searchResults = []
        parsedQuery = nil
        tokensUsed = 0
    }
    
    func getOperationTypeFromRequestType(_ requestType: String?) -> String {
        switch requestType {
        case "pastPaper":
            return "pastPaper"
        case "practiceQuestions":
            return "practiceQuestions"
        default:
            return "basicSearch"
        }
    }
    
    // MARK: - Response Models
    
    struct SearchResponse: Codable {
        let success: Bool
        let message: String?
        let parsedQuery: ParsedQuery?
        let results: [Content]
        let tokensUsed: Int
        let tokensRemaining: Int
    }
    
    struct QuestionsResponse: Codable {
        let success: Bool
        let message: String?
        let parsedQuery: ParsedQuery?
        let questions: [Question]
        let tokensUsed: Int
        let tokensRemaining: Int
    }
    
    struct BookmarkResponse: Codable {
        let success: Bool
        let message: String?
    }
} 