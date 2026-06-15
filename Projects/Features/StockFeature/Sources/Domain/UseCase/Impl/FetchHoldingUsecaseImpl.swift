/// 특정 종목의 보유 현황을 조회하는 유스케이스 구현체.
struct FetchHoldingUsecaseImpl: FetchHoldingUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute(stockCode: String) async throws -> StockHolding? {
        try await stockRepository.fetchHolding(stockCode: stockCode)
    }
}
