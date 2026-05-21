/// 인증 토큰 저장소 인터페이스.
///
/// Domain 계층은 Keychain 같은 구체 저장 기술이 아니라 이 인터페이스를 통해 토큰 저장을 요청한다.
protocol AuthTokenRepository: Sendable {
    func save(_ authToken: AuthToken) throws
    func load() throws -> AuthToken?
    func delete() throws
}
