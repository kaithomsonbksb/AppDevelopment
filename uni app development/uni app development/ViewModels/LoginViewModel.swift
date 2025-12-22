import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var error: String?
    @Published var isLoggedIn: Bool = false
    
    private let testEmail = "test@email.com"
    private let testPassword = "Password123!"
    
    func login() {
        if email == testEmail && password == testPassword {
            isLoggedIn = true
            error = nil
        } else {
            error = "Invalid credentials."
            isLoggedIn = false
        }
    }
}
