import TumoNetwork

/// 실제 백엔드 사용자 정보 조회 API를 호출하는 DataSource 구현체.
struct FetchMeDataSourceImpl: FetchMeDataSource {
    private let provider: Provider<AuthAPI>

    init(provider: Provider<AuthAPI>) {
        self.provider = provider
    }

    func fetchMe() async throws -> AuthUserDTO {
        try await provider.request(.me, as: AuthUserDTO.self)
    }
}
