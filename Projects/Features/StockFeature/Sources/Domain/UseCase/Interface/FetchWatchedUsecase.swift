protocol FetchWatchedUsecase: Sendable {
    func execute(stockCode: String) async throws -> Bool
}
