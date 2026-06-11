/// 시장·랭킹 기준별 종목 랭킹 목록을 page 단위로 조회하는 유스케이스 구현체.
struct FetchStockRankingsUsecaseImpl: FetchStockRankingsUsecase {
    private let stockRepository: any StockRepository

    init(stockRepository: any StockRepository) {
        self.stockRepository = stockRepository
    }

    func execute(
        market: StockMarket,
        type: StockRankingType,
        page: Int,
        size: Int
    ) async throws -> StockPage {
        try await stockRepository.fetchStockRankings(
            market: market,
            type: type,
            page: page,
            size: size
        )
    }
}
