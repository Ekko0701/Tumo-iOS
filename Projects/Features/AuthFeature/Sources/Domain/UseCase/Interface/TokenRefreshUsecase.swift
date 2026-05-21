/// Token Refresh 유스케이스 인터페이스.
///
/// 저장된 Refresh Token으로 새 인증 토큰을 발급받는 동작 단위를 표현한다.
protocol TokenRefreshUsecase: Sendable {
    func execute(refreshToken: String) async throws -> AuthToken
}
