import CoreStorage
import TumoNetwork

/// AuthFeature의 실제 의존성 그래프를 조립하는 객체.
///
/// TCA의 `DependencyKey`는 완성된 `AuthClient`만 등록하고,
/// Provider, DataSource, Repository, UseCase 연결은 이 Assembly가 담당한다.
enum AuthAssembly {
    static func live() -> AuthClient {
        let provider: Provider<AuthAPI> = TumoProviderFactory.live.publicProvider()
        let authorizedProvider: Provider<AuthAPI> = TumoProviderFactory.live.authorizedProvider()

        let loginDataSource = LoginDataSourceImpl(provider: provider)
        let signupDataSource = SignupDataSourceImpl(provider: provider)
        let tokenRefreshDataSource = TokenRefreshDataSourceImpl(provider: provider)

        let loginRepository = LoginRepositoryImpl(loginDataSource: loginDataSource)
        let signupRepository = SignupRepositoryImpl(signupDataSource: signupDataSource)
        let tokenRefreshRepository = TokenRefreshRepositoryImpl(tokenRefreshDataSource: tokenRefreshDataSource)
        let authTokenRepository = AuthTokenRepositoryImpl(
            tokenStorageClient: .live(keychainClient: .live())
        )

        let loginUsecase = LoginUsecaseImpl(
            loginRepository: loginRepository,
            authTokenRepository: authTokenRepository
        )
        let signupUsecase = SignupUsecaseImpl(signupRepository: signupRepository)
        let tokenRefreshUsecase = TokenRefreshUsecaseImpl(
            tokenRefreshRepository: tokenRefreshRepository,
            authTokenRepository: authTokenRepository
        )
        let refreshSessionUsecase = RefreshSessionUsecaseImpl(
            tokenRefreshUsecase: tokenRefreshUsecase,
            authTokenRepository: authTokenRepository
        )

        let fetchMeDataSource = FetchMeDataSourceImpl(provider: authorizedProvider)
        let logoutDataSource = LogoutDataSourceImpl(provider: authorizedProvider)

        let fetchMeRepository = FetchMeRepositoryImpl(fetchMeDataSource: fetchMeDataSource)
        let logoutRepository = LogoutRepositoryImpl(logoutDataSource: logoutDataSource)

        let fetchMeUsecase = FetchMeUsecaseImpl(fetchMeRepository: fetchMeRepository)
        let logoutUsecase = LogoutUsecaseImpl(
            logoutRepository: logoutRepository,
            authTokenRepository: authTokenRepository
        )

        return AuthClient.live(
            loginUsecase: loginUsecase,
            signupUsecase: signupUsecase,
            refreshSessionUsecase: refreshSessionUsecase,
            fetchMeUsecase: fetchMeUsecase,
            logoutUsecase: logoutUsecase
        )
    }
}
