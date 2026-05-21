public struct AuthFormError: Equatable, Sendable {
    public let message: String?
    public let emailMessage: String?
    public let passwordMessage: String?
    public let nicknameMessage: String?

    public init(
        message: String? = nil,
        emailMessage: String? = nil,
        passwordMessage: String? = nil,
        nicknameMessage: String? = nil
    ) {
        self.message = message
        self.emailMessage = emailMessage
        self.passwordMessage = passwordMessage
        self.nicknameMessage = nicknameMessage
    }
}
