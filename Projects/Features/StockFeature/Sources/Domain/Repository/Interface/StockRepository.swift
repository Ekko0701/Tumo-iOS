protocol StockRepository: Sendable {
    func fetchStocks(
        market: StockMarket,
        page: Int,
        size: Int
    ) async throws -> StockPage

    func fetchStockRankings(
        market: StockMarket,
        type: StockRankingType,
        page: Int,
        size: Int
    ) async throws -> StockPage

    func fetchStock(stockCode: String) async throws -> Stock
}
