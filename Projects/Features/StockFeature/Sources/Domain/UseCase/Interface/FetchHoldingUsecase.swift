protocol FetchHoldingUsecase: Sendable {
    /// 보유 중이 아니면 nil을 반환한다.
    func execute(stockCode: String) async throws -> StockHolding?
}
