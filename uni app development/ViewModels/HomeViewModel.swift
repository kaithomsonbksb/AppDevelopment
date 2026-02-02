// Store for unsynced perk assignments (offline support)
struct UnsyncedAssignmentsStore {
    private static let key = "unsynced_assignments"
    static func load(for email: String) -> [String] {
        let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: [String]] ?? [:]
        return dict[email] ?? []
    }
    static func save(_ perks: [String], for email: String) {
        var dict = UserDefaults.standard.dictionary(forKey: key) as? [String: [String]] ?? [:]
        dict[email] = perks
        UserDefaults.standard.set(dict, forKey: key)
    }
    static func add(_ perkId: String, for email: String) {
        var current = load(for: email)
        if !current.contains(perkId) {
            current.append(perkId)
            save(current, for: email)
        }
    }
    static func clear(for email: String) {
        var dict = UserDefaults.standard.dictionary(forKey: key) as? [String: [String]] ?? [:]
        dict[email] = []
        UserDefaults.standard.set(dict, forKey: key)
    }
}
import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var assignedPerks: [Perk] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var balance: Int = 0
    @Published var isOffline: Bool = false
    let email: String
    @Published var savedPerks: [SavedPerk] = []
    private var cancellables = Set<AnyCancellable>()

    init(email: String) {
        self.email = email
        fetchBalance()
        fetchAssignedPerks()
        syncUnsyncedAssignments()
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
        guard let url = URL(string: "http://192.168.1.151:5000/balance?email=\(email)") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let bal = json["balance"] as? Int {
                    self.balance = bal
                }
            }
        }.resume()
    }

    func addPerk(_ perk: Perk) {
        guard let url = URL(string: "http://192.168.1.151:5000/add_perk") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email, "perk_id": perk.id]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Offline: save for later sync
                    UnsyncedAssignmentsStore.add(perk.id, for: self.email)
                    self.errorMessage = "Offline: perk will be assigned when back online."
                    self.assignedPerks.append(perk)
                    return
                }
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let newBalance = json["balance"] as? Int {
                        self.balance = newBalance
                    }
                    self.fetchAssignedPerks()
                }
            }
        }.resume()
    }

    // Sync unsynced assignments when online
    func syncUnsyncedAssignments() {
        let unsynced = UnsyncedAssignmentsStore.load(for: email)
        guard !unsynced.isEmpty else { return }
        for perkId in unsynced {
            guard let url = URL(string: "http://192.168.1.151:5000/add_perk") else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = ["email": email, "perk_id": perkId]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if error == nil {
                        // Remove from unsynced if successful
                        var current = UnsyncedAssignmentsStore.load(for: self.email)
                        current.removeAll { $0 == perkId }
                        UnsyncedAssignmentsStore.save(current, for: self.email)
                        self.fetchAssignedPerks()
                    }
                }
            }.resume()
        }
    }
    
    func fetchAssignedPerks() {
        isLoading = true
        errorMessage = nil
        isOffline = false
        guard let url = URL(string: "http://192.168.1.151:5000/assignments?email=\(email)") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    // API failed, try offline cache
                    self.loadCachedEntitlements(apiError: error.localizedDescription)
                    return
                }
                guard let data = data else {
                    // API failed, try offline cache
                    self.loadCachedEntitlements(apiError: "No data from server")
                    return
                }
                // Try to decode as [String], else try to parse error JSON
                if let ids = try? JSONDecoder().decode([String].self, from: data) {
                    EntitlementCache.save(ids: ids, for: self.email)
                    let mapped = ids.compactMap { PerkCatalogue.perk(for: $0) }
                    self.assignedPerks = mapped
                    self.isOffline = false
                    self.errorMessage = nil
                } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let errMsg = (json["error"] as? String) ?? (json["message"] as? String) {
                    // API returned error JSON
                    self.loadCachedEntitlements(apiError: errMsg)
                } else {
                    self.loadCachedEntitlements(apiError: "Failed to parse perks")
                }
            }
        }.resume()
    }

    private func loadCachedEntitlements(apiError: String?) {
        let cachedIds = EntitlementCache.load(for: email)
        if let ids = cachedIds, !ids.isEmpty {
            self.assignedPerks = ids.compactMap { PerkCatalogue.perk(for: $0) }
            self.isOffline = true
            self.errorMessage = apiError != nil ? "Offline mode: " + apiError! : nil
        } else {
            self.assignedPerks = []
            self.isOffline = true
            self.errorMessage = (apiError ?? "") + (apiError != nil ? ". " : "") + "No cached perks available."
        }
    }
}
