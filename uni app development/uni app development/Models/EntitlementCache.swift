import Foundation

struct EntitlementCache {
    private static let keyPrefix = "entitlement_ids_"
    static func save(ids: [String], for email: String) {
        UserDefaults.standard.set(ids, forKey: keyPrefix + email)
    }
    static func load(for email: String) -> [String]? {
        UserDefaults.standard.stringArray(forKey: keyPrefix + email)
    }
    static func clear(for email: String) {
        UserDefaults.standard.removeObject(forKey: keyPrefix + email)
    }
}
