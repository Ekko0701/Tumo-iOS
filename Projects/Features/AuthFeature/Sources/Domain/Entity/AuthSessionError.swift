/// 인증 세션 복구 중 발생할 수 있는 도메인 에러.
enum AuthSessionError: Error, Equatable, Sendable {
    case authTokenNotFound
}
