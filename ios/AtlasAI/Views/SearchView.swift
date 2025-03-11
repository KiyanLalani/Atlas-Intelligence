import SwiftUI

struct SearchView: View {
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var tokenViewModel: TokenViewModel
    @State private var showingTokenAlert = false
    @State private var requestType = "basicSearch"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "222222").edgesIgnoringSafeArea(.all) // Dark background
                
                VStack(spacing: 20) {
                    // Token balance indicator
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Color(hex: "DAA520")) // Golden color
                        Text("\(tokenViewModel.tokenBalance) tokens")
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            tokenViewModel.fetchTokenStatus()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Color(hex: "B87333")) // Copper color
                        }
                    }
                    .padding(.horizontal)
                    
                    // Search bar
                    HStack {
                        TextField("Search for study materials...", text: $searchViewModel.searchQuery)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            if tokenViewModel.hasEnoughTokens(for: requestType) {
                                performSearch()
                            } else {
                                showingTokenAlert = true
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "B87333")) // Copper color
                                .cornerRadius(10)
                        }
                        .disabled(searchViewModel.searchQuery.isEmpty || searchViewModel.isLoading)
                        .opacity(searchViewModel.searchQuery.isEmpty || searchViewModel.isLoading ? 0.6 : 1)
                    }
                    .padding(.horizontal)
                    
                    // Request type selector
                    Picker("Request Type", selection: $requestType) {
                        Text("Basic Search").tag("basicSearch")
                        Text("Past Papers").tag("pastPaper")
                        Text("Practice Questions").tag("practiceQuestions")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Token cost indicator
                    HStack {
                        Text("Cost: \(tokenViewModel.getTokenCostString(for: requestType))")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Results or empty state
                    if searchViewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "DAA520")))
                            .scaleEffect(1.5)
                        Spacer()
                    } else if let error = searchViewModel.error {
                        Spacer()
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                                .padding()
                            
                            Text(error)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else if searchViewModel.searchResults.isEmpty {
                        Spacer()
                        VStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(Color(hex: "B87333")) // Copper color
                                .padding()
                            
                            Text("Enter a query to search for study materials")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Text("Example: \"GCSE Maths Edexcel quadratic equations notes\"")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.top, 5)
                        }
                        Spacer()
                    } else {
                        // Search results
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                // Parsed query info
                                if let parsedQuery = searchViewModel.parsedQuery {
                                    ParsedQueryView(parsedQuery: parsedQuery)
                                }
                                
                                // Results
                                ForEach(searchViewModel.searchResults) { content in
                                    NavigationLink(destination: ContentDetailView(content: content)) {
                                        ContentCardView(content: content)
                                    }
                                }
                                
                                // Token usage info
                                HStack {
                                    Text("Used \(searchViewModel.tokensUsed) tokens • \(searchViewModel.tokensRemaining) remaining")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, 10)
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("Atlas AI")
                .alert(isPresented: $showingTokenAlert) {
                    Alert(
                        title: Text("Insufficient Tokens"),
                        message: Text("You need \(tokenViewModel.getTokenCost(for: requestType)) tokens for this search. You currently have \(tokenViewModel.tokenBalance) tokens."),
                        primaryButton: .default(Text("Upgrade to Premium")) {
                            // Navigate to subscription screen
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }
    
    private func performSearch() {
        switch requestType {
        case "practiceQuestions":
            searchViewModel.generatePracticeQuestions()
        default:
            searchViewModel.search()
        }
    }
}

struct ParsedQueryView: View {
    let parsedQuery: ParsedQuery
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("I understood your query as:")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(spacing: 8) {
                if let examType = parsedQuery.examType {
                    TagView(text: examType, color: .blue)
                }
                
                if let examBoard = parsedQuery.examBoard {
                    TagView(text: examBoard, color: .green)
                }
                
                if let subject = parsedQuery.subject {
                    TagView(text: subject, color: .orange)
                }
                
                if let topic = parsedQuery.topic {
                    TagView(text: topic, color: .purple)
                }
                
                if let requestType = parsedQuery.requestType {
                    TagView(text: requestType, color: .red)
                }
            }
            .padding(.top, 2)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(5)
    }
}

struct ContentCardView: View {
    let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: content.contentTypeIcon)
                    .foregroundColor(Color(hex: "DAA520")) // Golden color
                
                Text(content.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(content.examType)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(5)
            }
            
            Text(content.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack {
                Text(content.subject)
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text(content.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .environmentObject(SearchViewModel())
            .environmentObject(TokenViewModel())
    }
} 