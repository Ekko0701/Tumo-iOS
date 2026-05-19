/// 회원가입 DataSource 응답을 Domain Entity로 변환하는 Repository 구현체.
struct SignupRepositoryImpl: SignupRepository {
    private let signupDataSource: any SignupDataSource

    init(signupDataSource: any SignupDataSource) {
        self.signupDataSource = signupDataSource
    }

    func signup(requestDTO: SignupRequestDTO) async throws -> AuthUser {
        let responseDTO = try await signupDataSource.signup(requestDTO: requestDTO)

        return AuthUser(
            id: responseDTO.id,
            email: responseDTO.email,
            nickname: responseDTO.nickname,
            cashBalance: responseDTO.cashBalance
        )
    }
}
