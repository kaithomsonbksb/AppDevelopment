import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginSystemModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Coastline Perks")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityIdentifier("title")
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .accessibilityIdentifier("emailField")
                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .accessibilityIdentifier("passwordField")
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .accessibilityIdentifier("errorText")
                }
                Button(action: {
                    viewModel.login()
                }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .accessibilityIdentifier("loginButton")
                NavigationLink(destination: SignupView(viewModel: viewModel)) {
                    Text("Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
                .accessibilityIdentifier("signupLink")
            }
            .padding()
        }
    }
}
