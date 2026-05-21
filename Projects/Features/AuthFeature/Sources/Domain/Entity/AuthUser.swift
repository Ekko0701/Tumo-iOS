/// 회원가입 성공 후 앱에서 사용하는 사용자 정보.
///
/// 서버 응답 DTO가 아니라 Auth 도메인에서 의미 있는 사용자 모델이다.
public struct AuthUser: Equatable, Sendable {
    public let id: Int64
    public let email: String
    public let nickname: String
    public let cashBalance: Int64

    public init(
        id: Int64,
        email: String,
        nickname: String,
        cashBalance: Int64
    ) {
        self.id = id
        self.email = email
        self.nickname = nickname
        self.cashBalance = cashBalance
    }
}
