import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var tokenViewModel: TokenViewModel
    @State private var showingLogoutAlert = false
    @State private var showingSubscriptionView = false
    @State private var showingPreferencesView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "222222").edgesIgnoringSafeArea(.all) // Dark background
                
                ScrollView {
                    VStack(spacing: 25) {
                        // User profile header
                        VStack(spacing: 15) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(Color(hex: "B87333")) // Copper color
                            
                            if let user = authViewModel.user {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        
                        // Subscription card
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(Color(hex: "DAA520")) // Golden color
                                
                                Text("Subscription")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if let user = authViewModel.user, user.subscription.isPremium {
                                    Text("Premium")
                                        .font(.subheadline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(hex: "DAA520").opacity(0.2))
                                        .foregroundColor(Color(hex: "DAA520"))
                                        .cornerRadius(5)
                                } else {
                                    Text("Free")
                                        .font(.subheadline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.gray)
                                        .cornerRadius(5)
                                }
                            }
                            
                            if let user = authViewModel.user {
                                if user.subscription.isPremium {
                                    HStack {
                                        Text("\(user.subscription.daysRemaining) days remaining")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                        Spacer()
                                        
                                        Text(user.subscription.autoRenew ? "Auto-renew on" : "Auto-renew off")
                                            .font(.caption)
                                            .foregroundColor(user.subscription.autoRenew ? .green : .red)
                                    }
                                }
                                
                                Button(action: {
                                    showingSubscriptionView = true
                                }) {
                                    Text(user.subscription.isPremium ? "Manage Subscription" : "Upgrade to Premium")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(hex: "B87333")) // Copper color
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Token balance card
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(Color(hex: "DAA520")) // Golden color
                                
                                Text("Token Balance")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(tokenViewModel.tokenBalance)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.5))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Last Refreshed")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text(tokenViewModel.lastRefreshed)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text("Next Refresh")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text(tokenViewModel.nextRefresh)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Settings options
                        VStack(spacing: 0) {
                            ProfileMenuButton(icon: "gear", title: "Preferences") {
                                showingPreferencesView = true
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.5))
                                .padding(.leading, 50)
                            
                            ProfileMenuButton(icon: "questionmark.circle", title: "Help & Support") {
                                // Open help view
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.5))
                                .padding(.leading, 50)
                            
                            ProfileMenuButton(icon: "arrow.right.square", title: "Logout", textColor: .red) {
                                showingLogoutAlert = true
                            }
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Profile")
                .alert(isPresented: $showingLogoutAlert) {
                    Alert(
                        title: Text("Logout"),
                        message: Text("Are you sure you want to logout?"),
                        primaryButton: .destructive(Text("Logout")) {
                            authViewModel.logout()
                        },
                        secondaryButton: .cancel()
                    )
                }
                .sheet(isPresented: $showingSubscriptionView) {
                    SubscriptionView()
                        .environmentObject(authViewModel)
                }
                .sheet(isPresented: $showingPreferencesView) {
                    PreferencesView()
                        .environmentObject(authViewModel)
                }
            }
        }
        .onAppear {
            tokenViewModel.fetchTokenStatus()
        }
    }
}

struct ProfileMenuButton: View {
    let icon: String
    let title: String
    var textColor: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "DAA520")) // Golden color
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
        }
    }
}

struct SubscriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "222222").edgesIgnoringSafeArea(.all) // Dark background
                
                VStack(spacing: 30) {
                    // Premium plan card
                    VStack(spacing: 20) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "DAA520")) // Golden color
                        
                        Text("Premium Plan")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("£0.99 / month")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Divider()
                            .background(Color.gray.opacity(0.5))
                        
                        VStack(alignment: .leading, spacing: 15) {
                            BenefitRow(icon: "dollarsign.circle", text: "50 tokens per week")
                            BenefitRow(icon: "arrow.clockwise", text: "Weekly token refresh")
                            BenefitRow(icon: "doc.text", text: "Access to all study materials")
                            BenefitRow(icon: "questionmark.circle", text: "Unlimited practice questions")
                        }
                        .padding(.vertical)
                        
                        Button(action: {
                            // Process subscription
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Subscribe Now")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "B87333")) // Copper color
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Free plan comparison
                    VStack(spacing: 15) {
                        Text("Free Plan")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Divider()
                            .background(Color.gray.opacity(0.5))
                        
                        VStack(alignment: .leading, spacing: 15) {
                            BenefitRow(icon: "dollarsign.circle", text: "15 tokens per week")
                            BenefitRow(icon: "arrow.clockwise", text: "Weekly token refresh")
                            BenefitRow(icon: "doc.text", text: "Limited study materials")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(hex: "B87333")) // Copper color
                    }
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "DAA520")) // Golden color
            
            Text(text)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct PreferencesView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var examBoard: String = "Edexcel"
    @State private var examType: String = "GCSE"
    @State private var subjects: [String] = []
    @State private var darkMode: Bool = true
    @State private var isLoading = false
    @State private var showingSaveAlert = false
    
    let examBoards = ["Edexcel", "AQA", "OCR", "WJEC", "Cambridge", "Other"]
    let examTypes = ["GCSE", "IGCSE", "A-level", "Other"]
    let availableSubjects = [
        "Mathematics", "Further Mathematics",
        "Biology", "Chemistry", "Physics", "Combined Science",
        "English Language", "English Literature",
        "History", "Geography", "Religious Studies",
        "Computer Science", "Business Studies", "Economics",
        "French", "German", "Spanish"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "222222").edgesIgnoringSafeArea(.all) // Dark background
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Exam board picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Exam Board")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Picker("Exam Board", selection: $examBoard) {
                                ForEach(examBoards, id: \.self) { board in
                                    Text(board).tag(board)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Exam type picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Exam Type")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Picker("Exam Type", selection: $examType) {
                                ForEach(examTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Subjects selection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Subjects")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(availableSubjects, id: \.self) { subject in
                                        Button(action: {
                                            toggleSubject(subject)
                                        }) {
                                            HStack {
                                                Image(systemName: subjects.contains(subject) ? "checkmark.square.fill" : "square")
                                                    .foregroundColor(subjects.contains(subject) ? Color(hex: "B87333") : .gray)
                                                
                                                Text(subject)
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Dark mode toggle
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Appearance")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Toggle("Dark Mode", isOn: $darkMode)
                                .foregroundColor(.white)
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "B87333")))
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Save button
                        Button(action: {
                            savePreferences()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save Preferences")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "B87333")) // Copper color
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.6 : 1)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(hex: "B87333")) // Copper color
                    }
                }
            }
            .onAppear {
                loadUserPreferences()
            }
            .alert(isPresented: $showingSaveAlert) {
                Alert(
                    title: Text("Preferences Saved"),
                    message: Text("Your preferences have been updated."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func toggleSubject(_ subject: String) {
        if subjects.contains(subject) {
            subjects.removeAll { $0 == subject }
        } else {
            subjects.append(subject)
        }
    }
    
    private func loadUserPreferences() {
        if let user = authViewModel.user {
            if let examBoard = user.preferences.examBoard {
                self.examBoard = examBoard
            }
            
            if let examType = user.preferences.examType {
                self.examType = examType
            }
            
            if let subjects = user.preferences.subjects {
                self.subjects = subjects
            }
            
            self.darkMode = user.preferences.darkMode
        }
    }
    
    private func savePreferences() {
        isLoading = true
        
        // In a real app, this would call an API to update preferences
        // For now, we'll just simulate a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            showingSaveAlert = true
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
            .environmentObject(TokenViewModel())
    }
} 