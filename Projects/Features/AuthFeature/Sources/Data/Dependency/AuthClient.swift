import ComposableArchitecture
import CoreNetwork

/// TCA Reducer에서 사용할 인증 API 의존성.
///
/// Reducer는 UseCase나 Repository를 직접 생성하지 않고,
/// `@Dependency(\.authClient)`를 통해 인증 기능을 요청한다.
struct AuthClient: Sendable {
    var login: @Sendable (_ email: String, _ password: String) async throws -> AuthToken
    var signup: @Sendable (_ email: String, _ password: String, _ nickname: String) async throws -> AuthUser
}

extension AuthClient {
    static func live(
        loginUsecase: any LoginUsecase,
        signupUsecase: any SignupUsecase
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
            }
        )
    }
}

private enum AuthClientKey: DependencyKey {
    static let liveValue: AuthClient = {
        let provider = Provider<AuthAPI>()

        let loginDataSource = LoginDataSourceImpl(provider: provider)
        let signupDataSource = SignupDataSourceImpl(provider: provider)

        let loginRepository = LoginRepositoryImpl(loginDataSource: loginDataSource)
        let signupRepository = SignupRepositoryImpl(signupDataSource: signupDataSource)

        let loginUsecase = LoginUsecaseImpl(loginRepository: loginRepository)
        let signupUsecase = SignupUsecaseImpl(signupRepository: signupRepository)

        return AuthClient.live(
            loginUsecase: loginUsecase,
            signupUsecase: signupUsecase
        )
    }()
}

extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClientKey.self] }
        set { self[AuthClientKey.self] = newValue }
    }
}
