import CoreStorage

/// Auth 도메인의 토큰 모델을 앱 로컬 저장소 모델로 변환해 저장하는 Repository 구현체.
struct AuthTokenRepositoryImpl: AuthTokenRepository {
    private let tokenStorageClient: TokenStorageClient

    init(tokenStorageClient: TokenStorageClient) {
        self.tokenStorageClient = tokenStorageClient
    }

    func save(_ authToken: AuthToken) throws {
        try tokenStorageClient.save(
            StoredAuthToken(
                accessToken: authToken.accessToken,
                refreshToken: authToken.refreshToken,
                tokenType: authToken.tokenType
            )
        )
    }

    func load() throws -> AuthToken? {
        guard let storedAuthToken = try tokenStorageClient.load() else {
            return nil
        }

        return AuthToken(
            accessToken: storedAuthToken.accessToken,
            refreshToken: storedAuthToken.refreshToken,
            tokenType: storedAuthToken.tokenType
        )
    }

    func delete() throws {
        try tokenStorageClient.delete()
    }
}
