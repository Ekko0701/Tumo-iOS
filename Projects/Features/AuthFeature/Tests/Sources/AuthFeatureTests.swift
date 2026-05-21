import ComposableArchitecture
import CoreStorage
import TumoNetwork
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

    func testLoginSuccessSavesAuthToken() async {
        let savedToken = LockIsolated<StoredAuthToken?>(nil)

        let store = TestStore(initialState: LoginFeature.State()) {
            LoginFeature()
        } withDependencies: {
            $0.authClient.login = { email, password in
                XCTAssertEqual(email, "user@tumo.com")
                XCTAssertEqual(password, "password123")

                return AuthToken(
                    accessToken: "access-token",
                    refreshToken: "refresh-token",
                    tokenType: "Bearer"
                )
            }
            $0.tokenStorageClient.save = { token in
                savedToken.setValue(token)
            }
        }

        await store.send(.emailChanged("user@tumo.com")) {
            $0.email = "user@tumo.com"
        }
        await store.send(.passwordChanged("password123")) {
            $0.password = "password123"
        }
        await store.send(.submitButtonTapped) {
            $0.isLoading = true
        }
        await store.receive(.loginSucceeded) {
            $0.isLoading = false
            $0.successMessage = "로그인에 성공했습니다."
        }

        XCTAssertEqual(
            savedToken.value,
            StoredAuthToken(
                accessToken: "access-token",
                refreshToken: "refresh-token",
                tokenType: "Bearer"
            )
        )
    }

    func testAuthServerFieldErrorsAreMappedToFormErrors() {
        let errorResponse = ErrorResponse(
            code: "INVALID_INPUT_VALUE",
            message: "요청 값이 올바르지 않습니다.",
            fieldErrors: [
                ErrorResponse.FieldError(
                    field: "email",
                    message: "이메일 형식이 올바르지 않습니다."
                ),
                ErrorResponse.FieldError(
                    field: "password",
                    message: "비밀번호는 8자 이상 64자 이하여야 합니다."
                ),
                ErrorResponse.FieldError(
                    field: "nickname",
                    message: "닉네임은 50자 이하여야 합니다."
                )
            ]
        )

        let formError = AuthErrorMessageMapper.formError(
            from: NetworkError.server(errorResponse, statusCode: 400)
        )

        XCTAssertNil(formError.message)
        XCTAssertEqual(formError.emailMessage, "이메일 형식이 올바르지 않습니다.")
        XCTAssertEqual(formError.passwordMessage, "비밀번호는 8자 이상 64자 이하여야 합니다.")
        XCTAssertEqual(formError.nicknameMessage, "닉네임은 50자 이하여야 합니다.")
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

    func testSignupSucceededDismissesSignupScreenAndPrefillsLoginEmail() async {
        var initialState = AuthFeature.State()
        initialState.isSignupScreenPresented = true
        initialState.signup.email = "user@tumo.com"
        initialState.signup.password = "password123"
        initialState.signup.nickname = "tumo"

        let store = TestStore(initialState: initialState) {
            AuthFeature()
        }

        await store.send(
            .signup(
                .signupSucceeded(
                    AuthUser(
                        id: 1,
                        email: "user@tumo.com",
                        nickname: "tumo",
                        cashBalance: 10_000_000
                    )
                )
            )
        ) {
            $0.isSignupScreenPresented = false
            $0.signup = SignupFeature.State()
            $0.login.email = "user@tumo.com"
            $0.login.successMessage = "회원가입이 완료되었습니다. 로그인해주세요."
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
