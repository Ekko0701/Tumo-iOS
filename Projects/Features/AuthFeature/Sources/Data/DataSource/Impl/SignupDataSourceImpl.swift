import CoreNetwork

/// 실제 백엔드 회원가입 API를 호출하는 DataSource 구현체.
struct SignupDataSourceImpl: SignupDataSource {
    private let provider: Provider<AuthAPI>

    init(provider: Provider<AuthAPI>) {
        self.provider = provider
    }

    func signup(requestDTO: SignupRequestDTO) async throws -> SignupResponseDTO {
        try await provider.request(
            .signup(requestDTO),
            as: SignupResponseDTO.self
        )
    }
}
