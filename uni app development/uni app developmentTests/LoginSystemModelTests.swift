import XCTest
@testable import uni_app_development

class MockAPIService: APIServiceProtocol {
    var shouldSucceed = true
    var errorMessage = "Invalid credentials"
    func login(email: String, password: String, completion: @escaping (Result<Void, String>) -> Void) {
        if shouldSucceed {
            completion(.success(()))
        } else {
            completion(.failure(errorMessage))
        }
    }
    func signup(email: String, password: String, completion: @escaping (Result<Void, String>) -> Void) {
        if shouldSucceed {
            completion(.success(()))
        } else {
            completion(.failure(errorMessage))
        }
    }
}

final class LoginSystemModelTests: XCTestCase {
    func testLoginSuccessUpdatesState() {
        let mockAPI = MockAPIService()
        mockAPI.shouldSucceed = true
        let vm = LoginSystemModel(apiService: mockAPI)
        vm.email = "test@example.com"
        vm.password = "password"
        let exp = expectation(description: "Login success")
        vm.login()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(vm.isLoggedIn)
            XCTAssertNil(vm.error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    func testLoginFailureShowsError() {
        let mockAPI = MockAPIService()
        mockAPI.shouldSucceed = false
        mockAPI.errorMessage = "Invalid credentials"
        let vm = LoginSystemModel(apiService: mockAPI)
        vm.email = "test@example.com"
        vm.password = "wrong"
        let exp = expectation(description: "Login failure")
        vm.login()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(vm.isLoggedIn)
            XCTAssertEqual(vm.error, "Invalid credentials")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
