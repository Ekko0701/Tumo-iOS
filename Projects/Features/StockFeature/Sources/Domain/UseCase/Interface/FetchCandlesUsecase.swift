protocol FetchCandlesUsecase: Sendable {
    /// 지정 종목의 캔들(차트) 목록을 조회한다. `from`/`to`는 `yyyyMMdd` 형식.
    func execute(
        stockCode: String,
        interval: CandleInterval,
        from: String,
        to: String
    ) async throws -> [StockCandle]
}
