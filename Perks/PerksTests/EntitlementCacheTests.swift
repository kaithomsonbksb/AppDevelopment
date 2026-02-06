import XCTest
@testable import Perks

final class EntitlementCacheTests: XCTestCase {

    func testSaveThenLoadReturnsSameEntitlements() {
        let email = "test+\(UUID().uuidString)@example.com"
        let expected = ["perk_01", "perk_02", "perk_03"]

        EntitlementCache.save(ids: expected, for: email)
        let loaded = EntitlementCache.load(for: email)

        XCTAssertEqual(loaded, expected)

        // Cleanup
        EntitlementCache.save(ids: [], for: email)
    }

    func testLoadWhenNoCacheReturnsEmptyArray() {
        let email = "nonexistent+\(UUID().uuidString)@example.com"
        let loaded = EntitlementCache.load(for: email)
        XCTAssertEqual(loaded, [])
    }
}
