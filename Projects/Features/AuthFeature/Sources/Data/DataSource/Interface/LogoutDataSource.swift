/// 로그아웃 API 호출을 담당하는 DataSource 인터페이스.
///
/// 로그아웃은 응답 바디가 없다.
protocol LogoutDataSource: Sendable {
    func logout() async throws
}
