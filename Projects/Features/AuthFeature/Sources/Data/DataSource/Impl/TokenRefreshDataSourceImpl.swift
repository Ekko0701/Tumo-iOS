import TumoNetwork

/// 실제 백엔드 Token Refresh API를 호출하는 DataSource 구현체.
struct TokenRefreshDataSourceImpl: TokenRefreshDataSource {
    private let provider: Provider<AuthAPI>

    init(provider: Provider<AuthAPI>) {
        self.provider = provider
    }

    func refreshToken(requestDTO: TokenRefreshRequestDTO) async throws -> LoginResponseDTO {
        try await provider.request(
            .refreshToken(requestDTO),
            as: LoginResponseDTO.self
        )
    }
}
