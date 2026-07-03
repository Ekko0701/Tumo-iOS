/// 사용자 정보 조회 유스케이스 구현체.
struct FetchMeUsecaseImpl: FetchMeUsecase {
    private let fetchMeRepository: any FetchMeRepository

    init(fetchMeRepository: any FetchMeRepository) {
        self.fetchMeRepository = fetchMeRepository
    }

    func execute() async throws -> AuthUser {
        try await fetchMeRepository.fetchMe()
    }
}
