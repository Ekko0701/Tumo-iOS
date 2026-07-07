/// 지정 종목을 관심 종목에 추가하는 유스케이스 구현체.
struct AddToWatchlistUsecaseImpl: AddToWatchlistUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute(stockCode: String) async throws {
        try await stockRepository.addToWatchlist(stockCode: stockCode)
    }
}
