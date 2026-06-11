protocol FetchStocksUsecase: Sendable {
    func execute(market: StockMarket, page: Int, size: Int) async throws -> StockPage
}
