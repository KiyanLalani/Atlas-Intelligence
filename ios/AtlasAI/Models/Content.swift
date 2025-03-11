import Foundation

struct Content: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let contentType: String
    let examBoard: String
    let examType: String
    let subject: String
    let topics: [String]
    let difficulty: String
    let tokenCost: Int
    let content: ContentData
    let metadata: Metadata
    let tags: [String]
    let popularity: Popularity
    let createdBy: String?
    let isVerified: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case description
        case contentType
        case examBoard
        case examType
        case subject
        case topics
        case difficulty
        case tokenCost
        case content
        case metadata
        case tags
        case popularity
        case createdBy
        case isVerified
        case createdAt
        case updatedAt
    }
    
    var formattedDate: String {
        guard let date = ISO8601DateFormatter().date(from: createdAt) else {
            return "Unknown date"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var contentTypeIcon: String {
        switch contentType {
        case "notes":
            return "doc.text"
        case "pastPaper":
            return "doc.on.doc"
        case "practiceQuestions":
            return "questionmark.circle"
        case "flashcards":
            return "rectangle.stack"
        case "video":
            return "play.rectangle"
        default:
            return "doc"
        }
    }
    
    var difficultyColor: String {
        switch difficulty {
        case "beginner":
            return "green"
        case "intermediate":
            return "orange"
        case "advanced":
            return "red"
        default:
            return "gray"
        }
    }
}

struct ContentData: Codable {
    let text: String?
    let fileUrl: String?
    let videoUrl: String?
    let questions: [Question]?
}

struct Question: Codable, Identifiable {
    var id: String {
        return UUID().uuidString
    }
    
    let question: String
    let options: [String]?
    let correctAnswer: String
    let explanation: String
}

struct Metadata: Codable {
    let year: Int?
    let season: String?
    let paperNumber: String?
    let duration: Int?
    let totalMarks: Int?
}

struct Popularity: Codable {
    let views: Int
    let downloads: Int
    let bookmarks: Int
}

struct SearchResult: Codable {
    let success: Bool
    let message: String?
    let parsedQuery: ParsedQuery?
    let results: [Content]
    let tokensUsed: Int
    let tokensRemaining: Int
}

struct ParsedQuery: Codable {
    let examType: String?
    let examBoard: String?
    let subject: String?
    let topic: String?
    let requestType: String?
} 