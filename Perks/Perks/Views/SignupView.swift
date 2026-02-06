import SwiftUI

struct SignupView: View {
    @ObservedObject var viewModel: LoginSystemModel
    let onSignup: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
                .accessibilityIdentifier("signupTitle")
            TextField("Email", text: $viewModel.userEmail)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .accessibilityIdentifier("signupEmailField")
            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .accessibilityIdentifier("signupPasswordField")
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .accessibilityIdentifier("signupErrorText")
            }
            Button(action: {
                viewModel.signup { success in
                    if success {
                        onSignup(viewModel.userEmail)
                    }
                }
            }) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .accessibilityIdentifier("signupButton")
        }
        .padding()
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView(viewModel: LoginSystemModel(), onSignup: { _ in })
    }
}
