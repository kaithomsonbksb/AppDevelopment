import Foundation

/// Errors returned by the backend API.
enum APIError: LocalizedError, Equatable {
    case invalidURL
    case serverError(message: String)
    case decodingError
    case network(String)
    case unexpectedStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode server response."
        case .network(let message):
            return message
        case .unexpectedStatus(let code):
            return "Unexpected server response (HTTP \(code))."
        }
    }
}

/// Protocol for dependency injection and unit testing.
protocol APIServiceProtocol {
    func login(email: String, password: String, completion: @escaping (Result<Void, APIError>) -> Void)
    func signup(email: String, password: String, completion: @escaping (Result<Void, APIError>) -> Void)
    func editPassword(email: String, newPassword: String, completion: @escaping (Result<Void, APIError>) -> Void)
    func fetchAssignments(email: String, completion: @escaping (Result<[String], APIError>) -> Void)
}

/// Concrete REST API client (JSON over HTTP).
final class APIService: APIServiceProtocol {
        func fetchAssignments(email: String, completion: @escaping (Result<[String], APIError>) -> Void) {
            guard let url = URL(string: "/assignments?email=\(email)", relativeTo: baseURL) else {
                completion(.failure(.invalidURL))
                return
            }
            let request = URLRequest(url: url)
            session.dataTask(with: request) { data, response, error in
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
                    // Try to decode error JSON
                    if let err = try? JSONDecoder().decode(ErrorResponse.self, from: data), let msg = err.error {
                        completion(.failure(.serverError(message: msg)))
                        return
                    }
                    if let msg = try? JSONDecoder().decode(MessageResponse.self, from: data), let text = msg.message {
                        completion(.failure(.serverError(message: text)))
                        return
                    }
                    completion(.failure(.decodingError))
                    return
                } else {
                    completion(.failure(.unexpectedStatus(http.statusCode)))
                }
            }.resume()
        }
    /// Update this if your dev server IP changes.
    /// Tip: consider putting this behind a config setting for submission.
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "http://192.168.1.151:5000")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Public API

    func login(email: String, password: String, completion: @escaping (Result<Void, APIError>) -> Void) {
        post(path: "/login", body: ["email": email, "password": password], completion: completion)
    }

    func signup(email: String, password: String, completion: @escaping (Result<Void, APIError>) -> Void) {
        post(path: "/signup", body: ["email": email, "password": password], completion: completion)
    }

    func editPassword(email: String, newPassword: String, completion: @escaping (Result<Void, APIError>) -> Void) {
        post(path: "/edit", body: ["email": email, "password": newPassword], completion: completion)
    }

    // MARK: - Helpers

struct ErrorResponse: Decodable { let error: String? }
struct MessageResponse: Decodable { let message: String? }

    private func post(path: String, body: [String: Any], completion: @escaping (Result<Void, APIError>) -> Void) {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(.serverError(message: "Failed to build request body.")))
            return
        }

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.network(error.localizedDescription)))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(.serverError(message: "No response from server.")))
                return
            }

            // Success codes your Flask app uses: /login 200, /signup 200
            if (200...299).contains(http.statusCode) {
                completion(.success(()))
                return
            }

            // Try to decode an error message from JSON.
            if let data = data {
                if let err = try? JSONDecoder().decode(ErrorResponse.self, from: data), let msg = err.error {
                    completion(.failure(.serverError(message: msg)))
                    return
                }
                if let msg = try? JSONDecoder().decode(MessageResponse.self, from: data), let text = msg.message {
                    completion(.failure(.serverError(message: text)))
                    return
                }
            }

            completion(.failure(.unexpectedStatus(http.statusCode)))
        }.resume()
    }
}
