/// 로그아웃 DataSource를 감싸는 Repository 구현체.
struct LogoutRepositoryImpl: LogoutRepository {
    private let logoutDataSource: any LogoutDataSource

    init(logoutDataSource: any LogoutDataSource) {
        self.logoutDataSource = logoutDataSource
    }

    func logout() async throws {
        try await logoutDataSource.logout()
    }
}
