import CoreNetwork

/// 인증 API 호출을 추상화한 Repository.
///
/// Feature/UseCase는 CoreNetwork의 `Provider`를 직접 다루지 않고,
/// 이 Repository를 통해 로그인과 회원가입을 요청한다.
protocol AuthRepository: Sendable {
    func login(request: LoginRequest) async throws -> LoginResponse
    func signup(request: SignupRequest) async throws -> SignupResponse
}

/// 실제 백엔드 인증 API를 호출하는 Repository 구현체.
struct LiveAuthRepository: AuthRepository {
    private let provider: Provider<AuthAPI>

    init(provider: Provider<AuthAPI> = Provider<AuthAPI>()) {
        self.provider = provider
    }

    func login(request: LoginRequest) async throws -> LoginResponse {
        try await provider.request(
            .login(request),
            as: LoginResponse.self
        )
    }

    func signup(request: SignupRequest) async throws -> SignupResponse {
        try await provider.request(
            .signup(request),
            as: SignupResponse.self
        )
    }
}
