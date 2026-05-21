public struct SignupResponseDTO: Codable, Equatable, Sendable {
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
