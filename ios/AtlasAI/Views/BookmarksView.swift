import SwiftUI

struct BookmarksView: View {
    @State private var bookmarks: [BookmarkItem] = []
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "222222").edgesIgnoringSafeArea(.all) // Dark background
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "DAA520")))
                        .scaleEffect(1.5)
                } else if let error = error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text(error)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            loadBookmarks()
                        }) {
                            Text("Try Again")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "B87333")) // Copper color
                                .cornerRadius(10)
                                .padding(.top, 20)
                        }
                    }
                    .padding()
                } else if bookmarks.isEmpty {
                    VStack {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "B87333")) // Copper color
                            .padding()
                        
                        Text("No Bookmarks Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Save study materials for quick access")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(bookmarks) { bookmark in
                            NavigationLink(destination: ContentDetailView(content: bookmark.content)) {
                                BookmarkRow(bookmark: bookmark)
                            }
                            .listRowBackground(Color.gray.opacity(0.1))
                        }
                        .onDelete(perform: deleteBookmark)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color(hex: "222222"))
                }
            }
            .navigationTitle("Bookmarks")
            .onAppear {
                loadBookmarks()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadBookmarks()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(hex: "B87333")) // Copper color
                    }
                }
            }
        }
    }
    
    private func loadBookmarks() {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            error = "Not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        let url = URL(string: "\(APIConfig.baseURL)/content/bookmarks")!
        let request = APIConfig.configureRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.error = "No data received"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(BookmarksResponse.self, from: data)
                    if response.success {
                        self.bookmarks = response.bookmarks
                    } else {
                        self.error = response.message ?? "Failed to fetch bookmarks"
                    }
                } catch {
                    self.error = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func deleteBookmark(at offsets: IndexSet) {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            error = "Not authenticated"
            return
        }
        
        for index in offsets {
            let bookmark = bookmarks[index]
            let contentId = bookmark.content.id
            
            let url = URL(string: "\(APIConfig.baseURL)/content/\(contentId)/bookmark")!
            var request = APIConfig.configureRequest(url: url, method: "DELETE")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.error = error.localizedDescription
                        return
                    }
                    
                    // Remove from local array regardless of server response
                    self.bookmarks.remove(atOffsets: offsets)
                }
            }.resume()
        }
    }
    
    // MARK: - Response Models
    
    struct BookmarksResponse: Codable {
        let success: Bool
        let message: String?
        let bookmarks: [BookmarkItem]
    }
}

struct BookmarkItem: Codable, Identifiable {
    let savedAt: String
    let content: Content
    
    var id: String {
        return content.id
    }
    
    var formattedSavedDate: String {
        guard let date = ISO8601DateFormatter().date(from: savedAt) else {
            return "Unknown date"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct BookmarkRow: View {
    let bookmark: BookmarkItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: bookmark.content.contentTypeIcon)
                    .foregroundColor(Color(hex: "DAA520")) // Golden color
                
                Text(bookmark.content.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(bookmark.content.examType)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(5)
            }
            
            Text(bookmark.content.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack {
                Text(bookmark.content.subject)
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("Saved: \(bookmark.formattedSavedDate)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct BookmarksView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksView()
    }
} 