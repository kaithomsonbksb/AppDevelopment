import Foundation
import Combine

class LoginSystemModel: ObservableObject {
        func signup() {
            guard let url = URL(string: "http://192.168.1.177:5000/signup") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: String] = ["email": email, "password": password]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.error = error.localizedDescription
                        self.isLoggedIn = false
                        return
                    }
                    guard let data = data else {
                        self.error = "No data from server"
                        self.isLoggedIn = false
                        return
                    }
                    let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                        self.isLoggedIn = true
                        self.error = nil
                    } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 409 {
                        self.error = (json?["error"] as? String) ?? "User already exists"
                        self.isLoggedIn = false
                    } else {
                        self.error = (json?["error"] as? String) ?? (json?["message"] as? String) ?? "Signup failed"
                        self.isLoggedIn = false
                    }
                }
            }.resume()
        }
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var error: String?
    @Published var isLoggedIn: Bool = false
        func login() {
            guard let url = URL(string: "http://192.168.1.177:5000/login") else { return }

        private let apiService: APIServiceProtocol

        init(apiService: APIServiceProtocol = APIService()) {
            self.apiService = apiService
        }

        func signup() {
            apiService.signup(email: email, password: password) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.isLoggedIn = true
                        self.error = nil
                    case .failure(let error):
                        self.isLoggedIn = false
                        self.error = error
                    }
                }
            }
        }
                    }
