/// 로그인 DataSource 응답을 Domain Entity로 변환하는 Repository 구현체.
struct LoginRepositoryImpl: LoginRepository {
    private let loginDataSource: any LoginDataSource

    init(loginDataSource: any LoginDataSource) {
        self.loginDataSource = loginDataSource
    }

    func login(requestDTO: LoginRequestDTO) async throws -> AuthToken {
        let responseDTO = try await loginDataSource.login(requestDTO: requestDTO)

        return AuthToken(
            accessToken: responseDTO.accessToken,
            refreshToken: responseDTO.refreshToken,
            tokenType: responseDTO.tokenType
        )
    }
}
