/// 지정 종목을 관심 종목에서 제거하는 유스케이스 구현체.
struct RemoveFromWatchlistUsecaseImpl: RemoveFromWatchlistUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute(stockCode: String) async throws {
        try await stockRepository.removeFromWatchlist(stockCode: stockCode)
    }
}
