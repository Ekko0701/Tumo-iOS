/// 거래 가능한 종목 목록을 조회하는 유스케이스 구현체.
struct FetchStocksUsecaseImpl: FetchStocksUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute() async throws -> [Stock] {
        try await stockRepository.fetchStocks()
    }
}
