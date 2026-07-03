import ComposableArchitecture
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

    func testLoginSuccess() async {
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
    }

    func testLoginUsecaseSavesAuthTokenAfterLogin() async throws {
        let loginRequest = LockIsolated<LoginRequestDTO?>(nil)
        let savedAuthToken = LockIsolated<AuthToken?>(nil)
        let authToken = AuthToken(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            tokenType: "Bearer"
        )

        let usecase = LoginUsecaseImpl(
            loginRepository: StubLoginRepository(
                loginHandler: { requestDTO in
                    loginRequest.setValue(requestDTO)

                    return authToken
                }
            ),
            authTokenRepository: StubAuthTokenRepository(
                saveHandler: { authToken in
                    savedAuthToken.setValue(authToken)
                }
            )
        )

        let result = try await usecase.execute(
            email: "user@tumo.com",
            password: "password123"
        )

        XCTAssertEqual(
            loginRequest.value,
            LoginRequestDTO(
                email: "user@tumo.com",
                password: "password123"
            )
        )
        XCTAssertEqual(
            savedAuthToken.value,
            AuthToken(
                accessToken: "access-token",
                refreshToken: "refresh-token",
                tokenType: "Bearer"
            )
        )
        XCTAssertEqual(result, authToken)
    }

    func testTokenRefreshUsecaseSavesAuthTokenAfterRefresh() async throws {
        let tokenRefreshRequest = LockIsolated<TokenRefreshRequestDTO?>(nil)
        let savedAuthToken = LockIsolated<AuthToken?>(nil)
        let authToken = AuthToken(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            tokenType: "Bearer"
        )

        let usecase = TokenRefreshUsecaseImpl(
            tokenRefreshRepository: StubTokenRefreshRepository(
                refreshTokenHandler: { requestDTO in
                    tokenRefreshRequest.setValue(requestDTO)

                    return authToken
                }
            ),
            authTokenRepository: StubAuthTokenRepository(
                saveHandler: { authToken in
                    savedAuthToken.setValue(authToken)
                }
            )
        )

        let result = try await usecase.execute(refreshToken: "old-refresh-token")

        XCTAssertEqual(
            tokenRefreshRequest.value,
            TokenRefreshRequestDTO(refreshToken: "old-refresh-token")
        )
        XCTAssertEqual(
            savedAuthToken.value,
            AuthToken(
                accessToken: "new-access-token",
                refreshToken: "new-refresh-token",
                tokenType: "Bearer"
            )
        )
        XCTAssertEqual(result, authToken)
    }

    func testRefreshSessionUsecaseRefreshesStoredAuthToken() async throws {
        let tokenRefreshRequest = LockIsolated<TokenRefreshRequestDTO?>(nil)
        let savedAuthToken = LockIsolated<AuthToken?>(nil)
        let oldAuthToken = AuthToken(
            accessToken: "old-access-token",
            refreshToken: "old-refresh-token",
            tokenType: "Bearer"
        )
        let newAuthToken = AuthToken(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            tokenType: "Bearer"
        )
        let authTokenRepository = StubAuthTokenRepository(
            saveHandler: { authToken in
                savedAuthToken.setValue(authToken)
            },
            loadHandler: {
                oldAuthToken
            }
        )
        let tokenRefreshUsecase = TokenRefreshUsecaseImpl(
            tokenRefreshRepository: StubTokenRefreshRepository(
                refreshTokenHandler: { requestDTO in
                    tokenRefreshRequest.setValue(requestDTO)

                    return newAuthToken
                }
            ),
            authTokenRepository: authTokenRepository
        )
        let refreshSessionUsecase = RefreshSessionUsecaseImpl(
            tokenRefreshUsecase: tokenRefreshUsecase,
            authTokenRepository: authTokenRepository
        )

        let result = try await refreshSessionUsecase.execute()

        XCTAssertEqual(
            tokenRefreshRequest.value,
            TokenRefreshRequestDTO(refreshToken: "old-refresh-token")
        )
        XCTAssertEqual(savedAuthToken.value, newAuthToken)
        XCTAssertEqual(result, newAuthToken)
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

private struct StubLoginRepository: LoginRepository {
    var loginHandler: @Sendable (_ requestDTO: LoginRequestDTO) async throws -> AuthToken

    func login(requestDTO: LoginRequestDTO) async throws -> AuthToken {
        try await loginHandler(requestDTO)
    }
}

private struct StubAuthTokenRepository: AuthTokenRepository {
    var saveHandler: @Sendable (_ authToken: AuthToken) throws -> Void = { _ in }
    var loadHandler: @Sendable () throws -> AuthToken? = { nil }
    var deleteHandler: @Sendable () throws -> Void = {}

    func save(_ authToken: AuthToken) throws {
        try saveHandler(authToken)
    }

    func load() throws -> AuthToken? {
        try loadHandler()
    }

    func delete() throws {
        try deleteHandler()
    }
}

private struct StubTokenRefreshRepository: TokenRefreshRepository {
    var refreshTokenHandler: @Sendable (_ requestDTO: TokenRefreshRequestDTO) async throws -> AuthToken

    func refreshToken(requestDTO: TokenRefreshRequestDTO) async throws -> AuthToken {
        try await refreshTokenHandler(requestDTO)
    }
}

@MainActor
final class AuthUserUsecaseTests: XCTestCase {
    private struct StubFetchMeRepository: FetchMeRepository {
        let user: AuthUser
        func fetchMe() async throws -> AuthUser { user }
    }

    private struct StubLogoutRepository: LogoutRepository {
        let error: Error?
        func logout() async throws { if let error { throw error } }
    }

    private final class SpyAuthTokenRepository: AuthTokenRepository, @unchecked Sendable {
        private(set) var deleteCallCount = 0
        func save(_ authToken: AuthToken) throws {}
        func load() throws -> AuthToken? { nil }
        func delete() throws { deleteCallCount += 1 }
    }

    func test_fetchMe_returnsUser() async throws {
        let user = AuthUser(id: 1, email: "a@b.com", nickname: "테스터", cashBalance: 10_000_000)
        let usecase = FetchMeUsecaseImpl(fetchMeRepository: StubFetchMeRepository(user: user))
        let result = try await usecase.execute()
        XCTAssertEqual(result, user)
    }

    func test_logout_success_deletesToken() async throws {
        let spy = SpyAuthTokenRepository()
        let usecase = LogoutUsecaseImpl(logoutRepository: StubLogoutRepository(error: nil), authTokenRepository: spy)
        try await usecase.execute()
        XCTAssertEqual(spy.deleteCallCount, 1)
    }

    func test_logout_backendFailure_stillDeletesTokenAndRethrows() async {
        struct Boom: Error {}
        let spy = SpyAuthTokenRepository()
        let usecase = LogoutUsecaseImpl(logoutRepository: StubLogoutRepository(error: Boom()), authTokenRepository: spy)
        do {
            try await usecase.execute()
            XCTFail("should rethrow")
        } catch {
            XCTAssertEqual(spy.deleteCallCount, 1)
        }
    }
}
