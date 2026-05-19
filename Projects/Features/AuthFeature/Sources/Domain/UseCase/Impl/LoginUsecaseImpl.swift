/// 로그인 유스케이스 구현체.
struct LoginUsecaseImpl: LoginUsecase {
    private let loginRepository: any LoginRepository

    init(loginRepository: any LoginRepository) {
        self.loginRepository = loginRepository
    }

    func execute(email: String, password: String) async throws -> AuthToken {
        let requestDTO = LoginRequestDTO(
            email: email,
            password: password
        )

        return try await loginRepository.login(requestDTO: requestDTO)
    }
}
