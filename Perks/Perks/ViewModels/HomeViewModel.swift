import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    func onLoginSuccess(email: String, isOffline: Bool) {
        self.email = email
        assignedPerks = [] // Clear previous perks
        if isOffline {
            loadCachedEntitlements(apiError: nil)
        } else {
            fetchAssignedPerks()
        }
    }
    @Published var assignedPerks: [Perk] = []
    @Published var isLoading: Bool = false
    @Published var isOffline: Bool = false
    @Published var errorMessage: String?
    @Published var email: String
    @Published var credits: Int = 50
    @Published var savedPerks: [SavedPerk] = []
    private var cancellables = Set<AnyCancellable>()
    private let api: APIServiceProtocol

    init(email: String, api: APIServiceProtocol = APIService()) {
        self.email = email
        self.api = api
        // Always populate from cache first
        loadFromCache()
        // Then try to refresh from API (if possible)
        refresh()
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


    // Sync unsynced assignments when online
    
    func refresh() {
        fetchAssignmentsFromAPI()
    }

    func fetchAssignedPerks() {
        isLoading = true
        fetchAssignmentsFromAPIWithLoading()
    }

    private func fetchAssignmentsFromAPIWithLoading() {
        api.fetchAssignments(email: email) { [weak self] (result: Result<[String], APIError>) in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let ids):
                    EntitlementCache.save(ids: ids, for: self.email)
                    self.errorMessage = nil
                    self.isOffline = false
                    self.assignedPerks = ids.compactMap { PerkCatalogue.perk(for: $0) }
                case .failure(let err):
                    self.isOffline = true
                    self.errorMessage = err.localizedDescription
                    self.loadFromCache()
                }
            }
        }
    }

    // Redeem a perk: subtract credits and save locally
    func addPerk(_ perk: Perk) {
        guard credits >= perk.costCredits else {
            errorMessage = "Not enough credits to redeem this perk."
            return
        }
        credits -= perk.costCredits
        createSaved(perkId: perk.id)
        assignedPerks.append(perk)
        let ids = assignedPerks.map { $0.id }
        EntitlementCache.save(ids: ids, for: email)
    }

    private func loadFromCache() {
        let cachedIDs = EntitlementCache.load(for: email)
        assignedPerks = cachedIDs.compactMap { PerkCatalogue.perk(for: $0) }
        if cachedIDs.isEmpty {
            errorMessage = "No cached perks found for offline use."
        }
    }

    private func fetchAssignmentsFromAPI() {
        api.fetchAssignments(email: email) { [weak self] (result: Result<[String], APIError>) in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let ids):
                    EntitlementCache.save(ids: ids, for: self.email)
                    self.errorMessage = nil
                    self.isOffline = false
                    self.assignedPerks = ids.compactMap { PerkCatalogue.perk(for: $0) }
                case .failure(let err):
                    self.isOffline = true
                    self.errorMessage = err.localizedDescription
                    self.loadFromCache()
                }
            }
        }
    }

    private func loadCachedEntitlements(apiError: String?) {
        let ids = EntitlementCache.load(for: email)
        if !ids.isEmpty {
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
