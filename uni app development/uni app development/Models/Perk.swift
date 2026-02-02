import Foundation

struct Perk: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let costCredits: Int
}

struct PerkCatalogue {
    static let all: [Perk] = [
        Perk(id: "perk_001", name: "Free Coffee", description: "Enjoy a free coffee every Monday at any campus café.", costCredits: 10),
        Perk(id: "perk_002", name: "10% Bookstore Discount", description: "Get 10% off all purchases at the university bookstore.", costCredits: 15),
        Perk(id: "perk_003", name: "VIP Event Access", description: "Access to exclusive university events and talks.", costCredits: 25),
        Perk(id: "perk_004", name: "Welcome Gift Pack", description: "Receive a special welcome pack with university merchandise.", costCredits: 8),
        Perk(id: "perk_005", name: "E-Book Credit", description: "Redeem a free e-book from the digital library.", costCredits: 12),
        Perk(id: "perk_006", name: "Cinema Ticket", description: "Claim a free cinema ticket for the local theater.", costCredits: 20),
        Perk(id: "perk_007", name: "Travel Discount", description: "Get 20% off on public transport monthly pass.", costCredits: 18),
        Perk(id: "perk_008", name: "Gym Day Pass", description: "Enjoy a one-day pass to the university gym.", costCredits: 10)
    ]
    static func perk(for id: String) -> Perk? {
        all.first { $0.id == id }
    }
}
