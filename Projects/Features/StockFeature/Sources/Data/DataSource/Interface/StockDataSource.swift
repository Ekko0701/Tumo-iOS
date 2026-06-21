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
    func observeRealtimePrices(stockCodes: [String]) -> AsyncThrowingStream<StockRealtimeEventDTO, Error>

    /// 지정 종목의 실시간 호가 SSE stream을 구독한다.
    func observeOrderBook(stockCode: String) -> AsyncThrowingStream<StockOrderBookEventDTO, Error>

    /// 사용자의 포트폴리오(보유 종목)를 조회한다.
    func fetchPortfolio() async throws -> PortfolioResponseDTO

    /// 지정 종목의 캔들(차트) 목록을 조회한다. `from`/`to`는 `yyyyMMdd` 형식.
    func fetchCandles(
        stockCode: String,
        interval: CandleInterval,
        from: String,
        to: String
    ) async throws -> StockCandleListResponseDTO
}
