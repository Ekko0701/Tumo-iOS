public struct SignupRequest: Codable, Equatable, Sendable {
    public let email: String
    public let password: String
    public let nickname: String

    public init(
        email: String,
        password: String,
        nickname: String
    ) {
        self.email = email
        self.password = password
        self.nickname = nickname
    }
}
