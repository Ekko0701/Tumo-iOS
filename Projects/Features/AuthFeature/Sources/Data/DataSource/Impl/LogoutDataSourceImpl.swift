import TumoNetwork

/// 실제 백엔드 로그아웃 API를 호출하는 DataSource 구현체.
struct LogoutDataSourceImpl: LogoutDataSource {
    private let provider: Provider<AuthAPI>

    init(provider: Provider<AuthAPI>) {
        self.provider = provider
    }

    func logout() async throws {
        _ = try await provider.requestData(.logout)
    }
}
