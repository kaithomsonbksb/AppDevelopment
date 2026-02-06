import XCTest
@testable import Perks 

final class LoginSystemModelTests: XCTestCase {

    // MARK: - Mock API

    private final class MockAPIService: APIServiceProtocol {
        var loginResult: Result<Void, APIError> = .success(())
        var signupResult: Result<Void, APIError> = .success(())
        var editResult: Result<Void, APIError> = .success(())
        var assignmentsResult: Result<[String], APIError> = .success([])

        func login(email: String, password: String, completion: @escaping (Result<Void, APIError>) -> Void) {
            completion(loginResult)
        }

        func signup(email: String, password: String, completion: @escaping (Result<Void, APIError>) -> Void) {
            completion(signupResult)
        }

        func editPassword(email: String, newPassword: String, completion: @escaping (Result<Void, APIError>) -> Void) {
            completion(editResult)
        }

        func fetchAssignments(email: String, completion: @escaping (Result<[String], APIError>) -> Void) {
            completion(assignmentsResult)
        }
    }

    // MARK: - Tests

    @MainActor
    func testLoginSuccessSetsLoggedIn() {
        let api = MockAPIService()
        api.loginResult = .success(())

        let model = LoginSystemModel(api: api)
        model.userEmail = "test@example.com"
        model.password = "password123"

        let exp = expectation(description: "Login completes")

        model.login { success in
            XCTAssertTrue(success)
            exp.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(model.isLoggedIn)
        XCTAssertFalse(model.isOffline)
        XCTAssertNil(model.errorMessage)
    }

    @MainActor
    func testLoginFailureShowsErrorAndDoesNotLogIn() {
        let api = MockAPIService()
        api.loginResult = .failure(.serverError(message: "Invalid email or password"))

        let model = LoginSystemModel(api: api)
        model.userEmail = "wrong@example.com"
        model.password = "wrongpass"

        let exp = expectation(description: "Login completes")

        model.login { success in
            XCTAssertFalse(success)
            exp.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(model.isLoggedIn)
        XCTAssertFalse(model.isOffline)
        XCTAssertEqual(model.errorMessage, "Invalid email or password")
    }

    @MainActor
    func testOfflineLoginSucceedsWhenCachedEntitlementsExist() {
        let email = "offline@example.com"

        // Pre-seed cache so offline login is allowed
        EntitlementCache.save(ids: ["perk_1", "perk_2"], for: email)

        let api = MockAPIService()
        api.loginResult = .failure(.network("No internet"))

        let model = LoginSystemModel(api: api)
        model.userEmail = email
        model.password = "doesntmatter"

        let exp = expectation(description: "Offline login completes")

        model.login { success in
            XCTAssertTrue(success)
            exp.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(model.isLoggedIn)
        XCTAssertTrue(model.isOffline)
        XCTAssertNil(model.errorMessage)

        // Cleanup
        EntitlementCache.save(ids: [], for: email)
    }
}
