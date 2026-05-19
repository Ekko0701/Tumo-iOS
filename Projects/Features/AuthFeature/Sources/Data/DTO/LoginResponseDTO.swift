public struct LoginResponseDTO: Codable, Equatable, Sendable {
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
