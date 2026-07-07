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

    /// 사용자의 포트폴리오 스냅샷을 조회한다.
    func fetchPortfolio() async throws -> Portfolio

    /// 지정 종목의 캔들(차트) 목록을 조회한다. `from`/`to`는 `yyyyMMdd` 형식.
    func fetchCandles(
        stockCode: String,
        interval: CandleInterval,
        from: String,
        to: String
    ) async throws -> [StockCandle]

    /// 관심 종목 목록을 page 단위로 조회한다.
    func fetchWatchlist(page: Int, size: Int) async throws -> StockPage

    /// 지정 종목이 관심 종목인지 확인한다.
    func fetchWatched(stockCode: String) async throws -> Bool

    /// 지정 종목을 관심 종목에 추가한다.
    func addToWatchlist(stockCode: String) async throws

    /// 지정 종목을 관심 종목에서 제거한다.
    func removeFromWatchlist(stockCode: String) async throws
}
