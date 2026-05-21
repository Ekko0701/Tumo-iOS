/// 저장된 인증 토큰을 조회하고 Refresh Token으로 새 세션을 발급받는 유스케이스 구현체.
struct RefreshSessionUsecaseImpl: RefreshSessionUsecase {
    private let tokenRefreshUsecase: any TokenRefreshUsecase
    private let authTokenRepository: any AuthTokenRepository

    init(
        tokenRefreshUsecase: any TokenRefreshUsecase,
        authTokenRepository: any AuthTokenRepository
    ) {
        self.tokenRefreshUsecase = tokenRefreshUsecase
        self.authTokenRepository = authTokenRepository
    }

    func execute() async throws -> AuthToken {
        do {
            guard let storedAuthToken = try authTokenRepository.load() else {
                throw AuthSessionError.authTokenNotFound
            }

            return try await tokenRefreshUsecase.execute(refreshToken: storedAuthToken.refreshToken)
        } catch {
            try? authTokenRepository.delete()

            throw error
        }
    }
}
