/// 로그인 데이터를 Domain Entity로 제공하는 Repository 인터페이스.
protocol LoginRepository: Sendable {
    func login(requestDTO: LoginRequestDTO) async throws -> AuthToken
}
