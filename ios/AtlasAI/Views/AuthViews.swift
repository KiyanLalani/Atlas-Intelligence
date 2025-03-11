import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Email field
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .foregroundColor(.white)
            
            // Password field
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(.white)
            
            // Login button
            Button(action: {
                authViewModel.login(email: email, password: password)
            }) {
                Text("Login")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "B87333")) // Copper color
                    .cornerRadius(10)
            }
            .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
            .opacity(email.isEmpty || password.isEmpty || authViewModel.isLoading ? 0.6 : 1)
            
            // Error message
            if let error = authViewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 10)
            }
            
            // Loading indicator
            if authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "DAA520")))
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal)
    }
}

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordError = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Name field
            TextField("Full Name", text: $name)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .autocapitalization(.words)
                .foregroundColor(.white)
            
            // Email field
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .foregroundColor(.white)
            
            // Password field
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(.white)
                .onChange(of: password) { _ in
                    validatePasswords()
                }
            
            // Confirm password field
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(.white)
                .onChange(of: confirmPassword) { _ in
                    validatePasswords()
                }
            
            // Password error message
            if !passwordError.isEmpty {
                Text(passwordError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Register button
            Button(action: {
                if validatePasswords() {
                    authViewModel.register(name: name, email: email, password: password)
                }
            }) {
                Text("Register")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "B87333")) // Copper color
                    .cornerRadius(10)
            }
            .disabled(name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || !passwordError.isEmpty || authViewModel.isLoading)
            .opacity(name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || !passwordError.isEmpty || authViewModel.isLoading ? 0.6 : 1)
            
            // Error message
            if let error = authViewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 10)
            }
            
            // Loading indicator
            if authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "DAA520")))
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal)
    }
    
    private func validatePasswords() -> Bool {
        if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
            return false
        }
        
        if password != confirmPassword {
            passwordError = "Passwords do not match"
            return false
        }
        
        passwordError = ""
        return true
    }
}

struct AuthViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .environmentObject(AuthViewModel())
                .background(Color(hex: "222222"))
                .previewLayout(.sizeThatFits)
                .padding()
            
            RegisterView()
                .environmentObject(AuthViewModel())
                .background(Color(hex: "222222"))
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
} 