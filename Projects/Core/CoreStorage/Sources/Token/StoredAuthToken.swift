/// 앱 로컬 저장소에 보관하는 인증 토큰 모델.
public struct StoredAuthToken: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String

    public init(
        accessToken: String,
        refreshToken: String,
        tokenType: String
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
    }
}
