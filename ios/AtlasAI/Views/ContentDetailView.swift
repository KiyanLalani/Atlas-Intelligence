import SwiftUI

struct ContentDetailView: View {
    let content: Content
    @EnvironmentObject var searchViewModel: SearchViewModel
    @State private var isBookmarked = false
    @State private var showingBookmarkAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: content.contentTypeIcon)
                            .foregroundColor(Color(hex: "DAA520")) // Golden color
                        
                        Text(content.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            bookmarkContent()
                        }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(Color(hex: "B87333")) // Copper color
                        }
                    }
                    
                    Text(content.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Divider()
                        .background(Color.gray.opacity(0.5))
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        MetadataItem(icon: "graduationcap", label: "Exam Type", value: content.examType)
                        Spacer()
                        MetadataItem(icon: "building.columns", label: "Exam Board", value: content.examBoard)
                    }
                    
                    HStack {
                        MetadataItem(icon: "book", label: "Subject", value: content.subject)
                        Spacer()
                        MetadataItem(icon: "chart.bar", label: "Difficulty", value: content.difficulty.capitalized)
                    }
                    
                    if let year = content.metadata.year {
                        HStack {
                            MetadataItem(icon: "calendar", label: "Year", value: "\(year)")
                            Spacer()
                            if let season = content.metadata.season {
                                MetadataItem(icon: "leaf", label: "Season", value: season)
                            }
                        }
                    }
                    
                    if content.topics.count > 0 {
                        Text("Topics")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 5)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(content.topics, id: \.self) { topic in
                                    TagView(text: topic, color: .purple)
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.5))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 15) {
                    Text("Content")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let text = content.content.text {
                        Text(text)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    if let fileUrl = content.content.fileUrl {
                        Link(destination: URL(string: fileUrl)!) {
                            HStack {
                                Image(systemName: "arrow.down.doc")
                                Text("Download File")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(hex: "B87333")) // Copper color
                            .cornerRadius(10)
                        }
                    }
                    
                    if let videoUrl = content.content.videoUrl {
                        Link(destination: URL(string: videoUrl)!) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Watch Video")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(hex: "B87333")) // Copper color
                            .cornerRadius(10)
                        }
                    }
                    
                    if let questions = content.content.questions, !questions.isEmpty {
                        Text("Practice Questions")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        ForEach(questions, id: \.id) { question in
                            QuestionView(question: question)
                                .padding(.vertical, 5)
                        }
                    }
                }
                
                // Footer
                VStack(alignment: .leading, spacing: 5) {
                    Divider()
                        .background(Color.gray.opacity(0.5))
                    
                    HStack {
                        Text("Created: \(content.formattedDate)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if content.isVerified {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("Verified")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(hex: "222222").edgesIgnoringSafeArea(.all)) // Dark background
        .navigationBarTitle("", displayMode: .inline)
        .alert(isPresented: $showingBookmarkAlert) {
            Alert(
                title: Text("Bookmarked"),
                message: Text("This content has been saved to your bookmarks."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func bookmarkContent() {
        searchViewModel.bookmarkContent(contentId: content.id)
        isBookmarked = true
        showingBookmarkAlert = true
    }
}

struct MetadataItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "DAA520")) // Golden color
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .foregroundColor(.white)
        }
    }
}

struct QuestionView: View {
    let question: Question
    @State private var showAnswer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.question)
                .foregroundColor(.white)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            if let options = question.options {
                ForEach(options.indices, id: \.self) { index in
                    HStack {
                        Text("\(["A", "B", "C", "D"][min(index, 3)]). ")
                            .fontWeight(.bold)
                            .foregroundColor(showAnswer && options[index] == question.correctAnswer ? .green : .white)
                        
                        Text(options[index])
                            .foregroundColor(showAnswer && options[index] == question.correctAnswer ? .green : .white)
                        
                        Spacer()
                        
                        if showAnswer && options[index] == question.correctAnswer {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(5)
                }
            }
            
            Button(action: {
                withAnimation {
                    showAnswer.toggle()
                }
            }) {
                Text(showAnswer ? "Hide Answer" : "Show Answer")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "B87333")) // Copper color
                    .cornerRadius(10)
            }
            
            if showAnswer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Correct Answer: \(question.correctAnswer)")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Explanation:")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(question.explanation)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 5)
    }
}

struct ContentDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleContent = Content(
            id: "1",
            title: "GCSE Mathematics: Quadratic Equations",
            description: "Comprehensive notes on solving quadratic equations for GCSE Mathematics",
            contentType: "notes",
            examBoard: "Edexcel",
            examType: "GCSE",
            subject: "Mathematics",
            topics: ["Quadratic Equations", "Algebra"],
            difficulty: "intermediate",
            tokenCost: 1,
            content: ContentData(
                text: "Quadratic equations are polynomial equations of the second degree, having the general form ax² + bx + c = 0, where a ≠ 0...",
                fileUrl: nil,
                videoUrl: nil,
                questions: [
                    Question(
                        question: "Solve the equation x² - 5x + 6 = 0",
                        options: ["x = 2, x = 3", "x = -2, x = -3", "x = 2, x = -3", "x = -2, x = 3"],
                        correctAnswer: "x = 2, x = 3",
                        explanation: "Using the quadratic formula or factoring, we get (x - 2)(x - 3) = 0, so x = 2 or x = 3."
                    )
                ]
            ),
            metadata: Metadata(
                year: 2023,
                season: "Summer",
                paperNumber: nil,
                duration: nil,
                totalMarks: nil
            ),
            tags: ["Algebra", "Equations"],
            popularity: Popularity(views: 120, downloads: 45, bookmarks: 30),
            createdBy: nil,
            isVerified: true,
            createdAt: "2023-09-15T10:30:00Z",
            updatedAt: "2023-09-15T10:30:00Z"
        )
        
        NavigationView {
            ContentDetailView(content: sampleContent)
                .environmentObject(SearchViewModel())
        }
    }
} 