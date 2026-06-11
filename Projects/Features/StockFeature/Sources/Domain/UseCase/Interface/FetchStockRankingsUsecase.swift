protocol FetchStockRankingsUsecase: Sendable {
    func execute(
        market: StockMarket,
        type: StockRankingType,
        page: Int,
        size: Int
    ) async throws -> StockPage
}
