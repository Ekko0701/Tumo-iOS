import TumoNetwork

/// 실제 백엔드 종목 API를 호출하는 DataSource 구현체.
struct StockDataSourceImpl: StockDataSource {
    private let provider: Provider<StockAPI>

    init(provider: Provider<StockAPI>) {
        self.provider = provider
    }

    func fetchStocks(
        market: StockMarket,
        page: Int,
        size: Int
    ) async throws -> StockPageResponseDTO {
        try await provider.request(
            .stocks(market: market, page: page, size: size),
            as: StockPageResponseDTO.self
        )
    }

    func fetchStockRankings(
        market: StockMarket,
        type: StockRankingType,
        page: Int,
        size: Int
    ) async throws -> StockPageResponseDTO {
        try await provider.request(
            .rankings(market: market, type: type, page: page, size: size),
            as: StockPageResponseDTO.self
        )
    }

    func fetchStock(stockCode: String) async throws -> StockResponseDTO {
        try await provider.request(
            .stock(stockCode: stockCode),
            as: StockResponseDTO.self
        )
    }
}
