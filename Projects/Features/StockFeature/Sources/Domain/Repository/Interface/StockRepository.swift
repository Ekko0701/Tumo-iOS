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

    /// 지정 종목의 실시간 체결가 stream을 구독한다.
    func observeRealtimePrices(stockCodes: [String]) -> AsyncThrowingStream<StockRealtimeEvent, Error>

    /// 지정 종목의 실시간 호가 stream을 구독한다.
    func observeOrderBook(stockCode: String) -> AsyncThrowingStream<StockOrderBookEvent, Error>

    /// 지정 종목의 보유 현황을 조회한다. 보유 중이 아니면 nil.
    func fetchHolding(stockCode: String) async throws -> StockHolding?
}
