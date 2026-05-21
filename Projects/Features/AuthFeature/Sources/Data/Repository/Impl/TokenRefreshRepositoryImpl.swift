/// Token Refresh DataSource 응답을 Domain Entity로 변환하는 Repository 구현체.
struct TokenRefreshRepositoryImpl: TokenRefreshRepository {
    private let tokenRefreshDataSource: any TokenRefreshDataSource

    init(tokenRefreshDataSource: any TokenRefreshDataSource) {
        self.tokenRefreshDataSource = tokenRefreshDataSource
    }

    func refreshToken(requestDTO: TokenRefreshRequestDTO) async throws -> AuthToken {
        let responseDTO = try await tokenRefreshDataSource.refreshToken(requestDTO: requestDTO)

        return AuthToken(
            accessToken: responseDTO.accessToken,
            refreshToken: responseDTO.refreshToken,
            tokenType: responseDTO.tokenType
        )
    }
}
