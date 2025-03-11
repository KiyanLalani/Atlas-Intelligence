import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .onAppear {
            authViewModel.checkAuthStatus()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var tokenViewModel: TokenViewModel
    
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            BookmarksView()
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .accentColor(Color(hex: "B87333")) // Copper color
        .onAppear {
            tokenViewModel.fetchTokenStatus()
        }
    }
}

struct AuthView: View {
    @State private var isLogin = true
    
    var body: some View {
        VStack {
            // Logo and app name
            VStack(spacing: 10) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "B87333")) // Copper color
                
                Text("Atlas AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "DAA520")) // Golden color
                
                Text("Your Educational Study Assistant")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 50)
            
            // Login/Register toggle
            Picker("", selection: $isLogin) {
                Text("Login").tag(true)
                Text("Register").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 50)
            .padding(.bottom, 20)
            
            // Auth form
            if isLogin {
                LoginView()
            } else {
                RegisterView()
            }
            
            Spacer()
        }
        .padding()
        .background(Color(hex: "222222").edgesIgnoringSafeArea(.all)) // Dark background
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
            .environmentObject(TokenViewModel())
            .environmentObject(SearchViewModel())
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 