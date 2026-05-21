/// Token Refresh 유스케이스 구현체.
struct TokenRefreshUsecaseImpl: TokenRefreshUsecase {
    private let tokenRefreshRepository: any TokenRefreshRepository

    init(tokenRefreshRepository: any TokenRefreshRepository) {
        self.tokenRefreshRepository = tokenRefreshRepository
    }

    func execute(refreshToken: String) async throws -> AuthToken {
        let requestDTO = TokenRefreshRequestDTO(refreshToken: refreshToken)

        return try await tokenRefreshRepository.refreshToken(requestDTO: requestDTO)
    }
}
