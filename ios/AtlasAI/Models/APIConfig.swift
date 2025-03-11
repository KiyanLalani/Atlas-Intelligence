import Foundation

enum Environment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            // For simulator testing, keep localhost
            return "http://localhost:5000/api"
            
            // OPTION 1: For testing on a physical device using your local network
            // return "http://192.168.1.XXX:5000/api"  // Replace with your computer's local IP address
            
            // OPTION 2: For testing with ngrok (temporary public URL for your local server)
            // return "https://your-ngrok-subdomain.ngrok.io/api"  // Replace with your ngrok URL
        case .staging:
            // Update with your actual staging server URL
            return "https://staging.atlasai.com/api"  // Replace with your actual staging server
        case .production:
            // Render deployment URL - update with your actual Render URL
            return "https://atlas-intelligence-api.onrender.com/api"  // Replace with your actual Render URL
        }
    }
}

class APIConfig {
    // Set your active environment here
    static let current: Environment = {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }()
    
    static var baseURL: String {
        return current.baseURL
    }
    
    // Helper to get auth token
    static func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    // Helper to configure a standard request with auth headers
    static func configureRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getAuthToken() {
            request.addValue(token, forHTTPHeaderField: "x-auth-token")
        }
        
        return request
    }
} 