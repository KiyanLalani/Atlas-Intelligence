import Foundation
import Combine

class TokenViewModel: ObservableObject {
    @Published var tokenBalance: Int = 0
    @Published var lastRefreshed: String = ""
    @Published var nextRefresh: String = ""
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Token Methods
    
    func fetchTokenStatus() {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            error = "Not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        let url = URL(string: "\(APIConfig.baseURL)/subscriptions/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(token, forHTTPHeaderField: "x-auth-token")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: TokenStatusResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    self?.tokenBalance = response.tokens.balance
                    
                    // Format dates
                    if let date = ISO8601DateFormatter().date(from: response.tokens.lastRefreshed) {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .none
                        self?.lastRefreshed = formatter.string(from: date)
                        
                        // Calculate next refresh date (7 days after last refresh)
                        let calendar = Calendar.current
                        if let nextRefreshDate = calendar.date(byAdding: .day, value: 7, to: date) {
                            self?.nextRefresh = formatter.string(from: nextRefreshDate)
                        }
                    }
                } else {
                    self?.error = response.message ?? "Failed to fetch token status"
                }
            }
            .store(in: &cancellables)
    }
    
    func getTokenCostString(for operationType: String) -> String {
        switch operationType {
        case "basicSearch":
            return "1 token"
        case "pastPaper":
            return "2 tokens"
        case "practiceQuestions":
            return "3 tokens"
        default:
            return "0 tokens"
        }
    }
    
    func hasEnoughTokens(for operationType: String) -> Bool {
        let cost = getTokenCost(for: operationType)
        return tokenBalance >= cost
    }
    
    func getTokenCost(for operationType: String) -> Int {
        switch operationType {
        case "basicSearch":
            return 1
        case "pastPaper":
            return 2
        case "practiceQuestions":
            return 3
        default:
            return 0
        }
    }
    
    func updateTokenBalance(newBalance: Int) {
        tokenBalance = newBalance
    }
    
    // MARK: - Response Models
    
    struct TokenStatusResponse: Codable {
        let success: Bool
        let message: String?
        let subscription: SubscriptionStatus
        let tokens: TokenStatus
    }
    
    struct SubscriptionStatus: Codable {
        let type: String
        let startDate: String
        let endDate: String
        let autoRenew: Bool
    }
    
    struct TokenStatus: Codable {
        let balance: Int
        let lastRefreshed: String
    }
} 