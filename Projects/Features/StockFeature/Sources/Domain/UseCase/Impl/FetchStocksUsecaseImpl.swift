/// 시장별 종목 목록을 page 단위로 조회하는 유스케이스 구현체.
struct FetchStocksUsecaseImpl: FetchStocksUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute(market: StockMarket, page: Int, size: Int) async throws -> StockPage {
        try await stockRepository.fetchStocks(market: market, page: page, size: size)
    }
}
