import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var assignedPerks: [Perk] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    let email: String
    private var cancellables = Set<AnyCancellable>()
    
    init(email: String) {
        self.email = email
    }
    
    func fetchAssignedPerks() {
        isLoading = true
        error = nil
        guard let url = URL(string: "http://192.168.1.91:5000/assignments?email=\(email)") else {
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
                    self.assignedPerks = ids.compactMap { PerkCatalogue.perk(for: $0) }
                } catch {
                    self.error = "Failed to parse perks"
                }
            }
        }.resume()
    }
}
