/// 사용자 정보 조회 DataSource 응답을 Domain Entity로 변환하는 Repository 구현체.
struct FetchMeRepositoryImpl: FetchMeRepository {
    private let fetchMeDataSource: any FetchMeDataSource

    init(fetchMeDataSource: any FetchMeDataSource) {
        self.fetchMeDataSource = fetchMeDataSource
    }

    func fetchMe() async throws -> AuthUser {
        let dto = try await fetchMeDataSource.fetchMe()
        return AuthUser(id: dto.id, email: dto.email, nickname: dto.nickname, cashBalance: dto.cashBalance)
    }
}
