/// 회원가입 유스케이스 구현체.
struct SignupUsecaseImpl: SignupUsecase {
    private let signupRepository: any SignupRepository

    init(signupRepository: any SignupRepository) {
        self.signupRepository = signupRepository
    }

    func execute(email: String, password: String, nickname: String) async throws -> AuthUser {
        let requestDTO = SignupRequestDTO(
            email: email,
            password: password,
            nickname: nickname
        )

        return try await signupRepository.signup(requestDTO: requestDTO)
    }
}
