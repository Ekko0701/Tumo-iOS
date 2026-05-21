/// Token Refresh 유스케이스 구현체.
struct TokenRefreshUsecaseImpl: TokenRefreshUsecase {
    private let tokenRefreshRepository: any TokenRefreshRepository
    private let authTokenRepository: any AuthTokenRepository

    init(
        tokenRefreshRepository: any TokenRefreshRepository,
        authTokenRepository: any AuthTokenRepository
    ) {
        self.tokenRefreshRepository = tokenRefreshRepository
        self.authTokenRepository = authTokenRepository
    }

    func execute(refreshToken: String) async throws -> AuthToken {
        let requestDTO = TokenRefreshRequestDTO(refreshToken: refreshToken)

        let authToken = try await tokenRefreshRepository.refreshToken(requestDTO: requestDTO)

        try authTokenRepository.save(authToken)

        return authToken
    }
}
