/// 로그아웃 Repository 인터페이스.
///
/// 로그아웃 작업의 비즈니스 로직을 추상화한다.
protocol LogoutRepository: Sendable {
    func logout() async throws
}
