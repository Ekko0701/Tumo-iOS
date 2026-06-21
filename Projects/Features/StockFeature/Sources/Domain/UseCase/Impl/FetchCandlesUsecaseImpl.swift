/// 특정 종목의 캔들(차트) 목록을 조회하는 유스케이스 구현체.
struct FetchCandlesUsecaseImpl: FetchCandlesUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute(
        stockCode: String,
        interval: CandleInterval,
        from: String,
        to: String
    ) async throws -> [StockCandle] {
        try await stockRepository.fetchCandles(
            stockCode: stockCode,
            interval: interval,
            from: from,
            to: to
        )
    }
}
