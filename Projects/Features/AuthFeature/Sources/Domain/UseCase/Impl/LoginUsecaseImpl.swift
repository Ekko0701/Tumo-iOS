/// 로그인 유스케이스 구현체.
struct LoginUsecaseImpl: LoginUsecase {
    private let loginRepository: any LoginRepository
    private let authTokenRepository: any AuthTokenRepository

    init(
        loginRepository: any LoginRepository,
        authTokenRepository: any AuthTokenRepository
    ) {
        self.loginRepository = loginRepository
        self.authTokenRepository = authTokenRepository
    }

    func execute(email: String, password: String) async throws -> AuthToken {
        let requestDTO = LoginRequestDTO(
            email: email,
            password: password
        )

        let authToken = try await loginRepository.login(requestDTO: requestDTO)

        try authTokenRepository.save(authToken)

        return authToken
    }
}
