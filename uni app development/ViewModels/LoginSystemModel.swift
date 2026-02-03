import Foundation
import Combine

class LoginSystemModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String? = nil

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }

    func signup() {
        print("[DEBUG] signup() called with email: \(email), password: \(password)")
        apiService.signup(email: email, password: password) { result in
            DispatchQueue.main.async {
                print("[DEBUG] signup() completion handler: \(result)")
                switch result {
                case .success:
                    self.isLoggedIn = true
                    self.errorMessage = nil
                case .failure(let error):
                    self.isLoggedIn = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func login() {
        apiService.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.isLoggedIn = true
                    self.errorMessage = nil
                case .failure(let error):
                    self.isLoggedIn = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}