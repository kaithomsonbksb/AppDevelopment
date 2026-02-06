import Foundation

final class RealAPIService: APIServiceProtocol {

    // IMPORTANT: change this to match your Flask host/IP
    private let baseURL = "http://192.168.1.151:5000"

    func login(email: String, password: String, completion: @escaping (Result<Void, APIError>) -> Void) {
        post(path: "/login", body: ["email": email, "password": password], completion: completion)
    }

        func fetchAssignments(email: String, completion: @escaping (Result<[String], APIError>) -> Void) {
            guard let url = URL(string: baseURL + "/assignments?email=\(email)") else {
                completion(.failure(.invalidURL))
                return
            }

            let request = URLRequest(url: url)
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(.network(error.localizedDescription)))
                    return
                }
                guard let http = response as? HTTPURLResponse else {
                    completion(.failure(.serverError(message: "No response from server.")))
                    return
                }
                guard let data = data else {
                    completion(.failure(.serverError(message: "No data from server.")))
                    return
                }
                if http.statusCode == 200 {
                    if let ids = try? JSONDecoder().decode([String].self, from: data) {
                        completion(.success(ids))
                        return
                    }
                    completion(.failure(.decodingError))
                    return
                } else {
                    completion(.failure(.unexpectedStatus(http.statusCode)))
                }
            }.resume()
        }

    func signup(email: String, password: String, completion: @escaping (Result<Void, APIError>) -> Void) {
        post(path: "/signup", body: ["email": email, "password": password], completion: completion)
    }

    func editPassword(email: String, newPassword: String, completion: @escaping (Result<Void, APIError>) -> Void) {
        post(path: "/edit", body: ["email": email, "password": newPassword], completion: completion)
    }

    private func post(path: String, body: [String: Any], completion: @escaping (Result<Void, APIError>) -> Void) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.serverError(message: "Failed to encode request")))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.network(error.localizedDescription)))
                return
            }

            let status = (response as? HTTPURLResponse)?.statusCode ?? -1

            if (200...299).contains(status) {
                completion(.success(()))
                return
            }

            // Try to parse {"error": "..."} from Flask
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = (json["error"] as? String) ?? (json["message"] as? String) {
                completion(.failure(.serverError(message: msg)))
            } else {
                completion(.failure(.unexpectedStatus(status)))
            }
        }.resume()
    }
}
