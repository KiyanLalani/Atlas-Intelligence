import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) {
        isLoading = true
        error = nil
        
        let url = URL(string: "\(APIConfig.baseURL)/auth/login")!
        var request = APIConfig.configureRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    self?.user = response.user
                    self?.isAuthenticated = true
                    self?.saveToken(response.token)
                } else {
                    self?.error = response.message ?? "Login failed"
                }
            }
            .store(in: &cancellables)
    }
    
    func register(name: String, email: String, password: String) {
        isLoading = true
        error = nil
        
        let url = URL(string: "\(APIConfig.baseURL)/auth/register")!
        var request = APIConfig.configureRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "name": name,
            "email": email,
            "password": password
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: RegisterResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    self?.user = response.user
                    self?.isAuthenticated = true
                    self?.saveToken(response.token)
                } else {
                    self?.error = response.message ?? "Registration failed"
                }
            }
            .store(in: &cancellables)
    }
    
    func logout() {
        user = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
    func checkAuthStatus() {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            isAuthenticated = false
            return
        }
        
        isLoading = true
        error = nil
        
        let url = URL(string: "\(APIConfig.baseURL)/auth/me")!
        let request = APIConfig.configureRequest(url: url)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: UserResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                    self?.isAuthenticated = false
                    UserDefaults.standard.removeObject(forKey: "authToken")
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    self?.user = response.user
                    self?.isAuthenticated = true
                } else {
                    self?.error = response.message ?? "Authentication failed"
                    self?.isAuthenticated = false
                    UserDefaults.standard.removeObject(forKey: "authToken")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "authToken")
    }
    
    // MARK: - Response Models
    
    struct LoginResponse: Codable {
        let success: Bool
        let message: String?
        let token: String
        let user: User
    }
    
    struct RegisterResponse: Codable {
        let success: Bool
        let message: String?
        let token: String
        let user: User
    }
    
    struct UserResponse: Codable {
        let success: Bool
        let message: String?
        let user: User
    }
}

// Response structures
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let token: String?
    let user: User?
    let preferences: Preferences?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case token
        case user
        case preferences
    }
}

struct UserDataResponse: Codable {
    let user: User
}

struct PreferencesResponse: Codable {
    let preferences: Preferences
}