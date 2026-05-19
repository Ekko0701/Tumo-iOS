/// 로그인 성공 후 앱에서 사용하는 인증 토큰 정보.
///
/// 서버 응답 DTO가 아니라 Auth 도메인에서 의미 있는 토큰 모델이다.
public struct AuthToken: Equatable, Sendable {
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
