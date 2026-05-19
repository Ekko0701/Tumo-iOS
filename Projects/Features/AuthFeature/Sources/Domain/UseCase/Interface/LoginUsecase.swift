/// 로그인 유스케이스 인터페이스.
///
/// 로그인이라는 앱의 동작 단위를 표현하고 Domain Entity를 반환한다.
protocol LoginUsecase: Sendable {
    func execute(email: String, password: String) async throws -> AuthToken
}
