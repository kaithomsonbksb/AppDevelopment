
import Foundation
import Combine

@MainActor
final class LoginSystemModel: ObservableObject {

    // MARK: - Inputs bound to UI
    @Published var userEmail: String = ""
    @Published var password: String = ""

    // MARK: - UI state
    @Published var isLoggedIn: Bool = false
    @Published var isOffline: Bool = false
    @Published var errorMessage: String?

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService()) {
        self.api = api
    }

    // Removed async convenience init; not needed for this context

    func login(completion: @escaping (Bool) -> Void) {
        errorMessage = nil

        api.login(email: userEmail, password: password) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.isLoggedIn = true
                self.isOffline = false
                completion(true)
            case .failure(let error):
                // Only allow offline login if we have cached entitlements for this email
                let cached = EntitlementCache.load(for: self.userEmail)
                if case .network = error, !cached.isEmpty {
                    self.isLoggedIn = true
                    self.isOffline = true
                    self.errorMessage = "Offline mode: logged in with cached data."
                    completion(true)
                } else {
                    self.isLoggedIn = false
                    self.isOffline = false
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }

    func signup(completion: @escaping (Bool) -> Void) {
        errorMessage = nil

        api.signup(email: userEmail, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = error.errorDescription
                    completion(false)
                }
            }
        }
    }

    func logout() {
        isLoggedIn = false
        userEmail = ""
        password = ""
        errorMessage = nil
    }
}
