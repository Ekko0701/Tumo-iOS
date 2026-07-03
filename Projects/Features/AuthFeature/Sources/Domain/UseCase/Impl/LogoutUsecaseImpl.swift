/// 로그아웃 유스케이스 구현체.
/// 백엔드 실패와 무관하게 로컬 토큰 삭제(로컬 로그아웃 항상 성립)
struct LogoutUsecaseImpl: LogoutUsecase {
    private let logoutRepository: any LogoutRepository
    private let authTokenRepository: any AuthTokenRepository

    init(logoutRepository: any LogoutRepository, authTokenRepository: any AuthTokenRepository) {
        self.logoutRepository = logoutRepository
        self.authTokenRepository = authTokenRepository
    }

    func execute() async throws {
        do {
            try await logoutRepository.logout()
        } catch {
            try? authTokenRepository.delete()
            throw error
        }
        try authTokenRepository.delete()
    }
}
