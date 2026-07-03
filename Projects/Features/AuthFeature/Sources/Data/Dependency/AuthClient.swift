import ComposableArchitecture

/// TCA Reducer에서 사용할 인증 API 의존성.
///
/// Reducer는 UseCase나 Repository를 직접 생성하지 않고,
/// `@Dependency(\.authClient)`를 통해 인증 기능을 요청한다.
public struct AuthClient: Sendable {
    public var login: @Sendable (_ email: String, _ password: String) async throws -> AuthToken
    public var signup: @Sendable (_ email: String, _ password: String, _ nickname: String) async throws -> AuthUser
    public var refreshSession: @Sendable () async throws -> AuthToken
    public var fetchMe: @Sendable () async throws -> AuthUser
    public var logout: @Sendable () async throws -> Void

    public init(
        login: @escaping @Sendable (_ email: String, _ password: String) async throws -> AuthToken,
        signup: @escaping @Sendable (_ email: String, _ password: String, _ nickname: String) async throws -> AuthUser,
        refreshSession: @escaping @Sendable () async throws -> AuthToken,
        fetchMe: @escaping @Sendable () async throws -> AuthUser,
        logout: @escaping @Sendable () async throws -> Void
    ) {
        self.login = login
        self.signup = signup
        self.refreshSession = refreshSession
        self.fetchMe = fetchMe
        self.logout = logout
    }
}

extension AuthClient {
    static func live(
        loginUsecase: any LoginUsecase,
        signupUsecase: any SignupUsecase,
        refreshSessionUsecase: any RefreshSessionUsecase,
        fetchMeUsecase: any FetchMeUsecase,
        logoutUsecase: any LogoutUsecase
    ) -> AuthClient {
        AuthClient(
            login: { email, password in
                try await loginUsecase.execute(
                    email: email,
                    password: password
                )
            },
            signup: { email, password, nickname in
                try await signupUsecase.execute(
                    email: email,
                    password: password,
                    nickname: nickname
                )
            },
            refreshSession: {
                try await refreshSessionUsecase.execute()
            },
            fetchMe: {
                try await fetchMeUsecase.execute()
            },
            logout: {
                try await logoutUsecase.execute()
            }
        )
    }
}

private enum AuthClientKey: DependencyKey {
    static let liveValue = AuthAssembly.live()

    static let testValue = AuthClient(
        login: { _, _ in fatalError("unimplemented") },
        signup: { _, _, _ in fatalError("unimplemented") },
        refreshSession: { fatalError("unimplemented") },
        fetchMe: { fatalError("unimplemented") },
        logout: { fatalError("unimplemented") }
    )
}

public extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClientKey.self] }
        set { self[AuthClientKey.self] = newValue }
    }
}
