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

    /// 지정 종목의 실시간 체결가 SSE stream을 구독한다.
    func observeRealtimePrices(stockCodes: [String]) -> AsyncThrowingStream<StockPriceEventDTO, Error>
}
