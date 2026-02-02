import Foundation

struct SavedPerk: Identifiable, Codable, Equatable {
    let id: String // perkId
    var note: String
    let savedAt: Date
}

class SavedPerkStore {
    private static let key = "saved_perks"
    static func load() -> [SavedPerk] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([SavedPerk].self, from: data)) ?? []
    }
    static func save(_ perks: [SavedPerk]) {
        if let data = try? JSONEncoder().encode(perks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
