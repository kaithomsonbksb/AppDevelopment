import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var assignedPerks: [Perk] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var balance: Int = 0
    @Published var isOffline: Bool = false
    let email: String
    @Published var savedPerks: [SavedPerk] = []
    private var cancellables = Set<AnyCancellable>()

    init(email: String) {
        self.email = email
        fetchBalance()
        fetchAssignedPerks()
        loadSaved()
    }
    // MARK: - Local CRUD for SavedPerk
    func loadSaved() {
        savedPerks = SavedPerkStore.load()
    }

    func createSaved(perkId: String) {
        guard !savedPerks.contains(where: { $0.id == perkId }) else { return }
        let new = SavedPerk(id: perkId, note: "", savedAt: Date())
        savedPerks.append(new)
        SavedPerkStore.save(savedPerks)
    }

    func updateSaved(perkId: String, note: String) {
        if let idx = savedPerks.firstIndex(where: { $0.id == perkId }) {
            savedPerks[idx].note = note
            SavedPerkStore.save(savedPerks)
        }
    }

    func deleteSaved(perkId: String) {
        savedPerks.removeAll { $0.id == perkId }
        SavedPerkStore.save(savedPerks)
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
        isOffline = false
        guard let url = URL(string: "http://192.168.1.177:5000/assignments?email=\(email)") else {
            self.error = "Invalid URL"
            self.isLoading = false
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    // API failed, try offline cache
                    self.loadCachedEntitlements()
                    return
                }
                guard let data = data else {
                    // API failed, try offline cache
                    self.loadCachedEntitlements()
                    return
                }
                do {
                    let ids = try JSONDecoder().decode([String].self, from: data)
                    print("[DEBUG] Perk IDs from backend: \(ids)")
                    EntitlementCache.save(ids: ids, for: self.email)
                    let mapped = ids.compactMap { PerkCatalogue.perk(for: $0) }
                    print("[DEBUG] Mapped perks: \(mapped)")
                    self.assignedPerks = mapped
                    self.isOffline = false
                } catch {
                    // API failed, try offline cache
                    self.loadCachedEntitlements()
                }
            }
        }.resume()
    }

    private func loadCachedEntitlements() {
        let cachedIds = EntitlementCache.load(for: email)
        if let ids = cachedIds, !ids.isEmpty {
            self.assignedPerks = ids.compactMap { PerkCatalogue.perk(for: $0) }
            self.isOffline = true
            self.error = nil
        } else {
            self.assignedPerks = []
            self.isOffline = true
            self.error = "No cached perks available."
        }
    }
}
