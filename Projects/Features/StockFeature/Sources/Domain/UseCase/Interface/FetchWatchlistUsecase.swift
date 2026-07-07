protocol FetchWatchlistUsecase: Sendable {
    func execute(page: Int, size: Int) async throws -> StockPage
}
