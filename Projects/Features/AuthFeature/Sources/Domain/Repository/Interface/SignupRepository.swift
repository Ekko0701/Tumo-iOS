/// 회원가입 데이터를 Domain Entity로 제공하는 Repository 인터페이스.
protocol SignupRepository: Sendable {
    func signup(requestDTO: SignupRequestDTO) async throws -> AuthUser
}
