/// 로그아웃 유스케이스 인터페이스.
///
/// 사용자 로그아웃 작업을 표현한다.
protocol LogoutUsecase: Sendable {
    func execute() async throws
}
