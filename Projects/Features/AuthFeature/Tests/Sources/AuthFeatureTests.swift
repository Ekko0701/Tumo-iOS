import ComposableArchitecture
import XCTest
@testable import AuthFeature

@MainActor
final class AuthFeatureTests: XCTestCase {
    func testLoginEmailChanged() async {
        let store = TestStore(initialState: LoginFeature.State()) {
            LoginFeature()
        }

        await store.send(.emailChanged("user@tumo.com")) {
            $0.email = "user@tumo.com"
        }
    }

    func testLoginPasswordChanged() async {
        let store = TestStore(initialState: LoginFeature.State()) {
            LoginFeature()
        }

        await store.send(.passwordChanged("password123")) {
            $0.password = "password123"
        }
    }

    func testSignupButtonTappedPresentsSignupScreen() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        }

        await store.send(.login(.signupButtonTapped)) {
            $0.isSignupScreenPresented = true
        }
    }

    func testSignupBackButtonTappedDismissesSignupScreenAndClearsSignupForm() async {
        var initialState = AuthFeature.State()
        initialState.isSignupScreenPresented = true
        initialState.signup.email = "user@tumo.com"
        initialState.signup.password = "password123"
        initialState.signup.nickname = "tumo"
        initialState.signup.errorMessage = "회원가입에 실패했습니다."

        let store = TestStore(initialState: initialState) {
            AuthFeature()
        }

        await store.send(.signupBackButtonTapped) {
            $0.isSignupScreenPresented = false
            $0.signup = SignupFeature.State()
        }
    }

    func testSignupFormChanged() async {
        let store = TestStore(initialState: SignupFeature.State()) {
            SignupFeature()
        }

        await store.send(.emailChanged("user@tumo.com")) {
            $0.email = "user@tumo.com"
        }

        await store.send(.passwordChanged("password123")) {
            $0.password = "password123"
        }

        await store.send(.nicknameChanged("tumo")) {
            $0.nickname = "tumo"
        }
    }

    func testLoginSubmitButtonEnabled() {
        var state = LoginFeature.State()

        XCTAssertFalse(state.isSubmitButtonEnabled)

        state.email = "user@tumo.com"
        state.password = "password123"

        XCTAssertTrue(state.isSubmitButtonEnabled)
    }

    func testSignupSubmitButtonEnabled() {
        var state = SignupFeature.State()

        XCTAssertFalse(state.isSubmitButtonEnabled)

        state.email = "user@tumo.com"
        state.password = "password123"
        state.nickname = "tumo"

        XCTAssertTrue(state.isSubmitButtonEnabled)
    }
}
