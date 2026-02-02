import Foundation
import Combine

class LoginSystemModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String? = nil

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
                    self.errorMessage = error.localizedDescription
                    self.isLoggedIn = false
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data from server"
                    self.isLoggedIn = false
                    return
                }
                let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                    self.isLoggedIn = true
                    self.errorMessage = nil
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 409 {
                    self.errorMessage = (json?["error"] as? String) ?? "User already exists"
                    self.isLoggedIn = false
                } else {
                    self.errorMessage = (json?["error"] as? String) ?? (json?["message"] as? String) ?? "Signup failed"
                    self.isLoggedIn = false
                }
            }
        }.resume()
    }

    func login() {
        guard let url = URL(string: "http://192.168.1.177:5000/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoggedIn = false
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data from server"
                    self.isLoggedIn = false
                    return
                }
                let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.isLoggedIn = true
                    self.errorMessage = nil
                } else if let httpResponse = response as? HTTPURLResponse {
                    self.errorMessage = (json?["error"] as? String) ?? (json?["message"] as? String) ?? "Login failed"
                    self.isLoggedIn = false
                } else {
                    self.errorMessage = "Server error"
                    self.isLoggedIn = false
                }
            }
        }.resume()
    }
}
