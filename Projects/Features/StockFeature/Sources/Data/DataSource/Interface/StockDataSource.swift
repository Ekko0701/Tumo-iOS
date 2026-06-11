protocol StockDataSource: Sendable {
    func fetchStocks(
        market: StockMarket,
        page: Int,
        size: Int
    ) async throws -> StockPageResponseDTO

    func fetchStockRankings(
        market: StockMarket,
        type: StockRankingType,
        page: Int,
        size: Int
    ) async throws -> StockPageResponseDTO

    func fetchStock(stockCode: String) async throws -> StockResponseDTO
}
