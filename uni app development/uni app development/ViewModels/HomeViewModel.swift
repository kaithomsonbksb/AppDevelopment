import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var assignedPerks: [Perk] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var balance: Int = 0
    let email: String
    private var cancellables = Set<AnyCancellable>()
    
    init(email: String) {
        self.email = email
        fetchBalance()
    }

    func fetchBalance() {
        guard let url = URL(string: "http://192.168.1.177:5000/balance?email=\(email)") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let bal = json["balance"] as? Int {
                    self.balance = bal
                }
            }
        }.resume()
    }

    func addPerk(_ perk: Perk) {
        guard let url = URL(string: "http://192.168.1.177:5000/add_perk") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email, "perk_id": perk.id]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let newBalance = json["balance"] as? Int {
                        self.balance = newBalance
                    }
                    self.fetchAssignedPerks()
                }
            }
        }.resume()
    }
    
    func fetchAssignedPerks() {
        isLoading = true
        error = nil
        guard let url = URL(string: "http://192.168.1.177:5000/assignments?email=\(email)") else {
            self.error = "Invalid URL"
            self.isLoading = false
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.error = "No data from server"
                    return
                }
                do {
                    let ids = try JSONDecoder().decode([String].self, from: data)
                    print("[DEBUG] Perk IDs from backend: \(ids)")
                    let mapped = ids.compactMap { PerkCatalogue.perk(for: $0) }
                    print("[DEBUG] Mapped perks: \(mapped)")
                    self.assignedPerks = mapped
                } catch {
                    self.error = "Failed to parse perks"
                }
            }
        }.resume()
    }
}
