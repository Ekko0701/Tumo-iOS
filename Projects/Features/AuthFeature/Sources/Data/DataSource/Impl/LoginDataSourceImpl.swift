import CoreNetwork

/// 실제 백엔드 로그인 API를 호출하는 DataSource 구현체.
struct LoginDataSourceImpl: LoginDataSource {
    private let provider: Provider<AuthAPI>

    init(provider: Provider<AuthAPI>) {
        self.provider = provider
    }

    func login(requestDTO: LoginRequestDTO) async throws -> LoginResponseDTO {
        try await provider.request(
            .login(requestDTO),
            as: LoginResponseDTO.self
        )
    }
}
