/// 사용자 정보 조회 유스케이스 인터페이스.
///
/// 현재 로그인한 사용자의 정보를 조회하는 앱의 동작 단위를 표현한다.
protocol FetchMeUsecase: Sendable {
    func execute() async throws -> AuthUser
}
