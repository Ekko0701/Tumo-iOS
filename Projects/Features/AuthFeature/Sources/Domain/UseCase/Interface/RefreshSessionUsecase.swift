/// 앱 시작 시 저장된 Refresh Token으로 인증 세션을 복구하는 유스케이스 인터페이스.
protocol RefreshSessionUsecase: Sendable {
    func execute() async throws -> AuthToken
}
