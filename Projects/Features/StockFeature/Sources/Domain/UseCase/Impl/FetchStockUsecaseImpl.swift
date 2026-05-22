/// 종목 코드로 특정 종목을 조회하는 유스케이스 구현체.
struct FetchStockUsecaseImpl: FetchStockUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute(stockCode: String) async throws -> Stock {
        try await stockRepository.fetchStock(stockCode: stockCode)
    }
}
