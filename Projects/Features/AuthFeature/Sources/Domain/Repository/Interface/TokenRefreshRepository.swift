/// Token Refresh 데이터를 Domain Entity로 제공하는 Repository 인터페이스.
protocol TokenRefreshRepository: Sendable {
    func refreshToken(requestDTO: TokenRefreshRequestDTO) async throws -> AuthToken
}
