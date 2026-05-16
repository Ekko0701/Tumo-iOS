import ComposableArchitecture
import XCTest
@testable import AuthFeature

@MainActor
final class AuthFeatureTests: XCTestCase {
    func testLoginButtonTapped() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        }

        await store.send(.loginButtonTapped) {
            $0.loginTapCount = 1
        }
    }
}
