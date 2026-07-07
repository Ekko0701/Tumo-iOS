/// 지정 종목이 관심 종목인지 확인하는 유스케이스 구현체.
struct FetchWatchedUsecaseImpl: FetchWatchedUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute(stockCode: String) async throws -> Bool {
        try await stockRepository.fetchWatched(stockCode: stockCode)
    }
}
