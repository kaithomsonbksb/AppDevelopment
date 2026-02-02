import XCTest
@testable import uni_app_development

final class EntitlementCacheTests: XCTestCase {
    func testSaveAndLoadEntitlementIds() {
        let email = "testuser@example.com"
        let ids = ["perk_001", "perk_002", "perk_003"]
        EntitlementCache.save(ids: ids, for: email)
        let loaded = EntitlementCache.load(for: email)
        XCTAssertEqual(loaded, ids)
        EntitlementCache.clear(for: email)
        let cleared = EntitlementCache.load(for: email)
        XCTAssertNil(cleared)
    }
}
