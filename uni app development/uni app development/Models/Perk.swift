import Foundation

struct Perk: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
}

struct PerkCatalogue {
    static let all: [Perk] = [
        Perk(id: "coffee", name: "Free Coffee", description: "Enjoy a free coffee every Monday!"),
        Perk(id: "discount", name: "10% Discount", description: "Get 10% off on all purchases."),
        Perk(id: "vip", name: "VIP Access", description: "Access to exclusive VIP events."),
        Perk(id: "gift", name: "Welcome Gift", description: "Receive a special welcome gift."),
        // Add more perks as needed
    ]
    static func perk(for id: String) -> Perk? {
        all.first { $0.id == id }
    }
}
