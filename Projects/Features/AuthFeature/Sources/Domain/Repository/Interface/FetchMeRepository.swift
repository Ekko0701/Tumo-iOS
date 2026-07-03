/// 사용자 정보 조회 Repository 인터페이스.
///
/// DataSource 응답 DTO를 Domain Entity로 변환하는 계층이다.
protocol FetchMeRepository: Sendable {
    func fetchMe() async throws -> AuthUser
}
