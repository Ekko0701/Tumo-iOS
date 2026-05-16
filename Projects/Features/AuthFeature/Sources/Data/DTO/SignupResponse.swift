public struct SignupResponse: Codable, Equatable, Sendable {
    public let id: Int
    public let email: String
    public let nickname: String
    public let cashBalance: Int

    public init(
        id: Int,
        email: String,
        nickname: String,
        cashBalance: Int
    ) {
        self.id = id
        self.email = email
        self.nickname = nickname
        self.cashBalance = cashBalance
    }
}
