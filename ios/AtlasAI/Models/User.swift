import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let role: String
    let subscription: Subscription
    let tokens: TokenBalance
    let preferences: Preferences
    let createdAt: String?
    let lastActive: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case role
        case subscription
        case tokens
        case preferences
        case createdAt
        case lastActive
    }
}

struct Subscription: Codable {
    let type: String
    let startDate: String
    let endDate: String
    let autoRenew: Bool
    
    var isActive: Bool {
        guard let endDate = ISO8601DateFormatter().date(from: endDate) else {
            return false
        }
        return endDate > Date()
    }
    
    var daysRemaining: Int {
        guard let endDate = ISO8601DateFormatter().date(from: endDate) else {
            return 0
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return components.day ?? 0
    }
    
    var isPremium: Bool {
        return type == "premium"
    }
}

struct TokenBalance: Codable {
    let balance: Int
    let lastRefreshed: String
    
    var formattedLastRefreshed: String {
        guard let date = ISO8601DateFormatter().date(from: lastRefreshed) else {
            return "Unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var nextRefreshDate: String {
        guard let lastRefreshedDate = ISO8601DateFormatter().date(from: lastRefreshed) else {
            return "Unknown"
        }
        let calendar = Calendar.current
        guard let nextRefreshDate = calendar.date(byAdding: .day, value: 7, to: lastRefreshedDate) else {
            return "Unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: nextRefreshDate)
    }
}

struct Preferences: Codable {
    let examBoard: String?
    let examType: String?
    let subjects: [String]?
    let darkMode: Bool
    
    enum CodingKeys: String, CodingKey {
        case examBoard
        case examType
        case subjects
        case darkMode
    }
} 