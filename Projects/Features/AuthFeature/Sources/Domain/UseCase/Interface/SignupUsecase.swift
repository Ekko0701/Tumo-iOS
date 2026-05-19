/// 회원가입 유스케이스 인터페이스.
///
/// 회원가입이라는 앱의 동작 단위를 표현하고 Domain Entity를 반환한다.
protocol SignupUsecase: Sendable {
    func execute(email: String, password: String, nickname: String) async throws -> AuthUser
}
